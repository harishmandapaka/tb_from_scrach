// SPDX-License-Identifier: Apache-2.0
// IEEE 1800-2023: variables of type real can be random.
module exp_top;
  class pkt_c;
    rand real gain;
    constraint c_gain { gain > 0.5; gain < 2.0; }
  endclass

  pkt_c p;
  int   ok = 1;
  initial begin
    p = new();
    repeat (20) begin
      if (!p.randomize()) ok = 0;
      else if (!(p.gain > 0.5 && p.gain < 2.0)) ok = 0;
    end
    if (ok) $display("PASS: rand_real (last gain=%f)", p.gain);
    else    $display("FAIL: rand_real (last gain=%f)", p.gain);
    $finish;
  end
endmodule
