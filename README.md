<!--no-pdf-->
# CMSC 131 Lab 1 Starter

Decode, encode, and checksum 20-byte IPv4 packet headers under a C driver. The manual is the assignment. This file is the repository's own notes.

## Layout

```text
Makefile        platform preamble and build rules
driver.c        provided: argument parsing and file I/O
cdecl.h         provided: the calling-convention macros
decode.asm      yours
encode.asm      yours
checksum.asm    yours
run_tests.sh    provided: the correctness gate
tests/          provided: the test corpus
LICENSE         CC BY-NC-SA 4.0, inherited from the pcasm material
```

## What to Run

```bash
make
make check
```

`make` builds `renpkt`. `make check` builds, then runs `./run_tests.sh`,
which reports each test and exits nonzero when any of them differ.

## Reading a First Run

The assembly files ship as stubs that assemble and link as-is, so the build
works before any code is written. Right now they do nothing useful, which
makes every check fail. That red run is the correct starting state for a
starter, and the badge stays red until the routines are implemented.

The provided files are fixtures. The grader compares your fork against the
starter, so an edited `driver.c`, `Makefile`, `run_tests.sh`, or `tests/`
file shows up as a diff in the open.
