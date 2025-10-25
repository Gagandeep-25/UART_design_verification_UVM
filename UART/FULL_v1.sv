`timescale 1ns / 1ps

module clk_gen(
  input clk,rst,
  input [16:0] baud,
  output reg tx_clk, rx_clk
);

 /*
   we know that Fclk = 50Mhz and Fout = 9600
   count = Fclk/Fout = 50mega / 9600 = 5208
   thus a clock edge is triggerd at 5208/2 i.e 2604
   hence the total period of a clock is 0 to 2604 + 0 to 2604 i.e = 5209
   for rx clk , we need to sample the data at the middle as we need to operate rx bit faster than tx
   in this case in single tx cycle , we have 16 rx cycles 
 */

  reg t_clk = 0;
  int tx_max = 0, rx_max = 0;
  int tx_count = 0, rx_count = 0;
  //////////////////////////////////////////////
  
  always @(posedge clk) begin
      if(rst) begin
        tx_max <= 0; 
        rx_max <= 0;
      end
      
      else begin
          case(baud)
              4800: begin
                      tx_max <= 14'd10416; // 50Mhz / baud
                      rx_max <= 11'd651;   // 10416 / 16 = 651
                    end
              9600: begin
                      tx_max <= 14'd5208; // 50Mhz / 9600
                      rx_max <= 11'd325;
                    end     
              14400: begin
                       tx_max <= 14'd3472; // 50Mhz / 14400
                       tx_max <= 11'd217;
                     end       
              19200 : begin
                        tx_max <= 14'd2604;
                        rx_max <= 11'd163;
                      end       
              38400: begin
                       tx_max <= 14'd1302;
                       rx_max <= 11'd81;
                     end
              57600: begin
                       tx_max <= 14'd868;
                       rx_max <= 11'd54;
                     end
                     
              default: begin
                         tx_max <= 14'd5208;
                         rx_max <= 11'd325;
                       end
          endcase
      end
  end
 
 //////////////////////////////////////////////////////////////////////// 
  always @(posedge clk) begin
    if(rst)
      begin
        rx_max <= 0;
        rx_count <= 0;
      end
    else
      begin
        if(rx_count <= rx_max)
          begin
            rx_count <= rx_count + 1;
          end
        else 
          begin
            rx_count <= 0;
          end  
      end  
  end
  
  assign rx_clk = (rx_count == rx_max) ? 1'b1 : 1'b0;
  
  ////////////////////////////////////////////////////////////////////////
always @(posedge clk) begin
  if(rst)
    begin
      tx_max = 0;
      tx_count = 0;
    end
  else 
    begin
      if(tx_count <= rx_max)
        begin
          tx_count <= tx_count + 1;
        end
      else begin
        tx_count <= 0;
      end
    end
end 

assign tx_clk = (tx_count == tx_max) ? 1'b1 : 1'b0 ;

endmodule

//////////////////////////////////////////////////////////////////////////////// UART_TX ///////////////////////////////////////////////////////////////////////////


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

/////////////////////////////////////////////////////////////////////////////// UART_RX ///////////////////////////////////////////////////////////////////////

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
