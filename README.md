<!--no-pdf-->
# CMSC 131 Lab 1 Starter

[![lab1-checks](https://github.com/WhiteLicorice/cmsc-131-lab1-starter/actions/workflows/test.yml/badge.svg)](https://github.com/WhiteLicorice/cmsc-131-lab1-starter/actions/workflows/test.yml)

Decode, encode, and checksum 20-byte IPv4 packet headers under a C driver.
The manual is the assignment. This file is the repository's own notes.

## Layout

```text
Makefile            platform preamble and build rules
driver.c            provided: argument parsing and file I/O
cdecl.h             provided: the calling-convention macros
decode.asm          yours
encode.asm          yours
checksum.asm        yours
run_tests.sh        provided: the correctness gate
contract_test.c     provided: the second pass, in C
contract_regs.asm   provided: register discipline checks for contract_test
tests/              provided: the header fixtures, their expected output,
                    and manifest.txt, the list both passes read
LICENSE             CC BY-NC-SA 4.0, inherited from the pcasm material
```

## What to Run

On Windows, run these commands in Git Bash, the shell from Block 1. In that
shell, `make` is your alias for `mingw32-make`. On Linux, use your terminal.

```bash
make
make check
```

`make` builds `renpkt` and `contract_test`. `make check` builds both, then
runs `./run_tests.sh`, which reports each test and exits nonzero when any
of them differ.

The gate has two passes. The first decodes every header listed in
`tests/manifest.txt` and compares the output with `tests/expected/`. The
second is `contract_test`. It decodes and re-encodes every header the
manifest marks valid. It checks a checksum vector that needs the carry
folded twice. It checks that all three routines keep `ebx`, `esi`, `edi`,
and `ebp`, and return with `esp` where the call left it. A program can pass
the first pass and fail the second. That failure is the usual encoder bug.

## Reading a First Run

The assembly files ship as stubs that assemble and link as-is, so the build
works before you write any code. Right now they do nothing useful, which
makes every check fail: `7 of 7 checks differ`. That red run is the correct
starting state for a starter. The badge stays red until you implement the
routines.

## Adding a Header

Put the header in `tests/NAME.bin`. Write the output `renpkt --decode`
must print for it in `tests/expected/NAME.out`. Then add one line to
`tests/manifest.txt`:

```text
NAME valid
```

Use `invalid` for a header with a wrong checksum. A valid header joins the
round trip in `contract_test` as well as the decode pass. The gate fails
and names the file when a `.bin` is not in the manifest, and when a listed
header has no expected file.

## The Driver's Argument Checks

`renpkt --encode` refuses a value its field cannot hold, and two values the
standard forbids. `--len` takes 20 through 65535, because the total length
counts the header. It defaults to 20. `--flags` takes 0 through 3, because
the top bit of the field is reserved and must be zero. `--df` sets 2 and
`--mf` sets 1. A refused option exits with status 2 and writes no file.

## Documentation

The three sections at the end of this file are yours. Complete Design Notes
and Subsystem Ownership before the Week 1 progress report. Complete Quirks
and Issues before the Week 3 progress report. Each section says what it
needs. Leave the rest of this file as it is.

## Fixtures

The provided files are fixtures. The grader compares your fork against the
starter. An edit to `driver.c`, `Makefile`, `run_tests.sh`,
`contract_test.c`, `contract_regs.asm`, or a provided `tests/` file appears
as a diff in the open. Your own headers and manifest lines are additions,
not edits.

---

## Design Notes

Complete this section before the Week 1 progress report. The syllabus asks
for problem analysis, a solution architecture, and an estimated timeline.
Keep each part short. Update it when the plan changes.

### Problem analysis

<<<<<<< Updated upstream
What the tool must read, what it must write, and which field is the hard
one. State the header layout in your own words.

### Solution architecture

How the three routines split the work. Which registers each routine uses,
and how the struct offsets in `driver.c` map to the fields.
=======
**Decode subsystem (`decode.asm`)**
The decode routine reads a 20-byte IPv4 base header and extracts its 13 fields into the ipv4_fields structure provided by the C driver. Since IPv4 stores multi-byte fields in network byte order (big-endian), these values must be reconstructed correctly when reading the header bytes.

Some fields share a byte, such as Version and IHL in the first byte, and DSCP and ECN in the second byte. The Flags and Fragment Offset fields also share two bytes, requiring bit shifting and masking to extract them separately.

**Encode Subsystem ('encode.asm')**
The encode routine builds a 20-byte IPv4 base header from the ipv4_fields structure. It reads 12 of the 13 fields and writes each at its position in the header. The checksum member is not copied. It is computed at the end instead.

Some fields share a byte and must be packed: Version and IHL in byte 0, DSCP and ECN in byte 1. Flags (3 bits) and Fragment Offset (13 bits) share bytes 6-7, so they are combined into one 16-bit word before being split into two bytes. The 16-bit fields (Total Length, Identification, and the flags/offset word) must be written in network byte order, high byte first.

### Solution architecture

**Decode subsystem (`decode.asm`)**
The decode routine is implemented in decode.asm and follows the 32-bit cdecl calling convention. It receives two arguments: a pointer to the 20-byte header and a pointer to the output structure.

It extracts each field using byte access, bitwise operations, and shifts. Multi-byte fields are reconstructed in big-endian order by combining their bytes. Fields occupying only part of a byte are isolated using shifts and masks.

The extracted values are stored at their corresponding offsets in the output structure:

Offsets 0–12: Version, IHL, DSCP, and ECN.

Offsets 16–28: Total Length, Identification, Flags, and Fragment Offset.

Offsets 32–40: TTL, Protocol, and Header Checksum.

Offsets 44–47: Source Address.

Offsets 48–51: Destination Address.

The routine uses pusha and popa to preserve general-purpose registers, follows the stack frame established with enter and leave, and returns with the stack balanced.

The decode implementation was completed and tested against the provided IPv4 header fixtures. An additional fixture, edge_dscp_ecn.bin, was added to exercise the extraction of mixed DSCP and ECN values and verify that the two fields are correctly separated from the same byte.

**Encode Subsystem ('encode.asm')**
The routine follows the 32-bit cdecl convention. After enter 0,0, in (the struct) is at [ebp+8] and hdr (the output buffer) is at [ebp+12]. esi holds in and is only read from. edi holds hdr and is only written to. Neither register moves, so every access is a fixed offset from one of them.

Fields are handled in three groups:
- Fields sharing a byte are masked to their width, shifted into position, and combined with or (byte 0 and byte 1).
- The straddling field is built as one 16-bit word: flags & 0x07 shifted left 13, or'd with fragment_offset & 0x1FFF, then split into bytes 6 and 7.
- Everything else is stored directly. 16-bit fields are split with shr 8 (high byte first, low byte second), which is the big-endian conversion done by hand. TTL and protocol are single bytes. The addresses are copied byte by byte, since they are already in network order.

The checksum is handled in order: bytes 10-11 are zeroed, ip_checksum(hdr, 20) is called over the finished header (arguments pushed right to left, caller removes them with add esp, 8), and the result in ax is stored with ah in byte 10 and al in byte 11.
>>>>>>> Stashed changes

### Timeline

One line per week. Name the subsystem each week finishes and the member
who owns it.

| Week | Goal | Owner |
|---|---|---|
| 1 | | |
| 2 | | |
| 3 | | |
| 4 | Defense | |

## Subsystem Ownership

Complete this section before the Week 1 progress report. The manual lists
the three subsystems. Each member owns one. In a group of four, two members
share one. The commit history must agree with this table.

| Subsystem | Owner |
|---|---|
| Decode path (`decode.asm`) | |
| Encode path (`encode.asm`) | |
| Checksum and tests (`checksum.asm`, `tests/`) | |

## Quirks and Issues

Complete this section before the Week 3 progress report. The syllabus asks
for documentation of quirks and issues with the complete implementation.
One entry per item. State what happens, what causes it, and what the group
did about it.

### Known issues

- 

### Quirks

- 
