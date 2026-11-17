// SPDX-License-Identifier: Apache-2.0
// IEEE 1800-2023: a covergroup declared in a class can be extended in a subclass,
// keeping the base coverpoints and adding new ones (including crosses with them).
// Few tools support this yet; this file only checks that it compiles and runs.
module exp_top;
  class base_c;
    rand bit [2:0] a;
    covergroup cg;
      cp_a: coverpoint a;
    endgroup
    function new();
      cg = new();
    endfunction
  endclass

  class sub_c extends base_c;
    rand bit [1:0] b;
    covergroup extends cg;
      cp_b:  coverpoint b;
      a_x_b: cross cp_a, cp_b;
    endgroup
    function new();
      super.new();
    endfunction
  endclass

  sub_c s;
  initial begin
    s = new();
    repeat (200) begin
      void'(s.randomize());
      s.cg.sample();
    end
    $display("PASS: covergroup_extends (coverage %0.1f%%)", s.cg.get_inst_coverage());
    $finish;
  end
endmodule
