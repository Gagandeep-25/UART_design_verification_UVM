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
