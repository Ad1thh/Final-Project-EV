`timescale 1ns/1ps

module uart_rx #(
    parameter BAUD_DIVIDER = 271 // Default for 31.25MHz and 115200 baud
)(
    input  logic       clk,
    input  logic       rstn,
    input  logic       rx,
    output logic       valid,
    output logic [7:0] rx_data
);

    typedef enum logic [1:0] {IDLE, START, DATA, STOP} state_t;
    state_t state, next_state;

    logic [15:0] baud_cnt;
    logic [2:0]  bit_cnt;
    logic [7:0]  shift_reg;

    always_ff @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            state <= IDLE;
            baud_cnt <= 0;
            bit_cnt <= 0;
            rx_data <= 8'h0;
            valid <= 1'b0;
        end else begin
            state <= next_state;
            valid <= 1'b0;

            case (state)
                IDLE: begin
                    baud_cnt <= 0;
                    if (rx == 1'b0) begin // Start bit detected
                        baud_cnt <= BAUD_DIVIDER / 2; // sample at middle of bit
                    end
                end
                START: begin
                    if (baud_cnt == 0) begin
                        baud_cnt <= BAUD_DIVIDER;
                        bit_cnt <= 0;
                    end else begin
                        baud_cnt <= baud_cnt - 1;
                    end
                end
                DATA: begin
                    if (baud_cnt == 0) begin
                        baud_cnt <= BAUD_DIVIDER;
                        shift_reg <= {rx, shift_reg[7:1]};
                        bit_cnt <= bit_cnt + 1;
                    end else begin
                        baud_cnt <= baud_cnt - 1;
                    end
                end
                STOP: begin
                    if (baud_cnt == 0) begin
                        rx_data <= shift_reg;
                        valid <= 1'b1;
                        baud_cnt <= 0;
                    end else begin
                        baud_cnt <= baud_cnt - 1;
                    end
                end
            endcase
        end
    end

    always_comb begin
        next_state = state;
        case (state)
            IDLE: begin
                if (rx == 1'b0) next_state = START;
            end
            START: begin
                if (baud_cnt == 0) next_state = DATA;
            end
            DATA: begin
                if (baud_cnt == 0 && bit_cnt == 7) next_state = STOP;
            end
            STOP: begin
                if (baud_cnt == 0) next_state = IDLE;
            end
        endcase
    end
endmodule
