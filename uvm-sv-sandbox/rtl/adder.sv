// SPDX-License-Identifier: Apache-2.0
// Device under test: a registered 8-bit adder.
//   in_valid, a, b  ->  out_valid, sum (9 bits, keeps the carry) one clock later.
// There is no ready signal, so the testbench never waits on the DUT.
// Define INJECT_BUG to build a broken version (it subtracts). The testbench must
// then report errors, which proves the checker really checks.
`timescale 1ns/1ps

module adder (
  input  logic       clk,
  input  logic       rst_n,
  input  logic       in_valid,
  input  logic [7:0] a,
  input  logic [7:0] b,
  output logic       out_valid,
  output logic [8:0] sum
);
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      out_valid <= 1'b0;
      sum       <= '0;
    end else begin
      out_valid <= in_valid;
      if (in_valid) begin
`ifdef INJECT_BUG
        sum <= {1'b0, a} - {1'b0, b};   // deliberate bug
`else
        sum <= {1'b0, a} + {1'b0, b};
`endif
      end
    end
  end
endmodule
