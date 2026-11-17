// SPDX-License-Identifier: Apache-2.0
// IEEE 1800-2023: "class :final" stops a class from being extended.
// Build with the define SHOW_ERRORS to add an illegal subclass; a tool that
// supports the feature must then refuse to compile.
module exp_top;
  class :final leaf_c;
    int value = 7;
  endclass

`ifdef SHOW_ERRORS
  class bad_c extends leaf_c;        // illegal: leaf_c is :final
  endclass
`endif

  leaf_c h;
  initial begin
    h = new();
    if (h.value == 7) $display("PASS: class_final");
    else              $display("FAIL: class_final");
    $finish;
  end
endmodule
