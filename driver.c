/*
 * renpkt - read and write IPv4 headers. Provided to the group. Do not modify.
 *
 * This file does everything that is not bit manipulation: it parses the
 * command line, opens files, reads the twenty bytes of a header into a
 * buffer, calls the assembly routines below, and formats the output. Your
 * defense will use this copy, so what it prints and the struct it fills are
 * the contract. Read this file before writing assembly.
 *
 * The three routines you implement are declared at the bottom, with the
 * struct they share. Everything else in here is the part the activity is
 * not about.
 */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "cdecl.h"

/* ------------------------------------------------------------------ */
/* The header layout, once.                                            */
/*                                                                    */
/* Twenty bytes, bit positions counted from the most significant bit  */
/* of each byte:                                                      */
/*                                                                    */
/*   byte  0        1        2        3                               */
/*       +--------+--------+--------+--------+                       */
/*    0  |Ver|IHL |DSCP|ECN|   Total Length  |                       */
/*       +--------+--------+--------+--------+                       */
/*    4  |  Identification |Flg| Frag Offset |                       */
/*       +--------+--------+--------+--------+                       */
/*    8  |  TTL   |Protocol|  Header Checksum|                       */
/*       +--------+--------+--------+--------+                       */
/*   12  |            Source Address         |                       */
/*       +--------+--------+--------+--------+                       */
/*   16  |         Destination Address       |                       */
/*       +--------+--------+--------+--------+                       */
/*                                                                    */
/* The struct below is what decode_header fills and encode_header     */
/* reads. Its layout is deliberate: every member is an unsigned int   */
/* so the assembly can store and load them with plain 32-bit moves.   */
/* The two addresses are four octets each, stored as eight separate   */
/* bytes in the struct so the assembly never has to form a multi-     */
/* byte number out of them.                                           */
/*                                                                    */
/* Offsets (each int member is 4 bytes. The octets are single bytes): */
/*                                                                    */
/*   +0  version           +4  ihl                                     */
/*   +8  dscp              +12 ecn                                     */
/*   +16 total_length      +20 identification                          */
/*   +24 flags             +28 fragment_offset                         */
/*   +32 ttl               +36 protocol                                */
/*   +40 checksum                                                      */
/*   +44 src[0] src[1] src[2] src[3]  (bytes 44, 45, 46, 47)           */
/*   +48 dst[0] dst[1] dst[2] dst[3]  (bytes 48, 49, 50, 51)           */
/*   total size 52 bytes                                               */
/* ------------------------------------------------------------------ */

struct ipv4_fields {
    unsigned int version;        /* 4 bits  */
    unsigned int ihl;            /* 4 bits  */
    unsigned int dscp;           /* 6 bits  */
    unsigned int ecn;            /* 2 bits  */
    unsigned int total_length;   /* 16 bits */
    unsigned int identification; /* 16 bits */
    unsigned int flags;          /* 3 bits  */
    unsigned int fragment_offset;/* 13 bits */
    unsigned int ttl;            /* 8 bits  */
    unsigned int protocol;       /* 8 bits  */
    unsigned int checksum;       /* 16 bits */
    unsigned char src[4];        /* 32 bits */
    unsigned char dst[4];        /* 32 bits */
};

/* The three routines you implement. */
void PRE_CDECL decode_header(unsigned char *hdr, struct ipv4_fields *out) POST_CDECL;
void PRE_CDECL encode_header(struct ipv4_fields *in, unsigned char *hdr) POST_CDECL;
unsigned short PRE_CDECL ip_checksum(unsigned char *hdr, int len) POST_CDECL;

/* ------------------------------------------------------------------ */
/* The rest is driver. Read it for the output format, not to change.  */
/* ------------------------------------------------------------------ */

static const char *proto_name(unsigned int p)
{
    switch (p) {
    case 1:  return " (ICMP)";
    case 6:  return " (TCP)";
    case 17: return " (UDP)";
    default: return "";
    }
}

static void print_fields(const struct ipv4_fields *f, int valid)
{
    printf("Version:          %u\n", f->version);
    printf("IHL:              %u (%u bytes)\n", f->ihl, f->ihl * 4);
    printf("DSCP:             %u\n", f->dscp);
    printf("ECN:              %u\n", f->ecn);
    printf("Total Length:     %u\n", f->total_length);
    printf("Identification:   %u\n", f->identification);
    printf("Flags:            %u", f->flags);
    if (f->flags & 0x2) printf(" (DF)");   /* bit 6 of the header */
    if (f->flags & 0x1) printf(" (MF)");   /* bit 5 of the header */
    printf("\n");
    printf("Fragment Offset:  %u\n", f->fragment_offset);
    printf("TTL:              %u\n", f->ttl);
    printf("Protocol:         %u%s\n", f->protocol, proto_name(f->protocol));
    printf("Header Checksum:  0x%04X\n", f->checksum);
    printf("Source:           %u.%u.%u.%u\n", f->src[0], f->src[1], f->src[2], f->src[3]);
    printf("Destination:      %u.%u.%u.%u\n", f->dst[0], f->dst[1], f->dst[2], f->dst[3]);
    printf("Checksum:         %s\n", valid ? "VALID" : "INVALID");
}

