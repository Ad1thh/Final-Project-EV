// ============================================================================
// File: fpga_top.sv
// Description: Top-Level Wrapper for RV32E Core on Xilinx Nexys 4 (Artix-7) FPGA.
//              Integrates riscv_core_top ASIC core without microarchitectural edits.
//              Handles 100MHz-to-25MHz clock division, active-low reset
//              synchronization, Block RAM memory initialization, and 
//              MMIO mapping at 0x8000_0000 to drive 16 board LEDs.
// Standards: SystemVerilog-2012 / Xilinx Vivado Compatible
// ============================================================================

`timescale 1ns/1ps

module fpga_top #(
    parameter int MEM_DEPTH = 8192,            // 32KB Memory (8192 x 32-bit)
    parameter string HEX_FILE = "firmware.hex"  // Default firmware memory initialization file
)(
    input  logic       sysclk,   // 125 MHz input clock (Zybo Z7 Pin K17)
    input  logic       BTN0,     // Active-high reset button (Zybo Z7 Pin K18)
    output logic [3:0] LED       // 4 On-board LEDs (Zybo Z7)
);

    // ------------------------------------------------------------------------
    // CLOCK DIVISION: 125 MHz to 31.25 MHz
    // ------------------------------------------------------------------------
    logic [1:0] clk_div_cnt = 2'b00;
    logic       clk_31m_raw;
    logic       clk_31m;

    always_ff @(posedge sysclk) begin
        clk_div_cnt <= clk_div_cnt + 1'b1;
    end

    assign clk_31m_raw = clk_div_cnt[1];

    // Global Clock Buffer for clean internal clock distribution
    BUFG u_bufg (
        .I (clk_31m_raw),
        .O (clk_31m)
    );

    // ------------------------------------------------------------------------
    // AUTOMATIC POWER-ON & BUTTON RESET GENERATOR (Pin E16 BTNC)
    // ------------------------------------------------------------------------
    logic [7:0] por_cnt = 8'h00;
    logic       rst_n;

    always_ff @(posedge clk_31m) begin
        if (BTN0) begin // Active-high BTN0 button pressed
            por_cnt <= 8'h00;
            rst_n   <= 1'b0;
        end else if (por_cnt != 8'hFF) begin // Auto reset for 256 cycles after bitstream flash
            por_cnt <= por_cnt + 1'b1;
            rst_n   <= 1'b0;
        end else begin
            rst_n   <= 1'b1; // CPU Running!
        end
    end

    // ------------------------------------------------------------------------
    // CPU CORE INTERFACE SIGNALS
    // ------------------------------------------------------------------------
    logic [31:0] imem_addr;
    logic [31:0] imem_rdata;
    logic [31:0] dmem_addr;
    logic [31:0] dmem_wdata;
    logic [3:0]  dmem_wmask;
    logic        dmem_we;
    logic [31:0] dmem_rdata;
    (* keep = "true", mark_debug = "true" *) logic [31:0] pc_debug;
    (* keep = "true", mark_debug = "true" *) logic        trap;

    logic        tmr_mode_pin;
    logic        fi_reg_en;
    logic [3:0]  fi_reg_addr;
    logic [5:0]  fi_reg_bit;
    logic        fi_alu_en;
    logic [1:0]  fi_alu_sel;
    logic [4:0]  fi_alu_bit;
    logic        ecc_sec_1, ecc_ded_1, ecc_sec_2, ecc_ded_2, tmr_mismatch, tmr_fatal_mismatch, pc_tmr_mismatch, pc_tmr_fatal_mismatch;
    logic        core_rst_n;

    // ------------------------------------------------------------------------
    // CPU CORE INSTANTIATION (IMMUTABLE ASIC IP)
    // ------------------------------------------------------------------------
    riscv_core_top #(
        .DATA_WIDTH (32),
        .REG_COUNT  (16),
        .ADDR_WIDTH (4)
    ) u_riscv_core (
        .clk        (clk_31m),
        .rst_n      (core_rst_n),
        .imem_addr  (imem_addr),
        .imem_rdata (imem_rdata),
        .dmem_addr  (dmem_addr),
        .dmem_wdata (dmem_wdata),
        .dmem_wmask (dmem_wmask),
        .dmem_we    (dmem_we),
        .dmem_rdata (dmem_rdata),
        .pc_debug   (pc_debug),
        .trap       (trap),
        .tmr_mode_pin(tmr_mode_pin),
        .fi_reg_en(fi_reg_en),
        .fi_reg_addr(fi_reg_addr),
        .fi_reg_bit(fi_reg_bit),
        .fi_alu_en(fi_alu_en),
        .fi_alu_sel(fi_alu_sel),
        .fi_alu_bit(fi_alu_bit),
        .ecc_sec_1(ecc_sec_1),
        .ecc_ded_1(ecc_ded_1),
        .ecc_sec_2(ecc_sec_2),
        .ecc_ded_2(ecc_ded_2),
        .tmr_mismatch(tmr_mismatch),
        .tmr_fatal_mismatch(tmr_fatal_mismatch),
        .pc_tmr_mismatch(pc_tmr_mismatch),
        .pc_tmr_fatal_mismatch(pc_tmr_fatal_mismatch)
    );

    // ------------------------------------------------------------------------
    // UNIFIED BLOCK RAM MEMORY ARRAY
    // ------------------------------------------------------------------------
    (* ram_style = "block" *) logic [31:0] mem [0:MEM_DEPTH-1];

    initial begin
        for (int i = 0; i < MEM_DEPTH; i++) begin
            mem[i] = 32'h0000_0013; // Default to NOP (ADDI x0, x0, 0)
        end
        if (HEX_FILE != "") begin
            $readmemh(HEX_FILE, mem);
        end
    end

    // Instruction Memory Read
    wire [31:0] imem_idx = imem_addr >> 2;
    assign imem_rdata = (imem_idx < MEM_DEPTH) ? mem[imem_idx] : 32'h0000_0013;

    // Data Memory Write (RAM space: dmem_addr[31] == 0)
    wire [31:0] dmem_idx = dmem_addr >> 2;

    always_ff @(posedge clk_31m) begin
        if (dmem_we && !dmem_addr[31] && (dmem_idx < MEM_DEPTH)) begin
            if (dmem_wmask[0]) mem[dmem_idx][7:0]   <= dmem_wdata[7:0];
            if (dmem_wmask[1]) mem[dmem_idx][15:8]  <= dmem_wdata[15:8];
            if (dmem_wmask[2]) mem[dmem_idx][23:16] <= dmem_wdata[23:16];
            if (dmem_wmask[3]) mem[dmem_idx][31:24] <= dmem_wdata[31:24];
        end
    end

    // ------------------------------------------------------------------------
    // MMIO MAPPING: 0x8000_0000 -> BOARD LEDS
    // ------------------------------------------------------------------------
    logic [3:0]  led_reg = 4'h1;

    always_ff @(posedge clk_31m or negedge core_rst_n) begin
        if (!core_rst_n) begin
            led_reg <= 4'h1; // Power/Reset indicator (LED 0 active on reset)
        end else begin
            if (dmem_we && dmem_addr[31]) begin // Address 0x8000_0000 region
                if (dmem_addr[7:0] == 8'h00) begin
                    if (dmem_wmask[0]) led_reg[3:0] <= dmem_wdata[3:0];
                end
            end
        end
    end

    assign LED = led_reg;

    // ------------------------------------------------------------------------
    // ZYNQ PS & AXI GPIO BRIDGE (Hardware-in-the-Loop)
    // ------------------------------------------------------------------------
    logic [31:0] gpio_from_ps; // Channel 1 (Output from PS to PL)
    logic [31:0] gpio_to_ps;   // Channel 2 (Input from PL to PS)

    // Synchronize GPIO inputs from PS (since PS clock may differ or have skew)
    logic [31:0] gpio_from_ps_sync1, gpio_from_ps_sync;
    always_ff @(posedge clk_31m) begin
        gpio_from_ps_sync1 <= gpio_from_ps;
        gpio_from_ps_sync  <= gpio_from_ps_sync1;
    end

    logic [7:0] rx_data;
    logic rx_toggle;
    logic tx_ack;

    assign rx_data   = gpio_from_ps_sync[7:0];
    assign rx_toggle = gpio_from_ps_sync[8];
    assign tx_ack    = gpio_from_ps_sync[9];

    // RX Edge Detector
    logic rx_toggle_q;
    logic rx_valid;
    always_ff @(posedge clk_31m or negedge rst_n) begin
        if (!rst_n) rx_toggle_q <= 0;
        else rx_toggle_q <= rx_toggle;
    end
    assign rx_valid = (rx_toggle != rx_toggle_q);

    // TX Handshake
    logic [7:0] tx_data_latch;
    logic tx_toggle;
    logic tx_ready;
    logic uart_valid;
    logic [7:0] uart_tx_data;
    logic tx_ack_q;

    always_ff @(posedge clk_31m) tx_ack_q <= tx_ack;
    assign tx_ready = (tx_toggle == tx_ack_q);

    always_ff @(posedge clk_31m or negedge rst_n) begin
        if (!rst_n) begin
            tx_toggle <= 0;
            tx_data_latch <= 0;
        end else if (uart_valid && tx_ready) begin
            tx_toggle <= ~tx_toggle;
            tx_data_latch <= uart_tx_data;
        end
    end

    assign gpio_to_ps = {23'd0, tx_toggle, tx_data_latch};

    system_wrapper u_zynq_system (
        .gpio_from_ps_tri_o (gpio_from_ps),
        .gpio_to_ps_tri_i   (gpio_to_ps)
    );

    // ------------------------------------------------------------------------
    // HARDWARE-IN-THE-LOOP (HIL) CONTROLLER
    // ------------------------------------------------------------------------
    hil_controller u_hil_ctrl (
        .clk           (clk_31m),
        .rst_n         (rst_n),
        .rx_valid      (rx_valid),
        .rx_data       (rx_data),
        .tx_valid      (uart_valid),
        .tx_data       (uart_tx_data),
        .tx_ready      (tx_ready),
        .fi_reg_en     (fi_reg_en),
        .fi_reg_addr   (fi_reg_addr),
        .fi_reg_bit    (fi_reg_bit),
        .fi_alu_en     (fi_alu_en),
        .fi_alu_sel    (fi_alu_sel),
        .fi_alu_bit    (fi_alu_bit),
        .tmr_mode_pin  (tmr_mode_pin),
        .core_rst_n    (core_rst_n),
        .ecc_sec_1     (ecc_sec_1),
        .ecc_ded_1     (ecc_ded_1),
        .ecc_sec_2     (ecc_sec_2),
        .ecc_ded_2     (ecc_ded_2),
        .tmr_mismatch  (tmr_mismatch)
    );

    // Data Memory Read (MMIO at 0x8000_0000 vs BRAM read)
    assign dmem_rdata = (dmem_addr[31]) ? 
                            ((dmem_addr[7:0] == 8'h00) ? {28'h0000000, led_reg} : 32'h0000_0000) :
                        ((dmem_idx < MEM_DEPTH) ? mem[dmem_idx] : 32'h0000_0000);

endmodule
