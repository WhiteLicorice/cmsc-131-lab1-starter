;
; contract_regs.asm - call each routine with sentinel registers.
;
; The stdout comparison cannot see whether a routine leaves ebx, esi, or edi
; changed. C calls these routines and assumes those three survive, so a
; routine that clobbers one produces failures far from the cause, and the
; failures appear in code the student did not write.
;
; Each function below loads a sentinel into ebx, esi, and edi, takes a copy
; of esp, calls the routine under test, and returns a bitmask:
;
;   bit 0  ebx changed
;   bit 1  esi changed
;   bit 2  edi changed
;   bit 3  esp moved
;
; Zero means every one of them survived. This file is provided. Do not
; modify it.
;

; Windows C puts a leading underscore on every exported name. Linux C does
; not. The Makefile passes -d ELF_TYPE on Linux. This block then respells
; the names below to match. asm_io.inc does the same for _asm_main in the
; bootcamp blocks.
%ifdef ELF_TYPE
  %define _decode_header decode_header
  %define _encode_header encode_header
  %define _ip_checksum ip_checksum
  %define _check_decode_registers check_decode_registers
  %define _check_encode_registers check_encode_registers
  %define _check_checksum_registers check_checksum_registers
  section .note.GNU-stack noalloc noexec nowrite progbits
%endif

extern _decode_header
extern _encode_header
extern _ip_checksum

%define SENTINEL_EBX 0x11111111
%define SENTINEL_ESI 0x22222222
%define SENTINEL_EDI 0x33333333

;
; verdict - build the register bitmask in eax. edx holds the saved stack
; pointer. The macro expands in place, so it adds nothing to the stack and
; the esp comparison stays honest.
;
%macro verdict 0
        xor     eax, eax
        cmp     ebx, SENTINEL_EBX
        je      %%ebx_ok
        or      eax, 1
%%ebx_ok:
        cmp     esi, SENTINEL_ESI
        je      %%esi_ok
        or      eax, 2
%%esi_ok:
        cmp     edi, SENTINEL_EDI
        je      %%edi_ok
        or      eax, 4
%%edi_ok:
        cmp     esp, edx
        je      %%esp_ok
        or      eax, 8
%%esp_ok:
%endmacro

segment .text

; int check_decode_registers(unsigned char *hdr, struct ipv4_fields *out)
        global  _check_decode_registers
_check_decode_registers:
        enter   0,0
        push    ebx
        push    esi
        push    edi

        mov     ebx, SENTINEL_EBX
        mov     esi, SENTINEL_ESI
        mov     edi, SENTINEL_EDI

        mov     eax, esp                ; the stack pointer, kept on the stack
        push    eax
        push    dword [ebp+12]          ; out
        push    dword [ebp+8]           ; hdr
        call    _decode_header
        add     esp, 8                  ; drop the two arguments
        pop     edx                     ; the saved stack pointer
        verdict

        pop     edi
        pop     esi
        pop     ebx
        leave
        ret

; int check_encode_registers(struct ipv4_fields *in, unsigned char *hdr)
        global  _check_encode_registers
_check_encode_registers:
        enter   0,0
        push    ebx
        push    esi
        push    edi

        mov     ebx, SENTINEL_EBX
        mov     esi, SENTINEL_ESI
        mov     edi, SENTINEL_EDI

        mov     eax, esp
        push    eax
        push    dword [ebp+12]          ; hdr
        push    dword [ebp+8]           ; in
        call    _encode_header
        add     esp, 8
        pop     edx
        verdict

        pop     edi
        pop     esi
        pop     ebx
        leave
        ret

; int check_checksum_registers(unsigned char *hdr, int len)
        global  _check_checksum_registers
_check_checksum_registers:
        enter   0,0
        push    ebx
        push    esi
        push    edi

        mov     ebx, SENTINEL_EBX
        mov     esi, SENTINEL_ESI
        mov     edi, SENTINEL_EDI

        mov     eax, esp
        push    eax
        push    dword [ebp+12]          ; len
        push    dword [ebp+8]           ; hdr
        call    _ip_checksum
        add     esp, 8
        pop     edx
        verdict

        pop     edi
        pop     esi
        pop     ebx
        leave
        ret
