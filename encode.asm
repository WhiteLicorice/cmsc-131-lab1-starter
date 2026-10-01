;
; encode.asm - build a 20-byte IPv4 header from the field struct.
;
; This is your starting point. It assembles and links as-is, so the build
; works before you write any code. Right now it writes nothing, so the
; twenty bytes driver.c saves are whatever the buffer held. Your job is to
; replace that with the construction described below.
;
; The contract, from driver.c:
;
;       unsigned char *hdr        [ebp+12]
;       struct ipv4_fields *in    [ebp+8]
;
; driver.c documents the struct layout:
;
;   +0 version   +4 ihl    +8 dscp   +12 ecn   +16 total_length
;   +20 identification    +24 flags  +28 fragment_offset
;   +32 ttl      +36 protocol       +40 checksum
;   +44 src[0..3]                   +48 dst[0..3]
;
; You write twenty bytes into hdr. Every multi-byte field goes out
; big-endian: the high byte first. The fragment offset's top five bits share
; byte 6 with the three flag bits. Its bottom eight bits are byte 7.
;
; The checksum is your job too. Bytes 10-11 must read as zero while the
; checksum is computed. Write them as zero, call ip_checksum over the
; finished header, and store its result into the field. The struct's
; checksum member is read on the decode path only. Don't copy it here.
;
; Do not clobber ebx, esi, edi, or ebp. C assumes they survive your call.
; Return in eax (driver.c ignores it here, so returning 0 is fine).
;

; Windows C puts a leading underscore on every exported name. Linux C does
; not. The Makefile passes -d ELF_TYPE on Linux. This block then respells
; the names below to match. asm_io.inc does the same for _asm_main in the
; bootcamp blocks. Leave this block alone.
%ifdef ELF_TYPE
  %define _ip_checksum ip_checksum
  %define _encode_header encode_header
  section .note.GNU-stack noalloc noexec nowrite progbits
%endif

extern _ip_checksum

; Field shifts and masks. A mask has one bit set per bit of field width.
%define VERSION_MASK    0x0F    ; version is 4 bits, the high nibble of byte 0
%define VERSION_SHIFT   4
%define IHL_MASK        0x0F    ; IHL is the low 4 bits of byte 0
%define DSCP_MASK       0x3F    ; DSCP is 6 bits, the high bits of byte 1
%define DSCP_SHIFT      2
%define ECN_MASK        0x03    ; ECN is the low 2 bits of byte 1
%define FLAGS_MASK      0x07    ; flags are 3 bits wide
%define FLAGS_SHIFT     13      ; flags sit above the 13-bit fragment offset
%define FRAG_MASK       0x1FFF  ; fragment offset is the low 13 bits of bytes 6-7
%define HI_BYTE_SHIFT   8       ; shift a 16-bit field down to reach its high byte
%define HDR_LEN         20      ; the driver always passes a 20-byte header

segment .text
        global  _encode_header
_encode_header:
        enter   0,0
        pusha

        ; This is the reverse of decode. 
        ; Mask it to its width, shift it up
        ; or shift pieces of a shared byte together,
        ; afterwards then store the byte. 

        ; esi and edi survive the ip_checksum call, so the pointers live there.


        ; pointers, opposite to the decode since 
        ; source first, destination second
        mov     esi, [ebp+8]       ; first argument (pointer to struct) 
        mov     edi, [ebp+12]      ; second args( header bytes)

        ; Based on struct 

        ; Byte 0: version (7-4) and IHL (bits 3-0)
        mov     eax, [esi+0]       ; version, top bits
        and     eax, VERSION_MASK
        shl     eax, VERSION_SHIFT
        mov     ebx, [esi+4]       ; ihl
        and     ebx, IHL_MASK
        or      eax, ebx ;merge them both together
        mov     [edi+0], al ; write byte to hdr[0]



        ; Byte 1: DSCP (bits 7-2) | ECN (bits 1-0)
        mov     eax, [esi+8]       ; dscp
        and     eax, DSCP_MASK
        shl     eax, DSCP_SHIFT
        mov     ebx, [esi+12]      ; ecn
        and     ebx, ECN_MASK
        or      eax, ebx; combine
        mov     [edi+1], al ; write byte to hdr[1]


        ; Bytes 2-3: Total Length (16 bits, big-endian)
        mov     eax, [esi+16]
        mov     ebx, eax
        shr     ebx, HI_BYTE_SHIFT ; shift of one length to the right
        mov     [edi+2], bl        ; high byte
        mov     [edi+3], al        ; low byte

        ; Bytes 4-5: Identification (16 bits, big-endian)
        mov     eax, [esi+20]
        mov     ebx, eax
        shr     ebx, HI_BYTE_SHIFT
        mov     [edi+4], bl        ; high byte
        mov     [edi+5], al        ; low byte


        ; Bytes 6-7: Flags (high 3 bits) | Fragment Offset (low 13 bits)
        mov     eax, [esi+24]      ; flags
        and     eax, FLAGS_MASK
        shl     eax, FLAGS_SHIFT      ; shift 13 up (since we occupy bottom of stack)
        mov     ebx, [esi+28]      ; fragment_offset
        and     ebx, FRAG_MASK        ; trim to 13 bits

        or      eax, ebx           ; eax = combined 16-bit word
        mov     ebx, eax
        shr     ebx, HI_BYTE_SHIFT
        mov     [edi+6], bl        ; high byte
        mov     [edi+7], al        ; low byte

        ; Byte 8: TTL (8 bits)
        mov     eax, [esi+32]
        mov     [edi+8], al

        ; Byte 9: Protocol (8 bits)
        mov     eax, [esi+36]
        mov     [edi+9], al

        popa
        mov     eax, 0
        leave
        ret
