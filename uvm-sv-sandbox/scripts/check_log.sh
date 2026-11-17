#!/usr/bin/env bash
# SPDX-License-Identifier: Apache-2.0
# Decide PASS/FAIL from a simulation log.
#
# Usage: bash scripts/check_log.sh LOG [pass|fail] [TEST]
#   pass  (default) the log must say "TEST PASSED" and the UVM report summary
#         must show 0 UVM_ERROR and 0 UVM_FATAL
#   fail  for the deliberate-bug run: the log must say "TEST FAILED" with at
#         least one UVM_ERROR, which means the scoreboard caught the bug
#   TEST  if given, the log must show that this test is the one that ran
set -u

LOG="${1:-}"
EXPECT="${2:-pass}"
TEST="${3:-}"

if [ -z "$LOG" ] || [ ! -f "$LOG" ]; then
  echo "RESULT: FAIL (log not found: ${LOG:-none given})"
  exit 1
fi

# Last "UVM_<SEVERITY> : <count>" line of the UVM report summary.
count() {
  grep -E "^(# )?$1 *: *[0-9]+ *$" "$LOG" | tail -n 1 | sed -E 's/.*: *([0-9]+) *$/\1/'
}

errors="$(count UVM_ERROR)"
fatals="$(count UVM_FATAL)"
if [ -z "$errors" ] || [ -z "$fatals" ]; then
  echo "RESULT: FAIL (no UVM report summary in the log, so the run did not finish; log: $LOG)"
  exit 1
fi

if [ -n "$TEST" ] && ! grep -qE "\[TEST\] running ${TEST}([^A-Za-z0-9_]|\$)" "$LOG"; then
  echo "RESULT: FAIL (expected test '$TEST' to run, but the log does not show it; log: $LOG)"
  exit 1
fi

score="$(grep -oE 'passed=[0-9]+ failed=[0-9]+' "$LOG" | tail -n 1)"

case "$EXPECT" in
  pass)
    if grep -q 'TEST PASSED' "$LOG" && [ "$errors" -eq 0 ] && [ "$fatals" -eq 0 ]; then
      echo "RESULT: PASS (${score:-no scoreboard line}; log: $LOG)"
      exit 0
    fi
    echo "RESULT: FAIL (UVM_ERROR=$errors UVM_FATAL=$fatals ${score}; log: $LOG)"
    exit 1
    ;;
  fail)
    if grep -q 'TEST FAILED' "$LOG" && [ "$errors" -gt 0 ]; then
      echo "RESULT: PASS (the deliberate DUT bug was caught: UVM_ERROR=$errors; log: $LOG)"
      exit 0
    fi
    echo "RESULT: FAIL (the deliberate DUT bug was NOT caught: UVM_ERROR=$errors UVM_FATAL=$fatals; log: $LOG)"
    exit 1
    ;;
  *)
    echo "usage: bash scripts/check_log.sh LOG [pass|fail] [TEST]"
    exit 2
    ;;
esac
