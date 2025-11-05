module clk_gen(
    input  wire clk,
    input  wire rst,
    input  wire [16:0] baud,
    output reg  tx_clk,
    output reg  rx_clk
);

    integer rx_max = 0, tx_max = 0;
    integer rx_count = 0, tx_count = 0;

    // Baud rate control
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            rx_max <= 0;
            tx_max <= 0;
        end else begin
            case (baud)
                4800   : begin rx_max <= 651;  tx_max <= 10416; end
                9600   : begin rx_max <= 325;  tx_max <= 5208;  end
                14400  : begin rx_max <= 217;  tx_max <= 3472;  end
                19200  : begin rx_max <= 163;  tx_max <= 2604;  end
                38400  : begin rx_max <= 81;   tx_max <= 1302;  end
                57600  : begin rx_max <= 54;   tx_max <= 868;   end
                115200 : begin rx_max <= 27;   tx_max <= 434;   end
                128000 : begin rx_max <= 24;   tx_max <= 392;   end
                default: begin rx_max <= 325;  tx_max <= 5208;  end
            endcase
        end
    end

    // RX Clock Generator
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            rx_count <= 0;
            rx_clk <= 0;
        end else if (rx_count >= rx_max) begin
            rx_clk <= ~rx_clk;
            rx_count <= 0;
        end else begin
            rx_count <= rx_count + 1;
        end
    end

    // TX Clock Generator
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            tx_count <= 0;
            tx_clk <= 0;
        end else if (tx_count >= tx_max) begin
            tx_clk <= ~tx_clk;
            tx_count <= 0;
        end else begin
            tx_count <= tx_count + 1;
        end
    end

endmodule


//////////////////////////////////////////////////////
// UART TRANSMITTER
//////////////////////////////////////////////////////
module uart_tx(
    input  wire tx_clk,
    input  wire tx_start,
    input  wire rst,
    input  wire [7:0] tx_data,
    input  wire [3:0] length,
    input  wire parity_type,
    input  wire parity_en,
    input  wire stop2,
    output reg  tx,
    output reg  tx_done,
    output reg  tx_err
);

    reg [7:0] tx_reg;
    reg parity_bit;
    integer count;

    typedef enum logic [2:0] {
        idle = 0, start_bit, send_data, send_parity,
        send_first_stop, send_sec_stop, done
    } state_type;

    state_type state, next_state;

    // Parity generation
    always @(posedge tx_clk) begin
        if (parity_type)
            case (length)
                5: parity_bit <= ^tx_data[4:0];
                6: parity_bit <= ^tx_data[5:0];
                7: parity_bit <= ^tx_data[6:0];
                8: parity_bit <= ^tx_data[7:0];
                default: parity_bit <= 0;
            endcase
        else
            case (length)
                5: parity_bit <= ~^tx_data[4:0];
                6: parity_bit <= ~^tx_data[5:0];
                7: parity_bit <= ~^tx_data[6:0];
                8: parity_bit <= ~^tx_data[7:0];
                default: parity_bit <= 0;
            endcase
    end

    // State register
    always @(posedge tx_clk or posedge rst) begin
        if (rst) state <= idle;
        else state <= next_state;
    end

    // Next-state and output logic
    always @(*) begin
        next_state = state;
        tx_done = 0;
        tx_err = 0;
        tx = 1'b1;

        case (state)
            idle: begin
                if (tx_start) next_state = start_bit;
            end

            start_bit: begin
                tx = 0;
                next_state = send_data;
            end

            send_data: begin
                tx = tx_reg[count];
                if (count < length - 1)
                    next_state = send_data;
                else if (parity_en)
                    next_state = send_parity;
                else
                    next_state = send_first_stop;
            end

            send_parity: begin
                tx = parity_bit;
                next_state = send_first_stop;
            end

            send_first_stop: begin
                tx = 1;
                if (stop2) next_state = send_sec_stop;
                else next_state = done;
            end

            send_sec_stop: begin
                tx = 1;
                next_state = done;
            end

            done: begin
                tx_done = 1;
                next_state = idle;
            end
        endcase
    end

    // Counters
    always @(posedge tx_clk or posedge rst) begin
        if (rst) begin
            count <= 0;
            tx_reg <= 0;
        end else begin
            case (state)
                idle: begin
                    count <= 0;
                    tx_reg <= tx_data;
                end
                send_data: count <= count + 1;
                default: count <= 0;
            endcase
        end
    end

endmodule


