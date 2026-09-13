#!/usr/bin/env bash
#
# renpkt correctness gate. It runs two passes.
#
# Pass 1, decode. Every header in tests/ goes through --decode. The output
# is captured, the program's status is read, and the output is compared
# against tests/expected/. The comparison strips trailing carriage returns,
# for the reason Block 1 explained.
#
# Pass 2, contract. ./contract_test decodes and re-encodes every valid
# sample, checks the checksum vector that needs two carry folds, and checks
# the register discipline of all three routines. That pass catches what the
# output comparison cannot see: a lost field on the encode path, a truncated
# fold, and a clobbered callee-saved register.
#
#       ./run_tests.sh
#
# Build first (make). The script reports each case and exits nonzero when a
# case differs, when the program crashes, or when the program returns
# nonzero. The program's status is read before the comparison runs, so a
# correct-looking output cannot hide a crash.

set -uo pipefail

bin="./renpkt"
if [ ! -x "$bin" ] && [ -x "$bin.exe" ]; then
    bin="$bin.exe"
fi

if [ ! -x "$bin" ]; then
    echo "run_tests.sh: $bin not found. Build it first: make" >&2
    exit 1
fi

# The decode pass captures each run here, then removes the file.
out="./.decode.out"
trap 'rm -f "$out"' EXIT

failures=0
total=0

for header in tests/*.bin; do
    name="$(basename "$header" .bin)"
    expected="tests/expected/$name.out"
    total=$((total + 1))

    "$bin" --decode "$header" > "$out" 2>/dev/null
    status=$?

    if [ "$status" -ne 0 ]; then
        echo "FAIL  $name (the program exited with status $status)"
        failures=$((failures + 1))
        continue
    fi

    if diff -u --strip-trailing-cr \
        --label "$expected" --label "what renpkt printed" "$expected" "$out"; then
        echo "ok    $name"
    else
        echo "FAIL  $name"
        failures=$((failures + 1))
    fi
done

# The contract pass. One more check, and it lives in its own program.
testbin="./contract_test"
if [ ! -x "$testbin" ] && [ -x "$testbin.exe" ]; then
    testbin="$testbin.exe"
fi

if [ ! -x "$testbin" ]; then
    echo "run_tests.sh: $testbin not found. Build it first: make" >&2
    exit 1
fi

total=$((total + 1))
if "$testbin"; then
    echo "ok    contract"
else
    echo "FAIL  contract"
    failures=$((failures + 1))
fi

echo
if [ "$failures" -eq 0 ]; then
    echo "All $total checks passed."
    exit 0
else
    echo "$failures of $total checks differ."
    exit 1
fi
