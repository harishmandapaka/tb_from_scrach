// SPDX-License-Identifier: Apache-2.0
// Interface: the only path between the UVM classes and the DUT pins.
`timescale 1ns/1ps

interface add_if (input logic clk);
  logic       rst_n;
  logic       in_valid;
  logic [7:0] a;
  logic [7:0] b;
  logic       out_valid;
  logic [8:0] sum;
endinterface
