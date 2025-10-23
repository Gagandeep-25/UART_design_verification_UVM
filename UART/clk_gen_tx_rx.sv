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
