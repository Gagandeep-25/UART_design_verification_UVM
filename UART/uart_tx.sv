module uart_tx(
  input tx_clk,tx_start,
  input rst,
  input [7:0] tx_data,
  input [3:0] length,
  input parity_type,parity_en,   // 1 - odd and 0 - even
  input stop2,
  output reg tx,tx_done,tx_err
);
  
  logic [7:0] tx_reg;
  
  logic start_b = 0;
  logic stop_b = 1;
  logic parity_bit = 0;
  integer count = 0;
  
  typedef enum bit [2:0] {idle = 0, start_bit = 1, send_data = 2,send_parity = 3, send_first_stop = 4, send_sec_stop = 5, done = 6} state_type;
  state_type state = idle;
  state_type next_state = idle;
  
  always @(posedge tx_clk) begin 
    if(parity_type == 1'b1) //odd
      begin
      /*
        we make use of reduction xor to get the parity , as reduction xor returns 1 if the data has 
        odd number of 1s else returns 0 indicating the type of parity that should be added to the data
      */
        case(length)
          4'd5 : parity_bit = ^(tx_data[4:0]);
          4'd6 : parity_bit = ^(tx_data[5:0]);
          4'd7 : parity_bit = ^(tx_data[6:0]);
          4'd8 : parity_bit = ^(tx_data[7:0]);
          default : parity_bit = 1'b0;
        endcase 
      end
    else 
      begin
        case(length)
          // we make use of reduction xnor as it returns 1 if the data has even number of 1s , indicating the type of parity
          4'd5 : parity_bit = ~^(tx_data[4:0]);
          4'd6 : parity_bit = ~^(tx_data[5:0]);
          4'd7 : parity_bit = ~^(tx_data[6:0]);
          4'd8 : parity_bit = ~^(tx_data[7:0]);
          default : parity_bit = 1'b0;
        endcase
      end
  end
  
  always @(posedge tx_clk) begin
    if(rst)
      state <= idle;
    else 
      state <= next_state;
  end
  
  // next state combinational logic 
  
  always @(*) begin
    case(state)
    
      idle : begin
      
               tx_done = 1'b0;
               tx = 1'b1;
               tx_reg = {(8){1'b0}};
               tx_err = 0;
               if(tx_start)
                 next_state = start_bit;
               else 
                 next_state = idle;
                 
             end
             
///////////////////////////////////////////////
                 
      start_bit : begin
      
                    tx_reg = tx_data;
                    tx = start_b;
                    next_state = send_data;
                    
                  end    
                  
//////////////////////////////////////////////

      send_data : begin
                    if(count < (length - 1))
                      begin
                        next_state = send_data;
                        tx = tx_reg[count];
                      end
                    else if(parity_en)
                      begin
                        tx = tx_reg[count];
                        next_state = send_parity;
                      end
                    else 
                      begin
                        tx = tx_reg[count];
                        next_state = send_first_stop;
                      end
                  end  
                  
///////////////////////////////////////////////

      send_parity : begin
                      tx = parity_bit;
                      next_state = send_first_stop; 
                    end                            
                    
///////////////////////////////////////////////

      send_first_stop : begin
                          tx = stop_b;
                          if(stop2)
                            next_state = send_sec_stop;
                          else 
                            next_state = done;
                        end  
                        
////////////////////////////////////////////////

      send_sec_stop : begin
                        tx = stop_b;
                        next_state = done;
                      end  
                      
//////////////////////////////////////////////////

      done : begin
               tx_done = 1'b1;
               next_state = idle; 
             end                 
             
///////////////////////////////////////////////////

      default : next_state = idle;
                                                                                          
    endcase
    
  end
  
  
always @(posedge tx_clk) begin
  case(state)
    idle : begin 
             count <= 0;
           end
           
    start_bit : begin
                  count <= 0; 
                end
                
    send_data : begin
                  count <= count + 1; 
                end            
                
    send_parity : begin 
                    count <= 0;
                  end          
                  
    send_first_stop : begin
                        count <= 0;
                      end 
                      
    send_sec_stop  : begin
                       count <= 0;
                     end          
                     
    done : begin
             count <= 0; 
           end          
           
    default : count <= 0;
                   
  endcase
    
end

endmodule
