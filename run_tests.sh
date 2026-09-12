#!/usr/bin/env bash
#
# renpkt correctness gate. Runs every header in tests/ through --decode and
# diffs the output against tests/expected/. Every case must match byte for
# byte. The comparison strips trailing carriage returns, for the reason
# Block 1 explained.
#
#       ./run_tests.sh
#
# Build renpkt first (make). The script reports each case and exits nonzero
# if any of them differ.

set -u

bin="./renpkt"
if [ ! -x "$bin" ] && [ -x "$bin.exe" ]; then
    bin="$bin.exe"
fi

if [ ! -x "$bin" ]; then
    echo "run_tests.sh: $bin not found. Build it first: make" >&2
    exit 1
fi

failures=0
total=0

for header in tests/*.bin; do
    name="$(basename "$header" .bin)"
    expected="tests/expected/$name.out"
    total=$((total + 1))

    if ! "$bin" --decode "$header" | diff -u --strip-trailing-cr \
        --label "$expected" --label "what renpkt printed" "$expected" -; then
        echo "FAIL  $name"
        failures=$((failures + 1))
    else
        echo "ok    $name"
    fi
done

echo
if [ "$failures" -eq 0 ]; then
    echo "All $total headers decoded correctly."
    exit 0
else
    echo "$failures of $total headers differ."
    exit 1
fi
