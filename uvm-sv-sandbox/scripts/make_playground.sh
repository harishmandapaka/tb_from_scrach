#!/usr/bin/env bash
# SPDX-License-Identifier: Apache-2.0
# Writes the two files EDA Playground expects:
#   build/playground/design.sv     <- rtl/adder.sv
#   build/playground/testbench.sv  <- tb/add_if.sv + tb/add_pkg.sv + tb/tb_top.sv
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OUT="$ROOT/build/playground"
mkdir -p "$OUT"
cp "$ROOT/rtl/adder.sv" "$OUT/design.sv"
{
  cat "$ROOT/tb/add_if.sv";  echo
  cat "$ROOT/tb/add_pkg.sv"; echo
  cat "$ROOT/tb/tb_top.sv"
} > "$OUT/testbench.sv"

cat <<'MSG'
Wrote build/playground/design.sv and build/playground/testbench.sv.
On https://www.edaplayground.com :
  1. Paste design.sv into the design.sv pane and testbench.sv into the testbench.sv pane.
  2. Languages & Libraries: SystemVerilog/Verilog, and UVM 1.2 as the library.
  3. Pick a simulator and click Run. Look for "*** TEST PASSED ***" in the log.
  4. Other test: add +UVM_TESTNAME=add_corner_test to the run options.
     Broken DUT: add +define+INJECT_BUG to the compile options (the run must then fail).
MSG
