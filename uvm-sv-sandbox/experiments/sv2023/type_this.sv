// SPDX-License-Identifier: Apache-2.0
// IEEE 1800-2023: type(this) is the type of the enclosing class, so a parameterized
// class does not have to spell out its own name and parameters.
module exp_top;
  class registry #(type T = int);
    static type(this) m_inst;
    T value;
    static function type(this) get();
      if (m_inst == null) m_inst = new();
      return m_inst;
    endfunction
  endclass

  registry #(int) r1;
  registry #(int) r2;
  initial begin
    r1 = registry #(int)::get();
    r2 = registry #(int)::get();
    if (r1 != null && r1 == r2) $display("PASS: type_this");
    else                        $display("FAIL: type_this");
    $finish;
  end
endmodule
