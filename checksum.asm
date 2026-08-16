;
; checksum.asm - the one's complement internet checksum.
;
; This is your starting point: it assembles and links as-is, so the build
; works before you write any code. Right now it always returns 0, which
; makes every header decode as VALID (the decode path sums the header as it
; stands and tests for zero, so a checksum routine that returns 0 means
; "valid" for everything). Your job is to replace that with the sum
; described below.
;
; The contract, from driver.c:
;
;       int len                   [ebp+12]
;       unsigned char *hdr        [ebp+8]
;
; Sum len bytes of hdr as len/2 16-bit big-endian words into a 32-bit
; accumulator, fold the carries until the result fits in 16 bits, and return
; the one's complement of that in ax. The manual's worked example is the
; test: zero the checksum field, sum the sample header, and you must get
; 0x9CBC.
;
; The decode path calls this over the header as it stands, checksum field
; included. A valid header returns 0 and an invalid one does not. The
; encode path calls it over a header whose checksum field you wrote as zero.
; Both uses fall out of the same routine. You don't need to know which one
; called you.
;
; Do not clobber ebx, esi, edi, or ebp. C assumes they survive your call.
;

; Windows C decorates the names it exports with a leading underscore and
; Linux C does not, so the same source would otherwise need two spellings of
; every entry point. -d ELF_TYPE, which the shared Makefile fragment passes
; on Linux, selects the respelling here. It's the same trick asm_io.inc
; uses for _asm_main in the bootcamp blocks. Leave this block alone.
%ifdef ELF_TYPE
  %define _ip_checksum ip_checksum
  section .note.GNU-stack noalloc noexec nowrite progbits
%endif

segment .text
        global  _ip_checksum
_ip_checksum:
        enter   0,0
        pusha

        ;
        ; TODO: the checksum loop.
        ;
        ; The manual's recipe:
        ;
        ;   1. Treat the header as 16-bit big-endian words. Load each byte
        ;      pair and recombine. Never load the pair as a single 16-bit
        ;      value, which gives you the bytes reversed.
        ;   2. Add each word to a 32-bit accumulator. Carries are kept, not
        ;      dropped. That is what the fold below is for.
        ;   3. While the accumulator exceeds 16 bits, add its high half to
        ;      its low half. This is the end-around carry. A large sum can
        ;      need the fold twice.
        ;   4. NOT the low 16 bits. That is the checksum.
        ;
        ; len is always even (the driver calls this with 20), so a loop
        ; that consumes two bytes per iteration and stops on ecx == 0 is
        ; enough. Leave the answer in ax when you return.
        ;
