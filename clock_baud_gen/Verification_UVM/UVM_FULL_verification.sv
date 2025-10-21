/////////////////////////////////////////////////////////////////////// DUT + INTERFACE //////////////////////////////////////////////////////////////////////////

module clk_gen(
  input clk,rst,
  input [16:0] baud,
  output tx_clk
);

 /*
   we know that Fclk = 50Mhz and Fout = 9600
   count = Fclk/Fout = 50mega / 9600 = 5208
   thus a clock edge is triggerd at 5208/2 i.e 2604
   hence the total period of a clock is 0 to 2604 + 0 to 2604 i.e = 5209
 */

  reg t_clk = 0;
  int tx_max = 0;
  int tx_count = 0;
  //////////////////////////////////////////////
  
  always @(posedge clk) begin
      if(rst) begin
        tx_max = 0; 
      end
      
      else begin
          case(baud)
              4800: begin
                      tx_max <= 14'd10416; // 50Mhz / baud
                    end
              9600: begin
                      tx_max <= 14'd5208; // 50Mhz / 9600
                    end     
              14400: begin
                       tx_max <= 14'd3472; // 50Mhz / 14400
                     end       
              19200 : begin
                        tx_max <= 14'd2604;
                      end       
              38400: begin
                       tx_max <= 14'd1302;
                     end
              57600: begin
                       tx_max <= 14'd868;
                     end
                     
              default: begin
                         tx_max <= 14'd5208;
                       end
          endcase
      end
  end
  
  always @(posedge clk) begin
    if(rst) begin
      tx_count <= 0;
      t_clk <= 0;
    end
    else begin
      if(tx_count < tx_max / 2)
        begin
          tx_count <= tx_count + 1; 
        end
      else 
        begin
          t_clk <= ~t_clk; // invert the clk when value reached
          tx_count <= 0;
        end
    end
  end
  
  assign tx_clk = t_clk;
  
endmodule

interface clk_if;

  logic clk;
  logic rst;
  logic [16:0] baud;
  logic tx_clk;
  
endinterface

//////////////////////////////////////////////////////////////////////// TEST BENCH ENVIRONMENT ////////////////////////////////////////////////////////////////////

`include "uvm_macros.svh"
import uvm_pkg::*;

typedef enum bit [1:0] {reset_asserted = 0, random_baud = 1} oper_mode;

class transaction extends uvm_sequence_item;
`uvm_object_utils(transaction)

    oper_mode oper;
    rand logic [16:0] baud;
    logic tx_clk;
    real period;
    
    constraint baud_c {
        baud inside {4800,9600,14400,19200,38400,57600};
    }
    
    function new(input string path = "transaction");
      super.new(path);
    endfunction
    
endclass

class reset_clk extends uvm_sequence#(transaction);
  `uvm_object_utils(reset_clk)
  
  transaction tr;
  
  function new(input string path = "reset_clk");
    super.new(path);
  endfunction
  
  virtual task body();
    repeat(5)
      begin
        tr = transaction::type_id::create("tr");
        start_item(tr);
        assert(tr.randomize());
        tr.oper = reset_asserted;
        finish_item(tr);
      end
  endtask
  
endclass

class variable_baud extends uvm_sequence#(transaction);
  `uvm_object_utils(variable_baud)
  
  transaction tr;
  
  function new(input string path = "variable_baud");
    super.new(path);
  endfunction
  
  virtual task body();
    repeat(5) begin
      tr = transaction::type_id::create("tr");
      start_item(tr);
      assert(tr.randomize());
      tr.oper = random_baud;
      finish_item(tr);
    end
  endtask
  
endclass

