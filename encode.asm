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
;       unsigned char *hdr        [ebp+12] ; destination
;       struct ipv4_fields *in    [ebp+8] ; source
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

segment .text
        global  _encode_header
_encode_header:
        enter   0,0
        pusha

        ;
        ; TODO: build the header from the struct.
        ;
        ; This is the reverse of decode. Mask each field to its width,
        ; shift it up to where it lives, or the pieces of a shared byte
        ; together, then store the byte. The fields that do not straddle
        ; anything are one store each.
        ;
        ; The checksum comes last, after every other byte is written. Write
        ; bytes 10-11 as zero, call ip_checksum with the header and 20, and
        ; store its result (in ax) into the field big-endian. Computing it
        ; before the rest of the header is in place sums whatever garbage
        ; was in the buffer. ip_checksum preserves ebx, esi, edi, and ebp,
        ; so a pointer kept in one of those survives the call. eax, ecx, and
        ; edx do not.
        ;

        mov     esi, [ebp + 8]
        mov     edi, [ebp + 12]

       
        ; 1st DWord
        ; byte 0 = Version | IHL
        ; bits 7-4 = Version
        ; bits 3-0 = IHL

        mov     eax, [esi + 16]
        mov    [edi], eax

        ; 1st DoubleWord
        ; byte 0 = Version | IHL
        ; bits 7-4 = Version
        ; bits 3-0 = IHL
        xor     ebx, ebx
        mov     eax, [esi]          ; eax = version
        and     eax, 0x0000000F     ; keep only 4 bits
        shl     eax, 4              ; move version to bits 7-4
        or      ebx, eax

        mov     eax, [esi + 4]      ; eax = IHL
        and     eax, 0x0000000F     ; keep only 4 bits
        or      ebx, eax
        

        ; byte 1 -> DSCP | ECN
        ; 7 - 2 | 1 - 0
        ; width 6 | 2
        ; DCSP
        mov     eax, [esi + 8]
        and     eax, 0x0000003F
        shl     eax, 10
        or      ebx, eax
       
        ; ECN
        mov     eax, [esi + 12]
        and     eax, 0x00000003
        shl     eax, 8
        or      ebx, eax

        ; 2 - 3 Byte
        ; 8 | 8
        mov     eax, [esi + 16]
        and     eax, 0x000000FF
        shl     eax, 24
        or      ebx, eax

        mov     eax, [esi + 16]
        and     eax, 0x0000FF00
        shl     eax, 8

        mov     [edi], ebx
        
       
        

        



        




        


        



        popa
        mov     eax, 0
        leave
        ret
