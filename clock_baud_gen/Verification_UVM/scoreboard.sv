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
