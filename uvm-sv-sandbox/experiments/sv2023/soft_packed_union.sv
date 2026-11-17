// SPDX-License-Identifier: Apache-2.0
// IEEE 1800-2023: "union soft" lets packed members have different widths.
// Members are right-aligned; writing a short member leaves the upper bits alone.
module exp_top;
  typedef union soft {
    logic [15:0] m_word;
    logic [7:0]  m_byte;
  } word_u;

  word_u w;
  initial begin
    w = 16'hABCD;
    w.m_byte = 8'h56;                // only the low 8 bits change
    if (w.m_word == 16'hAB56) $display("PASS: soft_packed_union");
    else                      $display("FAIL: soft_packed_union (m_word=%h)", w.m_word);
    $finish;
  end
endmodule
