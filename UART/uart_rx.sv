module uart_rx(
  input rx_clk,rx_start,
  input rst,rx,
  input [3:0] length,
  input parity_type,parity_en,
  input stop2,
  output reg [7:0] rx_out,
  output logic rx_done, rx_error
);

logic parity = 0;
logic [7:0] datard = 0;
int count = 0;
int bit_count = 0;

typedef enum bit [2:0] {idle = 0, start_bit = 1, recv_data = 2, check_parity = 3, check_first_stop = 4, check_sec_stop = 5, done = 6} state_type;

state_type state = idle;
state_type next_state = idle;

always @(posedge rx_clk) begin
  if(rst)
    state <= idle;
  else 
    state <= next_state; 
end

// next state combinational logic 

always @(*) begin
  case(state)
    idle : begin
             rx_done = 0;
             rx_error = 0;
             if(rx_start && !rx)
               next_state = start_bit;
             else
               next_state = idle;
           end
    
////////////////////////////////////////////////////
    
    start_bit : begin
                  if(count == 7 && rx) // exactly at the middle of the start bit 
                    begin
                      next_state = idle; // indicates error in reception hence we jump pack to idle
                    end 
                  else if(count == 15) // makes sure RX stays low for entire 15~16 cycles
                    begin
                      next_state = recv_data; 
                    end
                  else 
                    begin
                      next_state = start_bit; 
                    end
                end  
                
////////////////////////////////////////////////////

    recv_data : begin
                  if(count == 7)  // samples rx at the middle of the clock 
                    begin
                      datard[7:0] = {rx,datard[7:1]}; // append rx on MSB side and the other 7 are shifted right 
                    end 
                  else if(count == 15 && bit_count == (length - 1)) // indicates we have reached the end od data bit abd when the bit count is len -1 , that means we have recieved all bits in data  
                    begin 
                       // rx_out is the output data 
                       
                       case(length) // makes sure the LSB does not have garbage data
                         5 : rx_out = datard[7:3];
                         6 : rx_out = datard[7:2];
                         7 : rx_out = datard[7:1];
                         8 : rx_out = datard[7:0];
                         default : rx_out = 8'h00;
                       endcase
                       
                       if(parity_type)  // determines the value of parity 
                         parity = ^datard; // reduction xor i.e datard in odd 
                       else 
                         parity = ~^datard; // reduction xnor i.e. datard is even
                         
                         
                       if(parity_en)
                         next_state = check_parity;
                       else 
                         next_state = check_first_stop;
                    end
                    
                  else
                    next_state = recv_data;
                end         
                
///////////////////////////////////////////////////////////

    check_parity : begin 
                     if(count == 7)
                       begin
                         if(rx == parity)
                           rx_error = 1'b0;
                         else 
                           rx_error = 1'b1; 
                       end
                     else if(count == 15)
                       begin
                          next_state = check_first_stop;
                       end
                     else
                       begin
                         next_state = check_parity;
                       end
                   end                    
                   
/////////////////////////////////////////////////////////////

    check_first_stop : begin
                         if(count == 7)
                           begin
                             if(rx != 1'b1)
                               rx_error = 1'b1;
                             else 
                               rx_error = 1'b0; 
                           end
                         else if(count == 15)
                           begin
                             if(stop2)
                               next_state = check_sec_stop;
                             else 
                               next_state = done;
                           end
                       end      
                       
/////////////////////////////////////////////////////////////

    check_sec_stop : begin
                       if(count == 7)
                         begin
                           if(rx != 1'b1)
                             rx_error = 1'b1;
                           else 
                             rx_error = 1'b0; 
                         end
                       else if(count == 15)
                         begin
                           next_state = done; 
                         end
                     end  
                     
///////////////////////////////////////////////////////////////

    done : begin
             rx_done = 1'b1;
             next_state = idle;
             rx_error = 1'b0; 
           end      
  endcase 
end 

// sequential block to incrememnt count and bit count 

always @(posedge rx_clk) begin
  case(state)
    idle : begin
             count <= 0;
             bit_count <= 0; 
           end
           
/////////////////////////////////////////////////////////////////

    start_bit : begin
                  if(count < 15)
                    count <= count + 1;
                  else 
                    count <= 0; 
                end   
                
/////////////////////////////////////////////////////////////////

    recv_data : begin
                  if(count < 15)
                    count <= count + 1;
                  else begin
                    count <= 0;
                    bit_count <= bit_count + 1; // assuring we have reached a bit successfully 
                  end  // continues until len - 1
                end 
                
/////////////////////////////////////////////////////////////////

    check_parity : begin
                     if(count < 15)
                       count <= count + 1;
                     else 
                       count <= 0; 
                   end  
                   
//////////////////////////////////////////////////////////////////

    check_first_stop : begin
                         if(count < 15)
                           count <= count + 1;
                         else 
                           count <= 0;
                       end   
                       
//////////////////////////////////////////////////////////////////

    check_sec_stop : begin
                       if(count < 15)
                         count <= count + 1;
                       else 
                         count <= 0; 
                     end
                     
//////////////////////////////////////////////////////////////////
    done : begin
             count <= 0;
             bit_count <= 0;
           end
  endcase 
end

endmodule
