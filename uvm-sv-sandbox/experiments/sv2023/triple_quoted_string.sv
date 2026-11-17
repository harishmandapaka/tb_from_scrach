// SPDX-License-Identifier: Apache-2.0
// IEEE 1800-2023: triple-quoted strings. Quotes and new lines inside """...""" need
// no backslash. The check compares it with the same text written the old way.
module exp_top;
  string a;
  string b;
  initial begin
    a = """say "hi"
bye""";
    b = "say \"hi\"\nbye";
    if (a == b) $display("PASS: triple_quoted_string");
    else        $display("FAIL: triple_quoted_string (got <%s>)", a);
    $finish;
  end
endmodule
