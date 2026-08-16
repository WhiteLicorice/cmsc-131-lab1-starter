;
; encode.asm - build a 20-byte IPv4 header from the field struct.
;
; This is your starting point: it assembles and links as-is, so the build
; works before you write any code. Right now it writes twenty zero bytes,
; which produces a header that decodes as all zeros. Your job is to replace
; that with the construction described below.
;
; The contract, from driver.c:
;
;       unsigned char *hdr        [ebp+12]
;       struct ipv4_fields *in    [ebp+8]
;
; The struct layout is documented in driver.c:
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
; checksum is computed, so write them as zero, call ip_checksum over the
; finished header, and store its result into the field. The struct's
; checksum member is read on the decode path only. Don't copy it here.
;
; Do not clobber ebx, esi, edi, or ebp. C assumes they survive your call.
; Return in eax (driver.c ignores it here, so returning 0 is fine).
;

; Windows C decorates the names it exports with a leading underscore and
; Linux C does not, so the same source would otherwise need two spellings of
; every entry point. -d ELF_TYPE, which the shared Makefile fragment passes
; on Linux, selects the respelling here. It's the same trick asm_io.inc
; uses for _asm_main in the bootcamp blocks. Leave this block alone.
%ifdef ELF_TYPE
  %define _ip_checksum ip_checksum
  %define _encode_header encode_header
  section .note.GNU-stack noalloc noexec nowrite progbits
%endif

extern _ip_checksum

segment .text
        global  _encode_header
_encode_header:
        enter   0,0
        pusha

        ;
        ; TODO: build the header from the struct.
        ;
        ; The reverse of decode: shift each field down to where it lives,
        ; mask it to its width, or the pieces of a shared byte together,
        ; then store the byte. The fields that do not straddle anything
        ; are one store each.
        ;
        ; The checksum comes last, after every other byte is written. Write
        ; bytes 10-11 as zero, call ip_checksum with the header and 20, and
        ; store its result (in ax) into the field big-endian. Computing it
        ; before the rest of the header is in place sums whatever garbage
        ; was in the buffer. ip_checksum preserves the callee-saved
        ; registers, so saving edi around the call is enough.
        ;
