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
                      tx_max <= 14'd10417; // 50Mhz / baud
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