//////////////////////////////////////////////////////
// UART RECEIVER (FIXED)
//////////////////////////////////////////////////////
module uart_rx(
    input  wire rx_clk,
    input  wire rx_start,
    input  wire rst,
    input  wire rx,
    input  wire [3:0] length,
    input  wire parity_type,
    input  wire parity_en,
    input  wire stop2,
    output reg  [7:0] rx_out,
    output reg  rx_done,
    output reg  rx_err
);

    reg parity;
    reg [7:0] datard;
    integer count, bit_count;

    typedef enum logic [2:0] {
        idle = 0, start_bit, recv_data, check_parity,
        check_first_stop, check_sec_stop, done
    } state_type;

    state_type state, next_state;

    // State register
    always @(posedge rx_clk or posedge rst) begin
        if (rst)
            state <= idle;
        else
            state <= next_state;
    end

    // Sequential datapath
    always @(posedge rx_clk or posedge rst) begin
        if (rst) begin
            count <= 0;
            bit_count <= 0;
            datard <= 0;
            rx_out <= 0;
            rx_done <= 0;
            rx_err <= 0;
        end else begin
            rx_done <= 0;

            case (state)
                idle: begin
                    count <= 0;
                    bit_count <= 0;
                end

                start_bit: begin
                    if (count < 15)
                        count <= count + 1;
                    else
                        count <= 0;
                end

                recv_data: begin
                    if (count == 7)
                        datard <= {rx, datard[7:1]};
                    if (count < 15)
                        count <= count + 1;
                    else begin
                        count <= 0;
                        bit_count <= bit_count + 1;
                        if (bit_count == length - 1) begin
                            case (length)
                                5: rx_out <= datard[7:3];
                                6: rx_out <= datard[7:2];
                                7: rx_out <= datard[7:1];
                                8: rx_out <= datard[7:0];
                                default: rx_out <= 8'h00;
                            endcase
                        end
                    end
                end

                check_parity: begin
                    if (count < 15)
                        count <= count + 1;
                    else
                        count <= 0;

                    if (count == 7) begin
                        if (parity_type)
                            parity <= ^datard;
                        else
                            parity <= ~^datard;

                        if (rx != parity)
                            rx_err <= 1;
                        else
                            rx_err <= 0;
                    end
                end

                check_first_stop: begin
                    if (count < 15)
                        count <= count + 1;
                    else
                        count <= 0;
                    if (count == 7 && rx != 1)
                        rx_err <= 1;
                end

                check_sec_stop: begin
                    if (count < 15)
                        count <= count + 1;
                    else
                        count <= 0;
                    if (count == 7 && rx != 1)
                        rx_err <= 1;
                end

                done: begin
                    rx_done <= 1;
                    count <= 0;
                    bit_count <= 0;
                end
            endcase
        end
    end

    // Next-state logic
    always @(*) begin
        next_state = state;
        case (state)
            idle: if (rx_start && !rx) next_state = start_bit;
            start_bit: if (count == 15) next_state = recv_data;
            recv_data: if (count == 15 && bit_count == (length - 1))
                next_state = (parity_en ? check_parity : check_first_stop);
            check_parity: if (count == 15) next_state = check_first_stop;
            check_first_stop: if (count == 15)
                next_state = (stop2 ? check_sec_stop : done);
            check_sec_stop: if (count == 15) next_state = done;
            done: next_state = idle;
        endcase
    end

endmodule

`timescale 1ns / 1ps

//////////////////////////////////////////////////////
// UART TOP
//////////////////////////////////////////////////////

module uart_top(
    input  wire clk,
    input  wire rst,
    input  wire tx_start,
    input  wire rx_start,
    input  wire [7:0] tx_data,
    input  wire [16:0] baud,
    input  wire [3:0] length,
    input  wire parity_type,
    input  wire parity_en,
    input  wire stop2,
    output wire tx_done,
    output wire rx_done,
    output wire tx_err,
    output wire rx_err,
    output wire [7:0] rx_out
);

    // Internal signals
    wire tx;
    wire rx;
    wire tx_clk, rx_clk;

    assign rx = tx; // internal loopback

    clk_gen u_clk_gen(
        .clk(clk),
        .rst(rst),
        .baud(baud),
        .tx_clk(tx_clk),
        .rx_clk(rx_clk)
    );

    uart_tx u_tx(
        .tx_clk(tx_clk),
        .tx_start(tx_start),
        .rst(rst),
        .tx_data(tx_data),
        .length(length),
        .parity_type(parity_type),
        .parity_en(parity_en),
        .stop2(stop2),
        .tx(tx),
        .tx_done(tx_done),
        .tx_err(tx_err)
    );

    uart_rx u_rx(
        .rx_clk(rx_clk),
        .rx_start(rx_start),
        .rst(rst),
        .rx(rx),
        .length(length),
        .parity_type(parity_type),
        .parity_en(parity_en),
        .stop2(stop2),
        .rx_out(rx_out),
        .rx_done(rx_done),
        .rx_err(rx_err)
    );

endmodule


//////////////////////////////////////////////////////
// UART INTERFACE
//////////////////////////////////////////////////////
interface uart_if;
    logic clk, rst;
    logic tx_start, rx_start;
    logic [7:0] tx_data;
    logic [16:0] baud;
    logic [3:0] length;
    logic parity_type, parity_en;
    logic stop2;
    logic tx_done, rx_done, tx_err, rx_err;
    logic [7:0] rx_out;
endinterface