class driver extends uvm_driver#(transaction);
  `uvm_component_utils(driver)
  
  virtual clk_if vif;
  transaction tr;
  
  function new(input string path = "driver", uvm_component parent = null);
    super.new(path,parent);
  endfunction
  
  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    tr = transaction::type_id::create("tr");
    
    if(!uvm_config_db#(virtual clk_if)::get(this,"","vif",vif))
      `uvm_error("drv","unable to access Interface");
  endfunction
  
  virtual task run_phase(uvm_phase phase);
    forever begin
      seq_item_port.get_next_item(tr);
      
      if(tr.oper == reset_asserted)
      begin
        vif.rst <= 1'b1;
        @(posedge vif.clk);
      end
      else if(tr.oper == random_baud)
        begin
          `uvm_info("drv",$sformatf("Baud : %0d",tr.baud),UVM_NONE); 
          vif.rst <= 1'b0;
          vif.baud <= tr.baud;
          @(posedge vif.clk); //make dealy equal (faster clk)
          @(posedge vif.tx_clk);//slower clk
          @(posedge vif.tx_clk);
        end
        
      seq_item_port.item_done();
    end
  endtask
  
endclass

class mon extends uvm_monitor;
  `uvm_component_utils(mon)
  
  uvm_analysis_port#(transaction) send;
  transaction tr;
  virtual clk_if vif;
  
  real ton = 0;
  real toff = 0;
  
  function new(input string path = "mon", uvm_component parent = null);
    super.new(path,parent);
  endfunction
  
  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    send = new("send",this);
    tr = transaction::type_id::create("tr");
    
    if(!uvm_config_db#(virtual clk_if)::get(this,"","vif",vif))
      `uvm_error("mon","Unable to Access Interface");
  endfunction
  
  virtual task run_phase(uvm_phase phase);
    forever begin
      @(posedge vif.clk);
      if(vif.rst) begin
        tr.oper = reset_asserted;
        ton = 0;
        toff = 0;
        `uvm_info("MON","SYSTEM RESET DETECTED",UVM_NONE);
        send.write(tr);
      end
      else 
        begin
        
          tr.baud = vif.baud;
          tr.oper = random_baud;
          ton = 0;
          toff = 0;
          @(posedge vif.tx_clk); //wait for the first posedge 
          ton = $realtime;  //sample surrent simulation time 
          @(posedge vif.tx_clk);  // wait for second posedge 
          toff = $realtime;
          tr.period = toff - ton;
          
          `uvm_info("MON",$sformatf(""),UVM_NONE);
          send.write(tr);
        end
    end
  endtask
  
endclass

class sco extends uvm_scoreboard; // build the actual verification algorithm 
  `uvm_component_utils(sco)
  /*
  we know that each clk tick has a period of 20ns, hence dividing the period
  by 20ns , we get the count. this is simply the reverse logic that we applied in the 
  clock generator module
  
  Freq = 1/time and therefore baud = 1/time
  
  we need to add two extra count to include the transition during the comparision
  if working on a half clock cycle then we can just add 1 to include 1 transition from high to low
  
  */

  real count = 0;
  real baudcount = 0;
  uvm_analysis_imp#(transaction,sco) recv;
  
    
  function new(input string path = "sco", uvm_component parent = null);
    super.new(path,parent);
  endfunction
  
  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    recv = new("recv",this);
  endfunction
  
  virtual function void write(transaction tr);
    count = tr.period / 20;
    baudcount = count;
    
    `uvm_info("sco",$sformatf("BAUD : %0d , count : %0f , baud_count : %0f",tr.baud,count,baudcount),UVM_NONE);
    
    case(tr.baud)
      
      4800 : begin
               if(baudcount == 10418) //10416 + 2 <- includes the transition
                 `uvm_info("sco","TEST PASSED",UVM_NONE)
               else
                 `uvm_error("sco","TEST FAILED")
             end
             
      9600 : begin
               if(baudcount == 5210)
                 `uvm_info("sco","TEST PASSED",UVM_NONE)
               else 
                 `uvm_error("sco","TEST FAILED")
             end
              
       14400 : begin
                 if(baudcount == 3474)
                   `uvm_info("sco","TEST PASSED",UVM_NONE)
                 else 
                   `uvm_error("sco","TEST FAILED")
               end
               
        19200 : begin
                  if(baudcount == 2606)
                    `uvm_info("sco","TEST PASSED",UVM_NONE)
                  else
                    `uvm_error("sco","TEST FAILED")
                end             
                
        38400 : begin
                  if(baudcount == 1304)
                    `uvm_info("sco","TEST PASSED",UVM_NONE)
                  else 
                    `uvm_error("sco","TEST FAILED") 
                end      
                
        57600 : begin
                  if(baudcount == 870)
                    `uvm_info("sco","TEST PASSED",UVM_NONE)
                  else 
                    `uvm_error("sco","TEST FAILED")
                end       
               
    endcase
  endfunction
  
endclass

class agent extends uvm_agent;
  `uvm_component_utils(agent)
  
  function new(input string path = "agent", uvm_component parent = null);
    super.new(path,parent);
  endfunction
  
  driver d;
  mon m;
  uvm_sequencer#(transaction) seqr;
  
  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    d = driver::type_id::create("d",this);
    m = mon::type_id::create("m",this);
    seqr = uvm_sequencer#(transaction)::type_id::create("seqr",this);
  endfunction
  
  virtual function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    d.seq_item_port.connect(seqr.seq_item_export);
  endfunction
  
endclass

class env extends uvm_env;
  `uvm_component_utils(env)
  
  function new(input string path = "env", uvm_component parent = null);
    super.new(path,parent);
  endfunction
  
  agent a;
  sco s;
  
  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    a = agent::type_id::create("a",this);
    s = sco::type_id::create("s",this);
  endfunction
  
  virtual function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    a.m.send.connect(s.recv);
  endfunction 
  
endclass

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
