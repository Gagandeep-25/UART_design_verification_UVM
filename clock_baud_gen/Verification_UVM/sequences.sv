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
