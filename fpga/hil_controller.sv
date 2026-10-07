`timescale 1ns/1ps

module hil_controller (
    input  logic        clk,
    input  logic        rst_n,

    // UART RX Interface
    input  logic        rx_valid,
    input  logic [7:0]  rx_data,

    // UART TX Interface
    output logic        tx_valid,
    output logic [7:0]  tx_data,
    input  logic        tx_ready,

    // RISC-V Core FI Interface
    output logic        fi_reg_en,
    output logic [3:0]  fi_reg_addr,
    output logic [5:0]  fi_reg_bit,
    output logic        fi_alu_en,
    output logic [1:0]  fi_alu_sel,
    output logic [4:0]  fi_alu_bit,
    output logic        tmr_mode_pin,
    output logic        core_rst_n,

    // RISC-V Core Status Interface
    input  logic        ecc_sec_1,
    input  logic        ecc_ded_1,
    input  logic        ecc_sec_2,
    input  logic        ecc_ded_2,
    input  logic        tmr_mismatch
);

    // ========================================================================
    // RX PACKET PARSER (6 bytes)
    // ========================================================================
    typedef enum logic [2:0] {RX_IDLE, RX_TYPE, RX_REG, RX_BIT, RX_ALU, RX_END} rx_state_t;
    rx_state_t rx_state;

    logic [7:0] cmd_type;
    logic [7:0] cmd_reg;
    logic [7:0] cmd_bit;
    logic [7:0] cmd_alu;

    logic do_inject;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rx_state <= RX_IDLE;
            cmd_type <= 0;
            cmd_reg <= 0;
            cmd_bit <= 0;
            cmd_alu <= 0;
            do_inject <= 0;
        end else begin
            do_inject <= 0; // default pulse 0
            if (rx_valid) begin
                case (rx_state)
                    RX_IDLE: if (rx_data == 8'hAA) rx_state <= RX_TYPE;
                    RX_TYPE: begin cmd_type <= rx_data; rx_state <= RX_REG; end
                    RX_REG:  begin cmd_reg  <= rx_data; rx_state <= RX_BIT; end
                    RX_BIT:  begin cmd_bit  <= rx_data; rx_state <= RX_ALU; end
                    RX_ALU:  begin cmd_alu  <= rx_data; rx_state <= RX_END; end
                    RX_END: begin
                        if (rx_data == 8'h55) do_inject <= 1'b1;
                        rx_state <= RX_IDLE;
                    end
                    default: rx_state <= RX_IDLE;
                endcase
            end
        end
    end

    // ========================================================================
    // INJECTION LOGIC
    // ========================================================================
    logic rst_req;
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            fi_reg_en <= 0;
            fi_reg_addr <= 0;
            fi_reg_bit <= 0;
            fi_alu_en <= 0;
            fi_alu_sel <= 0;
            fi_alu_bit <= 0;
            tmr_mode_pin <= 0; // Default Simplex
            rst_req <= 0;
        end else begin
            fi_reg_en <= 0;
            fi_alu_en <= 0;
            rst_req <= 0;

            if (do_inject) begin
                if (cmd_type == 8'h01 || cmd_type == 8'h02) begin
                    // SEC or DED
                    fi_reg_en <= 1;
                    fi_reg_addr <= cmd_reg[3:0];
                    fi_reg_bit <= cmd_bit[5:0];
                end else if (cmd_type == 8'h03) begin
                    // ALU
                    fi_alu_en <= 1;
                    fi_alu_sel <= cmd_alu[1:0];
                    fi_alu_bit <= cmd_bit[4:0];
                end else if (cmd_type == 8'h04) begin
                    // MODE TOGGLE
                    tmr_mode_pin <= ~tmr_mode_pin;
                end else if (cmd_type == 8'h05) begin
                    // RESET
                    rst_req <= 1;
                end
            end
        end
    end

    // Core Reset generation
    logic [3:0] rst_cnt;
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            core_rst_n <= 0;
            rst_cnt <= 4'hF;
        end else if (rst_req) begin
            core_rst_n <= 0;
            rst_cnt <= 4'hF;
        end else if (rst_cnt != 0) begin
            core_rst_n <= 0;
            rst_cnt <= rst_cnt - 1;
        end else begin
            core_rst_n <= 1;
        end
    end

    // ========================================================================
    // EVENT CAPTURE & TX (14 bytes)
    // ========================================================================
    // Capture events (pulse)
    logic event_sec, event_ded, event_alu;
    assign event_sec = ecc_sec_1 | ecc_sec_2;
    assign event_ded = ecc_ded_1 | ecc_ded_2;
    assign event_alu = tmr_mismatch;

    // We need to latch events if they happen while TX is busy
    logic pending_sec, pending_ded, pending_alu;
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            pending_sec <= 0;
            pending_ded <= 0;
            pending_alu <= 0;
        end else begin
            if (event_sec) pending_sec <= 1;
            if (event_ded) pending_ded <= 1;
            if (event_alu) pending_alu <= 1;
            
            if (tx_start) begin
                // Clear the one we are about to send
                if (pending_ded) pending_ded <= 0;
                else if (pending_alu) pending_alu <= 0;
                else if (pending_sec) pending_sec <= 0;
            end
        end
    end

    // TX State Machine
    typedef enum logic [4:0] {
        TX_IDLE, TX_AA, TX_TYPE, TX_REG, TX_BIT, TX_ALU,
        TX_G3, TX_G2, TX_G1, TX_G0,
        TX_B3, TX_B2, TX_B1, TX_B0,
        TX_55, TX_WAIT
    } tx_state_t;

    tx_state_t tx_state;
    logic tx_start;
    logic [7:0] tx_byte_to_send;
    logic [7:0] active_type;

    assign tx_start = (tx_state == TX_IDLE) && (pending_ded | pending_alu | pending_sec);

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            tx_state <= TX_IDLE;
            tx_valid <= 0;
            tx_data <= 0;
            active_type <= 0;
        end else begin
            tx_valid <= 0; // default

            case (tx_state)
                TX_IDLE: begin
                    if (pending_ded) active_type <= 8'h02;
                    else if (pending_alu) active_type <= 8'h03;
                    else if (pending_sec) active_type <= 8'h01;

                    if (tx_start) begin
                        tx_state <= TX_AA;
                    end
                end
                
                TX_AA:   if (tx_ready) begin tx_valid <= 1; tx_data <= 8'hAA; tx_state <= TX_TYPE; end
                TX_TYPE: if (tx_ready) begin tx_valid <= 1; tx_data <= active_type; tx_state <= TX_REG; end
                TX_REG:  if (tx_ready) begin tx_valid <= 1; tx_data <= cmd_reg; tx_state <= TX_BIT; end
                TX_BIT:  if (tx_ready) begin tx_valid <= 1; tx_data <= cmd_bit; tx_state <= TX_ALU; end
                TX_ALU:  if (tx_ready) begin tx_valid <= 1; tx_data <= cmd_alu; tx_state <= TX_G3; end
                
                // Good value (0x00000000 for simplicity)
                TX_G3:   if (tx_ready) begin tx_valid <= 1; tx_data <= 8'h00; tx_state <= TX_G2; end
                TX_G2:   if (tx_ready) begin tx_valid <= 1; tx_data <= 8'h00; tx_state <= TX_G1; end
                TX_G1:   if (tx_ready) begin tx_valid <= 1; tx_data <= 8'h00; tx_state <= TX_G0; end
                TX_G0:   if (tx_ready) begin tx_valid <= 1; tx_data <= 8'h00; tx_state <= TX_B3; end
                
                // Bad value (0xDEADBEEF for simplicity)
                TX_B3:   if (tx_ready) begin tx_valid <= 1; tx_data <= 8'hDE; tx_state <= TX_B2; end
                TX_B2:   if (tx_ready) begin tx_valid <= 1; tx_data <= 8'hAD; tx_state <= TX_B1; end
                TX_B1:   if (tx_ready) begin tx_valid <= 1; tx_data <= 8'hBE; tx_state <= TX_B0; end
                TX_B0:   if (tx_ready) begin tx_valid <= 1; tx_data <= 8'hEF; tx_state <= TX_55; end
                
                TX_55:   if (tx_ready) begin tx_valid <= 1; tx_data <= 8'h55; tx_state <= TX_WAIT; end
                
                TX_WAIT: begin
                    // Wait for the last byte to clear ready (just a small delay)
                    if (tx_ready) tx_state <= TX_IDLE;
                end
            endcase
        end
    end

endmodule
