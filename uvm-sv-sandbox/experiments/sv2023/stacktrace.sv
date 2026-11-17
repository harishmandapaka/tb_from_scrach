// SPDX-License-Identifier: Apache-2.0
// IEEE 1800-2023: $stacktrace prints the current call stack. The format is
// tool-specific, so this file only checks that it compiles and runs.
module exp_top;
  task automatic inner();
    $stacktrace;
  endtask

  task automatic outer();
    inner();
  endtask

  initial begin
    outer();
    $display("PASS: stacktrace (check the call stack printed above)");
    $finish;
  end
endmodule
