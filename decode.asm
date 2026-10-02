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

        
        ; extracting header
        mov     esi, [ebp+8]            ; hdr
        mov     edi, [ebp+12]           ; out, ipv4_fields

        ; byte 0: version and ihl
        ; shifting and masking
        movzx   eax, byte [esi+0]       ; gets byte 0
        shr     eax, 4                  ; shift right by 4   
        
        movzx   ebx, byte [esi+0]       ; gets byte 0
        and     ebx, 0x0F               ; masking the ihl in the low nibble                   

        mov     [edi+0], eax            ; storing version to out
        mov     [edi+4], ebx            ; storing ihl to out


        ; byte 1: dscp and ecn
        movzx   eax, byte [esi+1]       ; gets byte 1
        shr     eax, 2                  ; shift to get the higher 6-bits for dscp

        movzx   ebx, byte [esi+1]       ; gets byte 1
        and     ebx, 0x03               ; mask for the bottom 2-bits

        mov     [edi+8], eax            ; storing dscp to out
        mov     [edi+12], ebx           ; storing ecn to out


        ; bytes 2-3: total length, one 16-bits 
        movzx   eax, byte [esi+2]       ; gets the byte 2
        shl     eax, 8                  ; shift left to get the high byte

        movzx   ebx, byte [esi+3]       ; gets the byte 3
        or      eax, ebx                ; mask to combine
                                        ; eax = 16-bit value for total length

        mov     [edi+16], eax           ; storing total length to out


        ; bytes 4-5: identification, one 16-bits
        movzx   eax, byte [esi+4]       ; gets the byte 4
        shl     eax, 8                  ; shift left to get the high byte

        movzx   ebx, byte [esi+5]       ; gets the byte 5
        or      eax, ebx                ; mask to combine
                                        ; eax = 16-bit value for identification

        mov     [edi+20], eax           ; storing identification to out


        ; byte 6-7: flags and fragment offset
        movzx   eax, byte [esi+6]       ; gets the byte 6
        shl     eax, 8                  ; shift left to get the high byte                  

        movzx   ebx, byte [esi+7]       ; gets the byte 
        or      eax, ebx                ; mask to combine

        mov     ebx, eax                ; copy combined bytes 6-7
        shr     eax, 13                 ; shift right by 13 for flags
        and     ebx, 0x1FFF             ; mask for the bottom 13 bits for fragment offset

        mov     [edi+24], eax
        mov     [edi+28], ebx


        ; byte 8: ttl
        movzx   eax, byte [esi+8]       ; gets the byte 8

        mov     [edi+32], eax           ; storing ttl to out


        ; byte 9: protocol
        movzx   eax, byte [esi+9]       ; gets the byte 9

        mov     [edi+36], eax           ; storing protocol to out


        ; bytes 10-11: header checksum
        movzx   eax, byte [esi+10]      ; gets the byte 10
        shl     eax, 8                  ; shift left by 8 to get high byte

        movzx   ebx, byte [esi+11]      ; gets the byte 11
        or      eax, ebx                ; mask to combine 16-bits

        mov     [edi+40], eax           ; storing header checksum to out
                                        

        ; bytes 12-15: source address
        movzx   eax, byte [esi+12]      ; gets the byte 12
        mov     [edi+44], al            ; stores the first byte

        movzx   eax, byte [esi+13]      ; gets the byte 13
        mov     [edi+45], al            ; stores the second byte

        movzx   eax, byte [esi+14]      ; gets the byte 14
        mov     [edi+46], al            ; stores the third byte

        movzx   eax, byte [esi+15]      ; gets the byte 15
        mov     [edi+47], al            ; stores the fourth byte


        ; bytes 16-19: destination address
        movzx   eax, byte [esi+16]      ; gets the byte 16
        mov     [edi+48], al            ; stores the first byte

        movzx   eax, byte [esi+17]      ; gets the byte 17
        mov     [edi+49], al            ; stores the second byte

        movzx   eax, byte [esi+18]      ; gets the byte 18
        mov     [edi+50], al            ; stores the third byte

        movzx   eax, byte [esi+19]      ; gets the byte 19
        mov     [edi+51], al            ; stores the fourth byte


        popa
        mov     eax, 0
        leave
        ret
