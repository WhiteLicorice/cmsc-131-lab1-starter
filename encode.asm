
;
; encode.asm - build a 20-byte IPv4 header from the field struct.
;

%ifdef ELF_TYPE
  %define _ip_checksum ip_checksum
  %define _encode_header encode_header
  section .note.GNU-stack noalloc noexec nowrite progbits
%endif

extern _ip_checksum

segment .text
global _encode_header

_encode_header:
    enter   0,0
    pusha

    ; Arguments:
    ; [EBP+8]  = in
    ; [EBP+12] = hdr

    mov     esi, [ebp+8]
    mov     edi, [ebp+12]

    ; ------------------------------------------------
    ; Byte 0: Version (4 bits) | IHL (4 bits)
    ; ------------------------------------------------

    mov     eax, [esi]
    and     eax, 0x0F
    shl     eax, 4

    mov     ebx, [esi+4]
    and     ebx, 0x0F

    or      eax, ebx
    mov     [edi], al

    ; ------------------------------------------------
    ; Byte 1: DSCP (6 bits) | ECN (2 bits)
    ; ------------------------------------------------

    mov     eax, [esi+8]
    and     eax, 0x3F
    shl     eax, 2

    mov     ebx, [esi+12]
    and     ebx, 0x03

    or      eax, ebx
    mov     [edi+1], al

        ; ------------------------------------------------
    ; Bytes 2-3: Total Length (16-bit big-endian)
    ; ------------------------------------------------

    mov     eax, [esi+16]
    mov     ebx, eax

    shr     eax, 8
    mov     [edi+2], al

    mov     [edi+3], bl

    ; ------------------------------------------------
    ; Bytes 4-5: Identification (16-bit big-endian)
    ; ------------------------------------------------

    mov     eax, [esi+20]
    mov     ebx, eax

    shr     eax, 8
    mov     [edi+4], al

    mov     [edi+5], bl

        ; ------------------------------------------------
    ; Bytes 6-7: Flags (3 bits) | Fragment Offset (13 bits)
    ; ------------------------------------------------

    mov     eax, [esi+24]
    and     eax, 0x07
    shl     eax, 13

    mov     ebx, [esi+28]
    and     ebx, 0x1FFF

    or      eax, ebx

    ; Write the resulting 16-bit word in big-endian order.
    mov     ebx, eax

    shr     eax, 8
    mov     [edi+6], al

    mov     [edi+7], bl

    ; ------------------------------------------------
    ; Bytes 8-9: TTL and Protocol
    ; ------------------------------------------------

    mov     eax, [esi+32]
    mov     [edi+8], al

    mov     eax, [esi+36]
    mov     [edi+9], al

    ; ------------------------------------------------
    ; Bytes 10-11: Checksum (initially zero)
    ; ------------------------------------------------

    mov     word [edi+10], 0

    ; ------------------------------------------------
    ; Calculate checksum over all 20 bytes.
    ; ip_checksum(hdr, 20)
    ; ------------------------------------------------

    push    dword 20
    push    dword edi
    call    _ip_checksum
    add     esp, 8


    popa
    mov     eax, 0

    leave
    ret
