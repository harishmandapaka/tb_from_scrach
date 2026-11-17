// SPDX-License-Identifier: Apache-2.0
// IEEE 1800-2023: `ifdef, `ifndef and `elsif can test an expression of macro names
// with !, &&, ||, -> and <->. The expression must be in parentheses.
`define FEATURE_A

module exp_top;
  int hits = 0;
  initial begin
`ifdef (FEATURE_A && !FEATURE_B)
    hits++;                          // must be taken
`endif
`ifdef (FEATURE_B || FEATURE_A)
    hits++;                          // must be taken
`endif
`ifdef FEATURE_B
    hits = -100;                     // FEATURE_B is not defined: must be skipped
`endif
    if (hits == 2) $display("PASS: ifdef_expression");
    else           $display("FAIL: ifdef_expression (hits=%0d)", hits);
    $finish;
  end
endmodule
