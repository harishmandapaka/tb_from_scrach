// SPDX-License-Identifier: Apache-2.0
// IEEE 1800-2023: the map() array method builds a new array from an old one.
module exp_top;
  int src[] = '{1, 2, 3};
  int plus1[];
  int times10[];
  initial begin
    plus1   = src.map(x) with (x + 1);       // named iterator
    times10 = src.map() with (item * 10);    // default iterator name: item
    if (plus1.size() == 3 && plus1[0] == 2 && plus1[1] == 3 && plus1[2] == 4 &&
        times10.size() == 3 && times10[0] == 10 && times10[2] == 30)
      $display("PASS: array_map");
    else
      $display("FAIL: array_map");
    $finish;
  end
endmodule
