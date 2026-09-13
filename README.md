<!--no-pdf-->
# CMSC 131 Lab 1 Starter

Decode, encode, and checksum 20-byte IPv4 packet headers under a C driver. The manual is the assignment. This file is the repository's own notes.

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
tests/              provided: the test corpus
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

The gate has two passes. The first decodes every header in `tests/` and
compares the output with `tests/expected/`. The second is `contract_test`,
which decodes and re-encodes every valid sample, checks a checksum vector
that needs the carry folded twice, and checks that all three routines keep
`ebx`, `esi`, `edi`, and `esp`. A program can pass the first pass and fail
the second. That failure is the usual encoder bug.

## Reading a First Run

The assembly files ship as stubs that assemble and link as-is, so the build
works before any code is written. Right now they do nothing useful, which
makes every check fail. That red run is the correct starting state for a
starter. The badge stays red until the routines are implemented.

The provided files are fixtures. The grader compares your fork against the
starter, so an edited `driver.c`, `Makefile`, `run_tests.sh`, or `tests/`
file shows up as a diff in the open.
