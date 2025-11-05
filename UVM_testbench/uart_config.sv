`include "uvm_macros.svh"
import uvm_pkg::*;


class uart_config extends uvm_object;
  `uvm_object_utils(uart_config)

  function new(string name = "uart_config");
    super.new(name);
  endfunction

  uvm_active_passive_enum is_active = UVM_ACTIVE; //type of agent

endclass
