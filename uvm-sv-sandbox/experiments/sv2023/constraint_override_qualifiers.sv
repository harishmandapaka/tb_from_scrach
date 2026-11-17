// SPDX-License-Identifier: Apache-2.0
// IEEE 1800-2023: :initial, :extends and :final also apply to constraints.
// Build with the define SHOW_ERRORS to add an illegal override of a :final constraint.
module exp_top;
  class base_c;
    rand bit [7:0] v;
    constraint c_range { v < 100; }
    constraint :final c_even { v[0] == 1'b0; }
  endclass

  class sub_c extends base_c;
    constraint :extends c_range { v < 10; }    // replaces the base constraint
    constraint :initial c_nonzero { v != 0; }  // new, not an override
  endclass

`ifdef SHOW_ERRORS
  class bad_c extends base_c;
    constraint c_even { v[0] == 1'b1; }        // illegal: c_even is :final
  endclass
`endif

  sub_c s;
  int   ok = 1;
  initial begin
    s = new();
    repeat (20) begin
      if (!s.randomize()) ok = 0;
      else if (!(s.v < 10 && s.v != 0 && s.v[0] == 1'b0)) ok = 0;
    end
    if (ok) $display("PASS: constraint_override_qualifiers (last v=%0d)", s.v);
    else    $display("FAIL: constraint_override_qualifiers (last v=%0d)", s.v);
    $finish;
  end
endmodule
