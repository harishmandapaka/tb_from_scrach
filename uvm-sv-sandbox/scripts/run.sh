#!/usr/bin/env bash
# SPDX-License-Identifier: Apache-2.0
# Build and run the adder UVM testbench on a free simulator, then decide PASS/FAIL.
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage: bash scripts/run.sh [options]
  -s SIM        verilator (default) or xsim
  -t TEST       UVM test class: add_test (default) or add_corner_test
  -r SEED       random seed (default 1)
  -v VERBOSITY  UVM_NONE, UVM_LOW (default), UVM_MEDIUM, UVM_HIGH or UVM_FULL
  -b            build the DUT with a deliberate bug; the run must then FAIL
  -w            write waves to build/<sim>/<variant>/waves.vcd
  -n            reuse an existing build instead of rebuilding
  -h            show this help
Logs go to build/logs/.
USAGE
}

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SIM=verilator
TEST=add_test
SEED=1
VERBOSITY=UVM_LOW
BUG=0
WAVES=0
REUSE=0

while getopts "s:t:r:v:bwnh" opt; do
  case "$opt" in
    s) SIM="$OPTARG" ;;
    t) TEST="$OPTARG" ;;
    r) SEED="$OPTARG" ;;
    v) VERBOSITY="$OPTARG" ;;
    b) BUG=1 ;;
    w) WAVES=1 ;;
    n) REUSE=1 ;;
    h) usage; exit 0 ;;
    *) usage; exit 2 ;;
  esac
done

# Prefer a Verilator built by "bash scripts/setup.sh --build-verilator".
if [ -x "$ROOT/third_party/verilator/bin/verilator" ]; then
  export PATH="$ROOT/third_party/verilator/bin:$PATH"
fi

TOP=tb_top
SRCS=("$ROOT/rtl/adder.sv" "$ROOT/tb/add_if.sv" "$ROOT/tb/add_pkg.sv" "$ROOT/tb/tb_top.sv")
DEFINES=()
VARIANT=clean
EXPECT=pass
if [ "$BUG" = 1 ]; then
  DEFINES+=(INJECT_BUG)
  VARIANT=bug
  EXPECT=fail
fi
if [ "$WAVES" = 1 ]; then
  DEFINES+=(DUMP_WAVES)
  VARIANT="${VARIANT}_waves"
fi
OUT="$ROOT/build/$SIM/$VARIANT"
LOG="$ROOT/build/logs/${SIM}_${TEST}_seed${SEED}_${VARIANT}.log"
mkdir -p "$OUT" "$ROOT/build/logs"

ncpu() { nproc 2>/dev/null || sysctl -n hw.ncpu 2>/dev/null || echo 2; }
need() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "ERROR: '$1' is not on PATH. $2" >&2
    exit 2
  fi
}

echo "== simulator=$SIM test=$TEST seed=$SEED dut=$VARIANT =="
case "$SIM" in
  verilator)
    need verilator "Build one with: make verilator-build (or bash scripts/setup.sh --build-verilator)"
    UVM_HOME="${UVM_HOME:-$ROOT/third_party/uvm/src}"
    if [ ! -f "$UVM_HOME/uvm_pkg.sv" ]; then
      echo "ERROR: UVM sources not found in $UVM_HOME. Run: make setup (or bash scripts/setup.sh)" >&2
      exit 2
    fi
    VL_ARGS=(-Wno-fatal -Wno-lint -Wno-style --binary -j "$(ncpu)" --timescale 1ns/1ps
             --top-module "$TOP" --Mdir "$OUT" +incdir+"$UVM_HOME" +define+UVM_NO_DPI)
    for d in ${DEFINES[@]+"${DEFINES[@]}"}; do VL_ARGS+=("+define+$d"); done
    if [ "$WAVES" = 1 ]; then VL_ARGS+=(--trace); fi
    if [ "$REUSE" = 0 ] || [ ! -x "$OUT/V$TOP" ]; then
      verilator "${VL_ARGS[@]}" "$UVM_HOME/uvm_pkg.sv" "${SRCS[@]}"
    fi
    ( cd "$OUT" && "./V$TOP" "+UVM_TESTNAME=$TEST" "+UVM_VERBOSITY=$VERBOSITY" "+verilator+seed+$SEED" ) 2>&1 \
      | tee "$LOG" || true
    ;;
  xsim)
    need xvlog "Source Vivado's settings64.sh first."
    X_DEFS=()
    for d in ${DEFINES[@]+"${DEFINES[@]}"}; do X_DEFS+=(-d "$d"); done
    if [ "$REUSE" = 0 ] || [ ! -d "$OUT/xsim.dir/${TOP}_snap" ]; then
      ( cd "$OUT" && xvlog -sv -L uvm ${X_DEFS[@]+"${X_DEFS[@]}"} "${SRCS[@]}" \
                  && xelab "$TOP" -L uvm -s "${TOP}_snap" )
    fi
    ( cd "$OUT" && xsim "${TOP}_snap" -R -testplusarg "UVM_TESTNAME=$TEST" \
                  -testplusarg "UVM_VERBOSITY=$VERBOSITY" -sv_seed "$SEED" ) 2>&1 \
      | tee "$LOG" || true
    ;;
  *)
    echo "ERROR: unknown simulator '$SIM' (use verilator or xsim)" >&2
    exit 2
    ;;
esac

bash "$ROOT/scripts/check_log.sh" "$LOG" "$EXPECT" "$TEST"
