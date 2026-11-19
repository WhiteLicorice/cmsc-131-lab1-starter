;
; decode.asm - extract every field from a 20-byte IPv4 header.
;
; This is your starting point. It assembles and links as-is, so the build
; works before you write any code. Right now it stores nothing, so renpkt
; prints the zeros driver.c put in the struct. Your job is to replace that
; with the extraction described below.
;
; The contract, from driver.c:
;
;       struct ipv4_fields *out   [ebp+12]
;       unsigned char *hdr        [ebp+8]
;
; hdr points at twenty bytes in network byte order. out points at the struct
; documented in driver.c. Its offsets are:
;
;   +0 version   +4 ihl    +8 dscp   +12 ecn   +16 total_length
;   +20 identification    +24 flags  +28 fragment_offset
;   +32 ttl      +36 protocol       +40 checksum
;   +44 src[0..3]                   +48 dst[0..3]
;
; Every int member is 4 bytes, so a plain 32-bit store fills one. The
; addresses are four single-byte stores each.
;
; Do not clobber ebx, esi, edi, or ebp. C assumes they survive your call.
; Return in eax (driver.c ignores it here, so returning 0 is fine).
;

; Windows C puts a leading underscore on every exported name. Linux C does
; not. The Makefile passes -d ELF_TYPE on Linux. This block then respells
; the names below to match. asm_io.inc does the same for _asm_main in the
; bootcamp blocks. Leave this block alone.
%ifdef ELF_TYPE
  %define _decode_header decode_header
  section .note.GNU-stack noalloc noexec nowrite progbits
%endif

segment .text
        global  _decode_header
_decode_header:
        enter   0,0
        pusha

        ;
        ; TODO: read the header and fill the struct.
        ;
        ; The field-by-field layout is the table in the manual. The notes
        ; that matter before you start:
        ;
        ;   * Every multi-byte field is big-endian, so load it byte by byte
        ;     and recombine. A single 16-bit load gives you the bytes
        ;     reversed.
        ;   * The fragment offset straddles a byte boundary. Its top five
        ;     bits live in byte 6 and its bottom eight in byte 7. Combine
        ;     both bytes into one word first, then shift and mask.
        ;   * The flags are the top three bits of the same word.
        ;   * Read and store the checksum field like any other field.
        ;     ip_checksum computes the VALID line separately.
        ;   * src and dst are four single-byte stores each. No shifting.
        ;
        ; Nothing here reads the file or prints. This routine only fills
        ; the struct, and driver.c does the rest.
        ;

        ; Arguments:
        ; [EBP+8]  = hdr
        ; [EBP+12] = out

        mov     esi, [ebp+12]          ; output struct
        mov     edi, [ebp+8]           ; IPv4 header

        ; -----------------------------------------
        ; Version and IHL (byte 0)
        ; -----------------------------------------

        movzx   eax, byte [edi]

        mov     ebx, eax
        shr     eax, 4
        mov     [esi], eax             ; version

        mov     eax, ebx
        and     eax, 0x0F
        mov     [esi+4], eax           ; IHL

        ; -----------------------------------------
        ; DSCP and ECN (byte 1)
        ; -----------------------------------------

        movzx   eax, byte [edi+1]

        mov     ebx, eax
        shr     eax, 2
        and     eax, 0x3F
        mov     [esi+8], eax           ; DSCP

        mov     eax, ebx
        and     eax, 0x03
        mov     [esi+12], eax          ; ECN

        ; -----------------------------------------
        ; Total Length (bytes 2-3)
        ; Big-endian: byte 2 is the high byte.
        ; -----------------------------------------

        movzx   eax, byte [edi+2]
        shl     eax, 8

        movzx   ebx, byte [edi+3]
        or      eax, ebx

        mov     [esi+16], eax

        ; -----------------------------------------
        ; Identification (bytes 4-5)
        ; -----------------------------------------

        movzx   eax, byte [edi+4]
        shl     eax, 8

        movzx   ebx, byte [edi+5]
        or      eax, ebx

        mov     [esi+20], eax

        ; -----------------------------------------
        ; Flags and Fragment Offset (bytes 6-7)
        ; -----------------------------------------

        movzx   eax, byte [edi+6]
        shl     eax, 8

        movzx   ebx, byte [edi+7]
        or      eax, ebx

        ; Lower 13 bits = fragment offset.
        mov     ebx, eax
        and     ebx, 0x1FFF
        mov     [esi+28], ebx

        ; Upper 3 bits = flags.
        shr     eax, 13
        and     eax, 0x07
        mov     [esi+24], eax

        ; -----------------------------------------
        ; TTL (byte 8)
        ; -----------------------------------------

        movzx   eax, byte [edi+8]
        mov     [esi+32], eax

        ; -----------------------------------------
        ; Protocol (byte 9)
        ; -----------------------------------------

        movzx   eax, byte [edi+9]
        mov     [esi+36], eax

        ; -----------------------------------------
        ; Header Checksum (bytes 10-11)
        ; -----------------------------------------

        movzx   eax, byte [edi+10]
        shl     eax, 8

        movzx   ebx, byte [edi+11]
        or      eax, ebx

        mov     [esi+40], eax

        ; -----------------------------------------
        ; Source Address (bytes 12-15)
        ; -----------------------------------------

        mov     al, [edi+12]
        mov     [esi+44], al

        mov     al, [edi+13]
        mov     [esi+45], al

        mov     al, [edi+14]
        mov     [esi+46], al

        mov     al, [edi+15]
        mov     [esi+47], al

        ; -----------------------------------------
        ; Destination Address (bytes 16-19)
        ; -----------------------------------------

        mov     al, [edi+16]
        mov     [esi+48], al

        mov     al, [edi+17]
        mov     [esi+49], al

        mov     al, [edi+18]
        mov     [esi+50], al

        mov     al, [edi+19]
        mov     [esi+51], al

        ; -----------------------------------------
        ; Restore registers and return.
        ; -----------------------------------------;
        popa
        mov     eax, 0
        leave
        ret
