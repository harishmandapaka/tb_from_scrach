// SPDX-License-Identifier: Apache-2.0
// IEEE 1800-2023: "default" in a constructor's argument list stands for all the
// arguments of the base-class constructor; super.new(default) passes them on.
module exp_top;
  class base_c;
    string tag;
    int    id;
    function new(string tag, int id);
      this.tag = tag;
      this.id  = id;
    endfunction
  endclass

  class sub_c extends base_c;
    int extra;
    function new(default, int extra);
      super.new(default);
      this.extra = extra;
    endfunction
  endclass

  sub_c s;
  initial begin
    s = new("pkt", 3, 9);            // tag and id go to base_c, extra stays here
    if (s.tag == "pkt" && s.id == 3 && s.extra == 9)
      $display("PASS: constructor_default_args");
    else
      $display("FAIL: constructor_default_args");
    $finish;
  end
endmodule
