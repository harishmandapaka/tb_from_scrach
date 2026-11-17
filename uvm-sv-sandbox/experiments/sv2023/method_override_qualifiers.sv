// SPDX-License-Identifier: Apache-2.0
// IEEE 1800-2023: method qualifiers that catch override mistakes at compile time.
//   :initial  this method must NOT override a base-class method
//   :extends  this method MUST override a virtual base-class method
//   :final    no class below may override this method again
// Build with the define SHOW_ERRORS to add an illegal override.
module exp_top;
  class base_c;
    virtual function :initial string name();
      return "base";
    endfunction
  endclass

  class mid_c extends base_c;
    virtual function :extends string name();
      return "mid";
    endfunction
  endclass

  class leaf_c extends mid_c;
    virtual function :extends :final string name();
      return "leaf";
    endfunction
  endclass

`ifdef SHOW_ERRORS
  class bad_c extends leaf_c;
    virtual function string name();  // illegal: name() is :final in leaf_c
      return "bad";
    endfunction
  endclass
`endif

  base_c b;
  leaf_c l;
  initial begin
    l = new();
    b = l;
    if (b.name() == "leaf") $display("PASS: method_override_qualifiers");
    else                    $display("FAIL: method_override_qualifiers (got %s)", b.name());
    $finish;
  end
endmodule
