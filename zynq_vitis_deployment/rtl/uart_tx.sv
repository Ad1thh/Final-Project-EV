`timescale 1ns / 1ps

module uart_tx #(
    parameter int BAUD_DIVIDER = 217, // 25MHz / 115200 baud
    parameter string PARITY = "NONE"  // "NONE", "EVEN", "ODD"
)(
    input  logic       clk,
    input  logic       rstn,
    
    // Handshake interface from CPU
    input  logic       valid,
    output logic       ready,
    input  logic [7:0] tx_data,
    
    // UART TX pin
    output logic       tx
);

    typedef enum logic [2:0] {
        ST_IDLE,
        ST_START,
        ST_DATA,
        ST_PARITY,
        ST_STOP
    } state_t;

    state_t state, next_state;

    // Counters
    logic [15:0] clk_count, next_clk_count;
    logic [2:0]  bit_count, next_bit_count;

    // Registers
    logic [7:0] shift_reg, next_shift_reg;
    logic       parity_bit, next_parity_bit;
    
    // Baud tick
    logic baud_tick;
    assign baud_tick = (clk_count == BAUD_DIVIDER - 1);

    always_ff @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            state      <= ST_IDLE;
            clk_count  <= 0;
            bit_count  <= 0;
            shift_reg  <= 8'h00;
            parity_bit <= 1'b0;
        end else begin
            state      <= next_state;
            clk_count  <= next_clk_count;
            bit_count  <= next_bit_count;
            shift_reg  <= next_shift_reg;
            parity_bit <= next_parity_bit;
        end
    end

    always_comb begin
        // Defaults
        next_state      = state;
        next_clk_count  = clk_count;
        next_bit_count  = bit_count;
        next_shift_reg  = shift_reg;
        next_parity_bit = parity_bit;
        
        ready           = 1'b0;
        tx              = 1'b1; // Idle state for UART is high

        if (state != ST_IDLE) begin
            if (baud_tick) begin
                next_clk_count = 0;
            end else begin
                next_clk_count = clk_count + 1;
            end
        end

        case (state)
            ST_IDLE: begin
                tx = 1'b1;
                ready = 1'b1;
                if (valid) begin
                    ready = 1'b0;
                    next_shift_reg = tx_data;
                    next_clk_count = 0;
                    next_bit_count = 0;
                    
                    if (PARITY == "EVEN") begin
                        next_parity_bit = ^tx_data;
                    end else if (PARITY == "ODD") begin
                        next_parity_bit = ~(^tx_data);
                    end else begin
                        next_parity_bit = 1'b0;
                    end
                    
                    next_state = ST_START;
                end
            end

            ST_START: begin
                tx = 1'b0; // Start bit is low
                if (baud_tick) begin
                    next_state = ST_DATA;
                end
            end

            ST_DATA: begin
                tx = shift_reg[0]; // Send LSB first
                if (baud_tick) begin
                    next_shift_reg = shift_reg >> 1;
                    if (bit_count == 3'd7) begin
                        if (PARITY == "NONE") begin
                            next_state = ST_STOP;
                        end else begin
                            next_state = ST_PARITY;
                        end
                    end else begin
                        next_bit_count = bit_count + 1;
                    end
                end
            end

            ST_PARITY: begin
                tx = parity_bit;
                if (baud_tick) begin
                    next_state = ST_STOP;
                end
            end

            ST_STOP: begin
                tx = 1'b1; // Stop bit is high
                if (baud_tick) begin
                    next_state = ST_IDLE;
                end
            end
            
            default: next_state = ST_IDLE;
        endcase
    end

endmodule
