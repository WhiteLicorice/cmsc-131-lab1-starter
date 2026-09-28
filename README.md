<!--no-pdf-->
# CMSC 131 Lab 1 Starter

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

| Field | Size | Description |
|---|---|---|
| Version | 4 | IPv4 is used, therefore this value is always 4 in decimal (0100) |
| Header Length (IHL) | 4 bit | This 4-bit field tells us the length of the IP header in 32-bit increments. With 4 bits in 32-bit increments, the max header length we can make with this is 60 bytes. This is the absolute limit of the header length.|
| Type of Service | 6 bits(DSCP), 2 bits(ECN) |DSCP is used to tell what priority the packet has. The ECN field enables congestion notification, which allows senders to slow down before packet loss.  |
| Total Length: | 16 bits | indicates  the entire size of the IP packet (header and data) in bytes [100(decimal) => 100 bytes]. If you have no data, the size is 20 bytes. |
| Identification | 16 bits | If fragmented, the packet will use this to identify whih IP packet it belongs to. All fragments of a packet use the same ID |
| IP Flags | 3 bits  | 1st bit is reserved and MUST always be set to 0. 2nd bit (Don't Fragment [DF]), means that the packet should not be fragmented by the router. 3rd bit (More Fragments [MF]) means that fragments can follow. |
| Fragment Offset | 13 bits | Specifies the position of the fragment in the original fragmented IP packet, it is measured in 8-byte units. (decimal value of bits) * 8 = (starting point of data) |
| Time to Live TTL | 8 bits  | A sort of timer "hop count" that decrements each time the packet passes through a router, it times out if it reaches 0. |
| Protocol | 8 bits | Tells us which protocol the packet uses. |
| Header Checksum | 16 bits | Can be used to detect errors in the header but does not validate the data if ever |
| Source Address | 32 bits | The sender's IP address |
| Destination Address | 32 bits | The destination IP address |
| Checksum Validation | ---? | Used to see if the checksum was valid, not included in the packet. just in the C print |
Reference: https://networklessons.com/ip-routing/ipv4-packet-header


### Problem analysis

What the tool must read, what it must write, and which field is the hard
one. State the header layout in your own words.

### Solution architecture

How the three routines split the work. Which registers each routine uses,
and how the struct offsets in `driver.c` map to the fields.

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
| Decode path (`decode.asm`) | EJ Tolentino |
| Encode path (`encode.asm`) | Julian Medalla |
| Checksum and tests (`checksum.asm`, `tests/`) | JB Aparicio |

## Quirks and Issues

Complete this section before the Week 3 progress report. The syllabus asks
for documentation of quirks and issues with the complete implementation.
One entry per item. State what happens, what causes it, and what the group
did about it.

### Known issues

- 

### Quirks

- 
