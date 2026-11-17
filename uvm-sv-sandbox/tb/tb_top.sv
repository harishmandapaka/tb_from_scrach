// SPDX-License-Identifier: Apache-2.0
// Top module: clock, reset, DUT, interface, and the call that starts UVM.
`timescale 1ns/1ps

module tb_top;
  import uvm_pkg::*;
  import add_pkg::*;

  logic clk = 1'b0;
  always #5 clk = ~clk;              // 10 ns period

  add_if intf (clk);

  adder dut (
    .clk      (clk),
    .rst_n    (intf.rst_n),
    .in_valid (intf.in_valid),
    .a        (intf.a),
    .b        (intf.b),
    .out_valid(intf.out_valid),
    .sum      (intf.sum)
  );

  // Hold reset for 3 clocks.
  initial begin
    intf.rst_n = 1'b0;
    repeat (3) @(posedge clk);
    intf.rst_n <= 1'b1;
  end

`ifdef DUMP_WAVES
  initial begin
    $dumpfile("waves.vcd");
    $dumpvars(0, tb_top);
  end
`endif

  initial begin
    uvm_config_db #(virtual add_if)::set(null, "*", "vif", intf);
    run_test("add_test");            // +UVM_TESTNAME=<test> picks another test
  end
endmodule
