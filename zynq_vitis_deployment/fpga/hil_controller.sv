`timescale 1ns/1ps

module hil_controller (
    input  logic        clk,
    input  logic        rst_n,

    // Physical Zybo Board Buttons and Switch
    input  logic        btn_sec,
    input  logic        btn_ded,
    input  logic        btn_tmr,
    input  logic        sw_mode,

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
    logic [7:0] rx_cmd_reg;
    logic [7:0] rx_cmd_bit;
    logic [7:0] rx_cmd_alu;

    logic do_inject;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rx_state   <= RX_IDLE;
            cmd_type   <= 0;
            rx_cmd_reg <= 0;
            rx_cmd_bit <= 0;
            rx_cmd_alu <= 0;
            do_inject  <= 0;
        end else begin
            do_inject <= 0; // default pulse 0
            if (rx_valid) begin
                case (rx_state)
                    RX_IDLE: if (rx_data == 8'hAA) rx_state <= RX_TYPE;
                    RX_TYPE: begin cmd_type   <= rx_data; rx_state <= RX_REG; end
                    RX_REG:  begin rx_cmd_reg <= rx_data; rx_state <= RX_BIT; end
                    RX_BIT:  begin rx_cmd_bit <= rx_data; rx_state <= RX_ALU; end
                    RX_ALU:  begin rx_cmd_alu <= rx_data; rx_state <= RX_END; end
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
    // PHYSICAL BUTTON & SWITCH SYNCHRONIZATION
    // ========================================================================
    logic [2:0] btn_sec_sync, btn_ded_sync, btn_tmr_sync, sw_mode_sync;
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            btn_sec_sync <= 3'b000;
            btn_ded_sync <= 3'b000;
            btn_tmr_sync <= 3'b000;
            sw_mode_sync <= 3'b000;
        end else begin
            btn_sec_sync <= {btn_sec_sync[1:0], btn_sec};
            btn_ded_sync <= {btn_ded_sync[1:0], btn_ded};
            btn_tmr_sync <= {btn_tmr_sync[1:0], btn_tmr};
            sw_mode_sync <= {sw_mode_sync[1:0], sw_mode};
        end
    end

    wire btn_sec_pulse = (btn_sec_sync[2:1] == 2'b01);
    wire btn_ded_pulse = (btn_ded_sync[2:1] == 2'b01);
    wire btn_tmr_pulse = (btn_tmr_sync[2:1] == 2'b01);
    wire sw_mode_edge  = (sw_mode_sync[2] ^ sw_mode_sync[1]);

    // ========================================================================
    // INJECTION LOGIC
    // ========================================================================
    logic rst_req;
    logic tmr_mode_uart_toggle;
    logic [7:0] target_reg;
    logic [7:0] target_bit;
    logic [7:0] target_alu;
    logic [2:0] sec_restore_cnt;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            fi_reg_en <= 0;
            fi_reg_addr <= 0;
            fi_reg_bit <= 0;
            fi_alu_en <= 0;
            fi_alu_sel <= 0;
            fi_alu_bit <= 0;
            tmr_mode_uart_toggle <= 0;
            tmr_mode_pin <= 0;
            rst_req <= 0;
            target_reg <= 0;
            target_bit <= 0;
            target_alu <= 0;
        end else begin
            fi_reg_en <= 0;
            fi_alu_en <= 0;
            rst_req <= 0;

            // Auto-restore SEC register flip after 4 cycles to return rf[1] to nominal
            if (sec_restore_cnt != 3'd0) begin
                sec_restore_cnt <= sec_restore_cnt - 1'b1;
                if (sec_restore_cnt == 3'd1) begin
                    fi_reg_en   <= 1'b1;
                    fi_reg_addr <= target_reg[3:0];
                    fi_reg_bit  <= target_bit[5:0];
                end
            end

            // Mode combination: Switch SW0 XOR UART Toggle
            tmr_mode_pin <= sw_mode_sync[2] ^ tmr_mode_uart_toggle;

            if (sw_mode_edge) begin
                target_reg <= {7'd0, (sw_mode_sync[1] ^ tmr_mode_uart_toggle)};
                target_bit <= 8'd0;
                target_alu <= 8'd0;
            end else if (btn_sec_pulse) begin
                // Physical BTN1: Inject SEC into Register 1, Bit 0
                fi_reg_en       <= 1'b1;
                fi_reg_addr     <= 4'd1;
                fi_reg_bit      <= 6'd0;
                target_reg      <= 8'd1;
                target_bit      <= 8'd0;
                target_alu      <= 8'd0;
                sec_restore_cnt <= 3'd4;
            end else if (btn_ded_pulse) begin
                // Physical BTN2: Inject DED into Register 1, Bit 0
                fi_reg_en   <= 1'b1;
                fi_reg_addr <= 4'd1;
                fi_reg_bit  <= 6'd0;
                target_reg  <= 8'd1;
                target_bit  <= 8'd0;
                target_alu  <= 8'd0;
            end else if (btn_tmr_pulse) begin
                // Physical BTN3: Inject ALU Fault into ALU0, Bit 0
                fi_alu_en   <= 1'b1;
                fi_alu_sel  <= 2'b00;
                fi_alu_bit  <= 5'd0;
                target_reg  <= 8'd0;
                target_bit  <= 8'd0;
                target_alu  <= 8'd0;
            end else if (do_inject) begin
                target_reg <= rx_cmd_reg;
                target_bit <= rx_cmd_bit;
                target_alu <= rx_cmd_alu;
                if (cmd_type == 8'h01 || cmd_type == 8'h02) begin
                    // SEC or DED
                    fi_reg_en <= 1;
                    fi_reg_addr <= rx_cmd_reg[3:0];
                    fi_reg_bit <= rx_cmd_bit[5:0];
                    if (cmd_type == 8'h01) sec_restore_cnt <= 3'd4;
                end else if (cmd_type == 8'h03) begin
                    // ALU
                    fi_alu_en <= 1;
                    fi_alu_sel <= rx_cmd_alu[1:0];
                    fi_alu_bit <= rx_cmd_bit[4:0];
                end else if (cmd_type == 8'h04) begin
                    // MODE TOGGLE
                    tmr_mode_uart_toggle <= ~tmr_mode_uart_toggle;
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

    // Frame storage (14 bytes)
    wire [7:0] tx_frame [0:13];
    assign tx_frame[0]  = 8'hAA;
    assign tx_frame[1]  = active_type;
    assign tx_frame[2]  = (active_type == 8'h05) ? {7'd0, tmr_mode_pin} : target_reg;
    assign tx_frame[3]  = target_bit;
    assign tx_frame[4]  = target_alu;
    assign tx_frame[5]  = 8'h00; // G3
    assign tx_frame[6]  = 8'h00; // G2
    assign tx_frame[7]  = 8'h00; // G1
    assign tx_frame[8]  = 8'h00; // G0
    assign tx_frame[9]  = 8'hDE; // B3
    assign tx_frame[10] = 8'hAD; // B2
    assign tx_frame[11] = 8'hBE; // B1
    assign tx_frame[12] = 8'hEF; // B0
    assign tx_frame[13] = 8'h55;

    typedef enum logic [1:0] {TX_IDLE, TX_SEND, TX_WAIT_ACK} tx_state_t;
    tx_state_t tx_state;
    logic [3:0] tx_idx;
    logic tx_start;
    logic [7:0] active_type;

    // We need to latch events if they happen while TX is busy
    logic pending_sec, pending_ded, pending_alu, pending_rst, pending_mode;
    logic rst_sent;
    assign tx_start = (tx_state == TX_IDLE) && (pending_rst | pending_ded | pending_alu | pending_sec | pending_mode);

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            pending_sec  <= 0;
            pending_ded  <= 0;
            pending_alu  <= 0;
            pending_rst  <= 0;
            pending_mode <= 0;
            rst_sent     <= 0;
        end else begin
            if (!rst_sent) begin
                pending_rst <= 1;
                rst_sent    <= 1;
            end else if (rst_req) begin
                pending_rst <= 1;
            end

            if (btn_sec_pulse || (do_inject && cmd_type == 8'h01)) pending_sec <= 1;
            if (event_ded || btn_ded_pulse || (do_inject && cmd_type == 8'h02)) pending_ded <= 1;
            if (event_alu || btn_tmr_pulse || (do_inject && cmd_type == 8'h03)) pending_alu <= 1;
            if (sw_mode_edge || (do_inject && cmd_type == 8'h04)) pending_mode <= 1;
            
            if (tx_start) begin
                // Clear the one we are about to send (priority: RESET > DED > ALU > SEC > MODE)
                if (pending_rst) pending_rst <= 0;
                else if (pending_ded) pending_ded <= 0;
                else if (pending_alu) pending_alu <= 0;
                else if (pending_sec) pending_sec <= 0;
                else if (pending_mode) pending_mode <= 0;
            end
        end
    end

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            tx_state    <= TX_IDLE;
            tx_valid    <= 1'b0;
            tx_data     <= 8'h00;
            tx_idx      <= 4'd0;
            active_type <= 8'h00;
        end else begin
            tx_valid <= 1'b0; // default 1-cycle pulse

            case (tx_state)
                TX_IDLE: begin
                    tx_idx <= 4'd0;
                    if (pending_rst) begin
                        active_type <= 8'h05;
                    end
                    else if (pending_ded)  active_type <= 8'h02;
                    else if (pending_alu)  active_type <= 8'h03;
                    else if (pending_sec)  active_type <= 8'h01;
                    else if (pending_mode) active_type <= 8'h04;

                    if (tx_start) begin
                        tx_state <= TX_SEND;
                    end
                end

                TX_SEND: begin
                    if (tx_ready) begin
                        tx_valid <= 1'b1;
                        tx_data  <= tx_frame[tx_idx];
                        tx_state <= TX_WAIT_ACK;
                    end
                end

                TX_WAIT_ACK: begin
                    // Wait for Cortex-A9 acknowledgment
                    if (tx_ready) begin
                        if (tx_idx == 4'd13) begin
                            tx_state <= TX_IDLE;
                        end else begin
                            tx_idx   <= tx_idx + 1'b1;
                            tx_state <= TX_SEND;
                        end
                    end
                end

                default: tx_state <= TX_IDLE;
            endcase
        end
    end

endmodule
