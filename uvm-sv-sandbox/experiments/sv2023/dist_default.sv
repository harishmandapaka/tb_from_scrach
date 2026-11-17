// SPDX-License-Identifier: Apache-2.0
// IEEE 1800-2023: "default :/ weight" in a dist covers every value not listed.
// Without it, only the listed values would be legal.
module exp_top;
  class pkt_c;
    rand bit [7:0] len;
    // 0 and 255 get weight 1 each; all other values share weight 8.
    constraint c_len { len dist { 0 := 1, 255 := 1, default :/ 8 }; }
  endclass

  pkt_c p;
  int   other = 0;
  int   ok    = 1;
  initial begin
    p = new();
    repeat (200) begin
      if (!p.randomize()) ok = 0;
      else if (p.len != 0 && p.len != 255) other++;
    end
    if (ok && other > 0) $display("PASS: dist_default (%0d of 200 draws were other values)", other);
    else                 $display("FAIL: dist_default (ok=%0d other=%0d)", ok, other);
    $finish;
  end
endmodule
