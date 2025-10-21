class test extends uvm_test;
  `uvm_component_utils(test)
  
  env e;
  variable_baud vbar;
  reset_clk rclk;
  
  function new(input string path = "test", uvm_component parent);
    super.new(path,parent);
  endfunction
  
  
  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    e = env::type_id::create("e",this);
    vbar = variable_baud::type_id::create("vbar");
    rclk = reset_clk::type_id::create("rclk");
  endfunction
  
  virtual task run_phase(uvm_phase phase);
    phase.raise_objection(this);
    vbar.start(e.a.seqr);
    #20;
    phase.drop_objection(this);
  endtask
  
endclass

module tb;

  clk_if vif();
  
  clk_gen dut (.clk(vif.clk),.rst(vif.rst),.baud(vif.baud),.tx_clk(vif.tx_clk));
  
  initial begin
    vif.clk <= 0;
  end
  
  always #10 vif.clk <= ~vif.clk;
  
  initial begin 
    uvm_config_db#(virtual clk_if)::set(null,"*","vif",vif);
    run_test("test");
  end
  
  initial begin 
    $dumpfile("waveform.vcd");
    $dumpvars(0, tb);  // dump all variables in tb and below
  end
  
endmodule
