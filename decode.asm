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

; Field shifts and masks. A mask has one bit set per bit of field width.
%define VERSION_SHIFT   4       ; version is the high nibble of byte 0
%define IHL_MASK        0x0F    ; IHL is the low 4 bits of byte 0
%define DSCP_SHIFT      2       ; DSCP is the high 6 bits of byte 1
%define ECN_MASK        0x03    ; ECN is the low 2 bits of byte 1
%define FLAGS_SHIFT     13      ; flags sit above the 13-bit fragment offset
%define FLAGS_MASK      0x07    ; flags are 3 bits wide
%define FRAG_MASK       0x1FFF  ; offset is 13 bits: 5 from byte 6, 8 from byte 7

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

        ; Pointers
        mov     esi, [ebp+8]   ; pointer to header
        mov     edi, [ebp+12]  ; pointer to struct

        ; Byte 0: version (bits 7-4) | IHL (bits 3-0)
        movzx   ebx, byte [esi+0]  ; ebx = byte 0

        ; extract version
        mov     eax, ebx
        shr     eax, VERSION_SHIFT
        mov     [edi+0], eax

        ; extract IHL
        mov     eax, ebx
        and     eax, IHL_MASK
        mov     [edi+4], eax

        ; Byte 1: DSCP (bits 7-2) | ECN (bits 1-0)
        movzx   ebx, byte [esi+1]  ; ebx = byte 1

        ; extract DSCP
        mov     eax, ebx
        shr     eax, DSCP_SHIFT
        mov     [edi+8], eax

        ; extract ECN
        mov     eax, ebx
        and     eax, ECN_MASK
        mov     [edi+12], eax

        ; Bytes 2-3: Total Length (16 bits)
        movzx   eax, byte [esi+2]  ; high byte
        shl     eax, 8
        movzx   ebx, byte [esi+3]  ; low byte
        or      eax, ebx
        mov     [edi+16], eax

        ; Bytes 4-5: Identification (16 bits)
        movzx   eax, byte [esi+4]  ; high byte
        shl     eax, 8
        movzx   ebx, byte [esi+5]  ; low byte
        or      eax, ebx
        mov     [edi+20], eax

        ; Bytes 6-7: Flags (high 3 bits) | Fragment Offset (low 13 bits)
        movzx   eax, byte [esi+6]  ; high byte
        shl     eax, 8
        movzx   ebx, byte [esi+7]  ; low byte
        or      eax, ebx

        ; extract Flags
        mov     ebx, eax
        shr     ebx, FLAGS_SHIFT
        and     ebx, FLAGS_MASK
        mov     [edi+24], ebx

        ; extract Fragment Offset
        and     eax, FRAG_MASK
        mov     [edi+28], eax

        ; Byte 8: TTL (8 bits)
        movzx   eax, byte [esi+8]  ; eax = byte 8
        mov     [edi+32], eax

        ; Byte 9: Protocol (8 bits)
        movzx   eax, byte [esi+9]  ; eax = byte 9
        mov     [edi+36], eax

        ; Bytes 10-11: Header Checksum (16 bits)
        movzx   eax, byte [esi+10]  ; high byte
        shl     eax, 8
        movzx   ebx, byte [esi+11]  ; low byte
        or      eax, ebx
        mov     [edi+40], eax

        ; Bytes 12-15: Source Address (32 bits)
        mov     al, [esi+12]
        mov     [edi+44], al
        mov     al, [esi+13]
        mov     [edi+45], al
        mov     al, [esi+14]
        mov     [edi+46], al
        mov     al, [esi+15]
        mov     [edi+47], al

        ; Bytes 16-19: Destination Address (32 bits)
        mov     al, [esi+16]
        mov     [edi+48], al
        mov     al, [esi+17]
        mov     [edi+49], al
        mov     al, [esi+18]
        mov     [edi+50], al
        mov     al, [esi+19]
        mov     [edi+51], al

        popa
        mov     eax, 0
        leave
        ret
