#!/usr/bin/env bash
# SPDX-License-Identifier: Apache-2.0
# Small regression: two tests that must pass, plus one run with a deliberate DUT
# bug that the scoreboard must catch.
# Usage: bash scripts/regress.sh [-s verilator|xsim] [-r SEED]
set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SIM=verilator
SEED=1
while getopts "s:r:h" opt; do
  case "$opt" in
    s) SIM="$OPTARG" ;;
    r) SEED="$OPTARG" ;;
    h) echo "usage: bash scripts/regress.sh [-s verilator|xsim] [-r SEED]"; exit 0 ;;
    *) exit 2 ;;
  esac
done

summary=()
failed=0
step() {   # step LABEL run.sh-arguments...
  local label="$1"
  shift
  echo
  echo "################ $label ################"
  if bash "$ROOT/scripts/run.sh" -s "$SIM" -r "$SEED" "$@"; then
    summary+=("PASS  $label")
  else
    summary+=("FAIL  $label")
    failed=1
  fi
}

step "add_test"                     -t add_test
step "add_corner_test"              -t add_corner_test -n
step "deliberate DUT bug is caught" -t add_test -b

echo
echo "Regression summary (simulator: $SIM, seed: $SEED)"
for line in "${summary[@]}"; do echo "  $line"; done
if [ "$failed" = 0 ]; then
  echo "ALL PASSED"
else
  echo "SOME CHECKS FAILED (logs are in build/logs/)"
fi
exit "$failed"
