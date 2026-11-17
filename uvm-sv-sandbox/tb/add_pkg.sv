// SPDX-License-Identifier: Apache-2.0
// UVM classes for the adder testbench. Written from scratch against the public
// IEEE 1800.2 (UVM) standard. Uses only calls that exist in both UVM 1.2 and
// IEEE 1800.2, so it works with every UVM library the free simulators offer.
`timescale 1ns/1ps

package add_pkg;
  import uvm_pkg::*;
  `include "uvm_macros.svh"

  // -------------------------------------------------------------------------
  // Transaction: one addition
  // -------------------------------------------------------------------------
  class add_item extends uvm_sequence_item;
    `uvm_object_utils(add_item)
    rand bit [7:0] a;
    rand bit [7:0] b;
    bit      [8:0] sum;   // filled in by the monitor

    function new(string name = "add_item");
      super.new(name);
    endfunction

    function string convert2string();
      return $sformatf("a=%0d b=%0d sum=%0d", a, b, sum);
    endfunction
  endclass

  // -------------------------------------------------------------------------
  // Sequences
  // -------------------------------------------------------------------------
  // add_seq: n fully random additions.
  class add_seq extends uvm_sequence #(add_item);
    `uvm_object_utils(add_seq)
    int unsigned n = 20;

    function new(string name = "add_seq");
      super.new(name);
    endfunction

    // How each item is randomized. Child sequences override only this.
    virtual function bit pick(add_item it);
      return it.randomize();
    endfunction

    task body();
      repeat (n) begin
        req = add_item::type_id::create("req");
        start_item(req);
        if (!pick(req)) `uvm_error("SEQ", "randomize() failed")
        finish_item(req);
      end
    endtask
  endclass

  // add_corner_seq: edge values only (0, 1, 127/128, 255) on each input.
  class add_corner_seq extends add_seq;
    `uvm_object_utils(add_corner_seq)

    function new(string name = "add_corner_seq");
      super.new(name);
    endfunction

    virtual function bit pick(add_item it);
      return it.randomize() with { a inside {8'd0, 8'd1, 8'd127, 8'd255};
                                  b inside {8'd0, 8'd1, 8'd128, 8'd255}; };
    endfunction
  endclass

  // -------------------------------------------------------------------------
  // Sequencer, driver, monitor, agent
  // -------------------------------------------------------------------------
  class add_sequencer extends uvm_sequencer #(add_item);
    `uvm_component_utils(add_sequencer)

    function new(string name, uvm_component parent);
      super.new(name, parent);
    endfunction
  endclass

  // Driver: one item = one clock with in_valid high, then one idle clock.
  class add_driver extends uvm_driver #(add_item);
    `uvm_component_utils(add_driver)
    virtual add_if vif;

    function new(string name, uvm_component parent);
      super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
      super.build_phase(phase);
      if (!uvm_config_db #(virtual add_if)::get(this, "", "vif", vif))
        `uvm_fatal("NOVIF", "virtual interface 'vif' was not set")
    endfunction

    task run_phase(uvm_phase phase);
      vif.in_valid <= 1'b0;
      wait (vif.rst_n === 1'b1);
      forever begin
        seq_item_port.get_next_item(req);
        `uvm_info("DRV", {"driving ", req.convert2string()}, UVM_HIGH)
        @(posedge vif.clk);
        vif.in_valid <= 1'b1;
        vif.a        <= req.a;
        vif.b        <= req.b;
        @(posedge vif.clk);
        vif.in_valid <= 1'b0;
        seq_item_port.item_done();
      end
    endtask
  endclass

  // Monitor: samples the pins every clock and publishes what it sees.
  class add_monitor extends uvm_monitor;
    `uvm_component_utils(add_monitor)
    virtual add_if vif;
    uvm_analysis_port #(add_item) in_ap;    // inputs the DUT accepted
    uvm_analysis_port #(add_item) out_ap;   // results the DUT produced

    function new(string name, uvm_component parent);
      super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
      super.build_phase(phase);
      in_ap  = new("in_ap", this);
      out_ap = new("out_ap", this);
      if (!uvm_config_db #(virtual add_if)::get(this, "", "vif", vif))
        `uvm_fatal("NOVIF", "virtual interface 'vif' was not set")
    endfunction

    task run_phase(uvm_phase phase);
      add_item t;
      forever begin
        @(posedge vif.clk);
        if (vif.rst_n !== 1'b1) continue;
        if (vif.in_valid === 1'b1) begin
          t = add_item::type_id::create("in");
          t.a = vif.a;
          t.b = vif.b;
          in_ap.write(t);
        end
        if (vif.out_valid === 1'b1) begin
          t = add_item::type_id::create("out");
          t.sum = vif.sum;
          out_ap.write(t);
        end
      end
    endtask
  endclass

  class add_agent extends uvm_agent;
    `uvm_component_utils(add_agent)
    add_sequencer sqr;
    add_driver    drv;
    add_monitor   mon;

    function new(string name, uvm_component parent);
      super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
      super.build_phase(phase);
      sqr = add_sequencer::type_id::create("sqr", this);
      drv = add_driver::type_id::create("drv", this);
      mon = add_monitor::type_id::create("mon", this);
    endfunction

    function void connect_phase(uvm_phase phase);
      drv.seq_item_port.connect(sqr.seq_item_export);
    endfunction
  endclass

  // -------------------------------------------------------------------------
  // Scoreboard: reference model + in-order compare
  // -------------------------------------------------------------------------
  `uvm_analysis_imp_decl(_in)
  `uvm_analysis_imp_decl(_out)

  class add_scoreboard extends uvm_scoreboard;
    `uvm_component_utils(add_scoreboard)
    uvm_analysis_imp_in  #(add_item, add_scoreboard) in_imp;
    uvm_analysis_imp_out #(add_item, add_scoreboard) out_imp;
    bit [8:0]    pending_q[$];   // results still expected, oldest first
    int unsigned n_pass;
    int unsigned n_fail;

    function new(string name, uvm_component parent);
      super.new(name, parent);
      in_imp  = new("in_imp", this);
      out_imp = new("out_imp", this);
    endfunction

    // Reference model: the result the DUT must produce for each accepted input.
    function void write_in(add_item t);
      pending_q.push_back({1'b0, t.a} + {1'b0, t.b});
    endfunction

    function void write_out(add_item t);
      bit [8:0] exp_sum;
      if (pending_q.size() == 0) begin
        `uvm_error("SB", $sformatf("DUT produced sum=%0d with no input pending", t.sum))
        return;
      end
      exp_sum = pending_q.pop_front();
      if (t.sum === exp_sum) begin
        n_pass++;
      end else begin
        n_fail++;
        `uvm_error("SB", $sformatf("mismatch: expected %0d, got %0d", exp_sum, t.sum))
      end
    endfunction

    function void check_phase(uvm_phase phase);
      if (n_pass + n_fail == 0)
        `uvm_error("SB", "no results were checked")
      if (pending_q.size() != 0)
        `uvm_error("SB", $sformatf("%0d expected results never came out", pending_q.size()))
    endfunction

    function void report_phase(uvm_phase phase);
      `uvm_info("SB", $sformatf("passed=%0d failed=%0d", n_pass, n_fail), UVM_NONE)
    endfunction
  endclass

  // -------------------------------------------------------------------------
  // Environment and tests
  // -------------------------------------------------------------------------
  class add_env extends uvm_env;
    `uvm_component_utils(add_env)
    add_agent      agt;
    add_scoreboard sb;

    function new(string name, uvm_component parent);
      super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
      super.build_phase(phase);
      agt = add_agent::type_id::create("agt", this);
      sb  = add_scoreboard::type_id::create("sb", this);
    endfunction

    function void connect_phase(uvm_phase phase);
      agt.mon.in_ap.connect(sb.in_imp);
      agt.mon.out_ap.connect(sb.out_imp);
    endfunction
  endclass

  // add_test: 20 random additions. Prints TEST PASSED / TEST FAILED at the end.
  class add_test extends uvm_test;
    `uvm_component_utils(add_test)
    add_env env;

    function new(string name, uvm_component parent);
      super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
      super.build_phase(phase);
      env = add_env::type_id::create("env", this);
    endfunction

    task run_phase(uvm_phase phase);
      add_seq seq;
      phase.raise_objection(this);
      `uvm_info("TEST", $sformatf("running %s", get_type_name()), UVM_NONE)
      seq = add_seq::type_id::create("seq");   // a factory override can swap this
      seq.start(env.agt.sqr);
      #50ns;                                   // let the last result come out
      phase.drop_objection(this);
    endtask

    function void report_phase(uvm_phase phase);
      uvm_report_server rs = uvm_report_server::get_server();
      if (rs.get_severity_count(UVM_ERROR) + rs.get_severity_count(UVM_FATAL) == 0)
        `uvm_info("TEST", "*** TEST PASSED ***", UVM_NONE)
      else
        `uvm_info("TEST", "*** TEST FAILED ***", UVM_NONE)
    endfunction
  endclass

  // add_corner_test: same flow, but the factory swaps in add_corner_seq.
  class add_corner_test extends add_test;
    `uvm_component_utils(add_corner_test)

    function new(string name, uvm_component parent);
      super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
      add_seq::type_id::set_type_override(add_corner_seq::get_type());
      super.build_phase(phase);
    endfunction
  endclass

endpackage
