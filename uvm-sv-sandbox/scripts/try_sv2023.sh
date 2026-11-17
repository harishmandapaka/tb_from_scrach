#!/usr/bin/env bash
# SPDX-License-Identifier: Apache-2.0
# Which IEEE 1800-2023 (SystemVerilog 2023) features does your simulator accept?
# Builds and runs each file in experiments/sv2023/ on its own and prints a table.
set -uo pipefail

usage() {
  cat <<'USAGE'
Usage: bash scripts/try_sv2023.sh [-s verilator|xsim] [-d DEFINE]... [name ...]
  -s SIM     verilator (default) or xsim
  -d NAME    add a define, e.g. -d SHOW_ERRORS (adds code the standard forbids)
  name ...   run only these experiments (file names without .sv)
USAGE
}

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
EXP_DIR="$ROOT/experiments/sv2023"
SIM=verilator
DEFS=()
while getopts "s:d:h" opt; do
  case "$opt" in
    s) SIM="$OPTARG" ;;
    d) DEFS+=("$OPTARG") ;;
    h) usage; exit 0 ;;
    *) usage; exit 2 ;;
  esac
done
shift $((OPTIND - 1))

if [ -x "$ROOT/third_party/verilator/bin/verilator" ]; then
  export PATH="$ROOT/third_party/verilator/bin:$PATH"
fi

case "$SIM" in
  verilator) TOOL=verilator ;;
  xsim)      TOOL=xvlog ;;
  *) echo "ERROR: unknown simulator '$SIM' (use verilator or xsim)" >&2; exit 2 ;;
esac
if ! command -v "$TOOL" >/dev/null 2>&1; then
  echo "ERROR: '$TOOL' is not on PATH." >&2
  exit 2
fi

files=()
if [ $# -gt 0 ]; then
  for name in "$@"; do
    f="$EXP_DIR/${name%.sv}.sv"
    if [ ! -f "$f" ]; then
      echo "ERROR: no experiment called '$name' in experiments/sv2023/" >&2
      exit 2
    fi
    files+=("$f")
  done
else
  files=("$EXP_DIR"/*.sv)
fi

TIMEOUT=""
if command -v timeout >/dev/null 2>&1; then TIMEOUT="timeout 120"; fi

OUT_ROOT="$ROOT/build/sv2023/$SIM"
mkdir -p "$OUT_ROOT"
rows=()
for f in "${files[@]}"; do
  name="$(basename "$f" .sv)"
  dir="$OUT_ROOT/$name"
  rm -rf "$dir"
  mkdir -p "$dir"
  built=0
  case "$SIM" in
    verilator)
      vdefs=()
      for d in ${DEFS[@]+"${DEFS[@]}"}; do vdefs+=("+define+$d"); done
      if verilator --binary -Wno-fatal -Wno-lint -Wno-style --top-module exp_top \
           --Mdir "$dir" ${vdefs[@]+"${vdefs[@]}"} "$f" > "$dir/compile.log" 2>&1; then
        built=1
        ( cd "$dir" && $TIMEOUT ./Vexp_top ) > "$dir/run.log" 2>&1
      fi
      ;;
    xsim)
      xdefs=()
      for d in ${DEFS[@]+"${DEFS[@]}"}; do xdefs+=(-d "$d"); done
      if ( cd "$dir" && xvlog -sv ${xdefs[@]+"${xdefs[@]}"} "$f" && xelab exp_top -s exp_snap ) \
           > "$dir/compile.log" 2>&1; then
        built=1
        ( cd "$dir" && $TIMEOUT xsim exp_snap -R ) > "$dir/run.log" 2>&1
      fi
      ;;
  esac
  if [ "$built" = 0 ]; then
    result="not accepted (compile/elaborate error)"
  elif grep -qE '^(# )?PASS:' "$dir/run.log"; then
    result="works"
  elif grep -qE '^(# )?FAIL:' "$dir/run.log"; then
    result="compiles, wrong result"
  else
    result="compiles, no result line"
  fi
  rows+=("$(printf '%-32s %s' "$name" "$result")")
done

echo
echo "IEEE 1800-2023 feature survey on $SIM"
printf '%-32s %s\n' "EXPERIMENT" "RESULT"
for r in "${rows[@]}"; do echo "$r"; done
echo
echo "Logs: build/sv2023/$SIM/<experiment>/compile.log and run.log"
for d in ${DEFS[@]+"${DEFS[@]}"}; do
  if [ "$d" = SHOW_ERRORS ]; then
    echo "Note: with SHOW_ERRORS, a compile error in class_final, method_override_qualifiers"
    echo "      and constraint_override_qualifiers is the CORRECT result (that code is illegal)."
  fi
done
exit 0
