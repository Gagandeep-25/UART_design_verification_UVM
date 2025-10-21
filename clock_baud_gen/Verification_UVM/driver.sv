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