static int read_file(const char *path, unsigned char *buf, size_t len)
{
    FILE *f = fopen(path, "rb");
    if (!f) {
        fprintf(stderr, "renpkt: cannot open %s\n", path);
        return 0;
    }
    size_t got = fread(buf, 1, len, f);
    fclose(f);
    if (got != len) {
        fprintf(stderr, "renpkt: %s: expected %u bytes, read %u\n",
                path, (unsigned)len, (unsigned)got);
        return 0;
    }
    return 1;
}

static int write_file(const char *path, const unsigned char *buf, size_t len)
{
    FILE *f = fopen(path, "wb");
    if (!f) {
        fprintf(stderr, "renpkt: cannot open %s\n", path);
        return 0;
    }
    size_t wrote = fwrite(buf, 1, len, f);
    fclose(f);
    if (wrote != len) {
        fprintf(stderr, "renpkt: wrote %u of %u bytes to %s\n",
                (unsigned)wrote, (unsigned)len, path);
        return 0;
    }
    return 1;
}

static int parse_octets(const char *s, unsigned char *out)
{
    unsigned a, b, c, d;
    if (sscanf(s, "%u.%u.%u.%u", &a, &b, &c, &d) != 4 ||
        a > 255 || b > 255 || c > 255 || d > 255) {
        fprintf(stderr, "renpkt: bad address: %s\n", s);
        return 0;
    }
    out[0] = (unsigned char)a;
    out[1] = (unsigned char)b;
    out[2] = (unsigned char)c;
    out[3] = (unsigned char)d;
    return 1;
}

static void usage(void)
{
    fprintf(stderr,
        "usage:\n"
        "  renpkt --decode FILE\n"
        "  renpkt --encode [--ttl N] [--proto N] [--len N] [--id N]\n"
        "                 [--frag N] [--flags N] [--src A.B.C.D] [--dst A.B.C.D]\n"
        "                 [--df] [--mf] -o FILE\n");
    exit(2);
}

static void cmd_decode(int argc, char **argv)
{
    if (argc != 3) usage();
    unsigned char hdr[20];
    if (!read_file(argv[2], hdr, 20)) exit(1);

    struct ipv4_fields f;
    memset(&f, 0, sizeof(f));
    decode_header(hdr, &f);

    /*
     * The decode path does not compare a computed checksum against the
     * stored one. Summing a header that already contains its checksum and
     * testing for zero is the shortcut the manual describes. One's
     * complement arithmetic makes a valid header sum to 0x0000. This is
     * ip_checksum's job, so the VALID line reports what it returned.
     */
    int valid = (ip_checksum(hdr, 20) == 0);
    print_fields(&f, valid);
}

static void cmd_encode(int argc, char **argv)
{
    struct ipv4_fields f;
    memset(&f, 0, sizeof(f));
    f.version = 4;
    f.ihl = 5;

    const char *out = NULL;
    for (int i = 2; i < argc; i++) {
        if (!strcmp(argv[i], "-o") && i + 1 < argc) {
            out = argv[++i];
        } else if (!strcmp(argv[i], "--ttl") && i + 1 < argc) {
            f.ttl = (unsigned)atoi(argv[++i]);
        } else if (!strcmp(argv[i], "--proto") && i + 1 < argc) {
            f.protocol = (unsigned)atoi(argv[++i]);
        } else if (!strcmp(argv[i], "--len") && i + 1 < argc) {
            f.total_length = (unsigned)atoi(argv[++i]);
        } else if (!strcmp(argv[i], "--id") && i + 1 < argc) {
            f.identification = (unsigned)atoi(argv[++i]);
        } else if (!strcmp(argv[i], "--frag") && i + 1 < argc) {
            f.fragment_offset = (unsigned)atoi(argv[++i]);
        } else if (!strcmp(argv[i], "--flags") && i + 1 < argc) {
            f.flags = (unsigned)atoi(argv[++i]);
        } else if (!strcmp(argv[i], "--src") && i + 1 < argc) {
            if (!parse_octets(argv[++i], f.src)) exit(1);
        } else if (!strcmp(argv[i], "--dst") && i + 1 < argc) {
            if (!parse_octets(argv[++i], f.dst)) exit(1);
        } else if (!strcmp(argv[i], "--df")) {
            f.flags |= 0x2;   /* bit 6 of the header is the field's bit 1 */
        } else if (!strcmp(argv[i], "--mf")) {
            f.flags |= 0x1;   /* bit 5 of the header is the field's bit 0 */
        } else {
            usage();
        }
    }
    if (!out) usage();

    unsigned char hdr[20];
    encode_header(&f, hdr);
    if (!write_file(out, hdr, 20)) exit(1);
}

int main(int argc, char **argv)
{
    if (argc < 2) usage();
    if (!strcmp(argv[1], "--decode")) cmd_decode(argc, argv);
    else if (!strcmp(argv[1], "--encode")) cmd_encode(argc, argv);
    else usage();
    return 0;
}
