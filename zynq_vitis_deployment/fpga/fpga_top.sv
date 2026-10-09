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
    parameter int MEM_DEPTH = 1024,            // 4KB Memory (1024 x 32-bit, fits xc7z010 LUTRAM)
    parameter string HEX_FILE = "firmware.hex"  // Default firmware memory initialization file
)(
    // Dedicated Zynq-7000 PS7 External IO
    inout  wire [14:0] DDR_addr,
    inout  wire [2:0]  DDR_ba,
    inout  wire        DDR_cas_n,
    inout  wire        DDR_ck_n,
    inout  wire        DDR_ck_p,
    inout  wire        DDR_cke,
    inout  wire        DDR_cs_n,
    inout  wire [3:0]  DDR_dm,
    inout  wire [31:0] DDR_dq,
    inout  wire [3:0]  DDR_dqs_n,
    inout  wire [3:0]  DDR_dqs_p,
    inout  wire        DDR_odt,
    inout  wire        DDR_ras_n,
    inout  wire        DDR_reset_n,
    inout  wire        DDR_we_n,
    inout  wire        FIXED_IO_ddr_vrn,
    inout  wire        FIXED_IO_ddr_vrp,
    inout  wire [53:0] FIXED_IO_mio,
    inout  wire        FIXED_IO_ps_clk,
    inout  wire        FIXED_IO_ps_porb,
    inout  wire        FIXED_IO_ps_srstb,

    // PL Zybo Peripherals
    input  logic       BTN0,     // Active-high reset button
    input  logic       BTN1,     // Active-high SEC inject (Zybo Z7 Pin P16)
    input  logic       BTN2,     // Active-high DED inject (Zybo Z7 Pin V16)
    input  logic       BTN3,     // Active-high ALU inject (Zybo Z7 Pin Y16)
    input  logic       SW0,      // Hardware TMR mode switch (Zybo Z7 Pin G15)
    output logic [3:0] LED       // 4 On-board LEDs (Zybo Z7)
);

    // ------------------------------------------------------------------------
    // CLOCK DISTRIBUTION: 50 MHz PS FCLK_CLK0 to 25 MHz Core Clock
    // ------------------------------------------------------------------------
    wire        fclk_50m;
    logic       clk_div_25m = 1'b0;
    logic       clk_31m;

    always_ff @(posedge fclk_50m) begin
        clk_div_25m <= ~clk_div_25m;
    end

    // Global Clock Buffer for clean internal clock distribution
    BUFG u_bufg (
        .I (clk_div_25m),
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
        // Built-in diagnostic firmware default preloaded into BRAM
        mem[0]  = 32'h800002b7; mem[1]  = 32'h0000b337; mem[2]  = 32'haaa30313; mem[3]  = 32'h0062a023;
        mem[4]  = 32'h1ac000ef; mem[5]  = 32'h00005337; mem[6]  = 32'h55530313; mem[7]  = 32'h0062a023;
        mem[8]  = 32'h19c000ef; mem[9]  = 32'h00100313; mem[10] = 32'h0062a023; mem[11] = 32'h00f00093;
        mem[12] = 32'h01900113; mem[13] = 32'h002081b3; mem[14] = 32'h02800213; mem[15] = 32'h12419c63;
        mem[16] = 32'h401101b3; mem[17] = 32'h00a00213; mem[18] = 32'h12419663; mem[19] = 32'h0020f1b3;
        mem[20] = 32'h00900213; mem[21] = 32'h12419063; mem[22] = 32'h0020e1b3; mem[23] = 32'h01f00213;
        mem[24] = 32'h10419a63; mem[25] = 32'h0020c1b3; mem[26] = 32'h01600213; mem[27] = 32'h10419463;
        mem[28] = 32'h0020a1b3; mem[29] = 32'h00100213; mem[30] = 32'h0e419e63; mem[31] = 32'h001121b3;
        mem[32] = 32'h0e019a63; mem[33] = 32'h138000ef; mem[34] = 32'h00200313; mem[35] = 32'h0062a023;
        mem[36] = 32'h00f00093; mem[37] = 32'h00409113; mem[38] = 32'h0f000213; mem[39] = 32'h0e411463;
        mem[40] = 32'h00215193; mem[41] = 32'h03c00213; mem[42] = 32'h0c419e63; mem[43] = 32'h123450b7;
        mem[44] = 32'h12345237; mem[45] = 32'h0c409863; mem[46] = 32'h104000ef; mem[47] = 32'h00300313;
        mem[48] = 32'h0062a023; mem[49] = 32'h000000b7; mem[50] = 32'h40008093; mem[51] = 32'h12345137;
        mem[52] = 32'h0020a023; mem[53] = 32'h00000013; mem[54] = 32'h0000a183; mem[55] = 32'h0a311c63;
        mem[56] = 32'h05a00213; mem[57] = 32'h00408223; mem[58] = 32'h00000013; mem[59] = 32'h0040c383;
        mem[60] = 32'h05a00313; mem[61] = 32'h0a639063; mem[62] = 32'h46800213; mem[63] = 32'h00409423;
        mem[64] = 32'h00000013; mem[65] = 32'h0080d383; mem[66] = 32'h08439663; mem[67] = 32'h0b0000ef;
        mem[68] = 32'h00400313; mem[69] = 32'h0062a023; mem[70] = 32'h00000463; mem[71] = 32'h0880006f;
        mem[72] = 32'h00500093; mem[73] = 32'h00a00113; mem[74] = 32'h0020c463; mem[75] = 32'h0780006f;
        mem[76] = 32'h008001ef; mem[77] = 32'h0700006f; mem[78] = 32'h06018663; mem[79] = 32'h080000ef;
        mem[80] = 32'h00008337; mem[81] = 32'h0ff30313; mem[82] = 32'h0062a023; mem[83] = 32'h070000ef;
        mem[84] = 32'h00100313; mem[85] = 32'h000083b7; mem[86] = 32'h0063e3b3; mem[87] = 32'h0072a023;
        mem[88] = 32'h05c000ef; mem[89] = 32'h00131313; mem[90] = 32'h0ff37313; mem[91] = 32'hfe0314e3;
        mem[92] = 32'hfd1ff06f; mem[93] = 32'h0000f337; mem[94] = 32'h00130313; mem[95] = 32'h0062a023;
        mem[96] = 32'h0340006f; mem[97] = 32'h0000f337; mem[98] = 32'h00230313; mem[99] = 32'h0062a023;
        mem[100]= 32'h0240006f; mem[101]= 32'h0000f337; mem[102]= 32'h00330313; mem[103]= 32'h0062a023;
        mem[104]= 32'h0140006f; mem[105]= 32'h0000f337; mem[106]= 32'h00430313; mem[107]= 32'h0062a023;
        mem[108]= 32'h0040006f; mem[109]= 32'h00100073; mem[110]= 32'hffdff06f; mem[111]= 32'h00000413;
        mem[112]= 32'h001004b7; mem[113]= 32'h00140413; mem[114]= 32'hfe941ee3; mem[115]= 32'h00008067;
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
            tx_toggle <= tx_ack;
            tx_data_latch <= 0;
        end else if (uart_valid && tx_ready) begin
            tx_toggle <= ~tx_toggle;
            tx_data_latch <= uart_tx_data;
        end
    end

    assign gpio_to_ps = {23'd0, tx_toggle, tx_data_latch};

    system_wrapper u_zynq_system (
        .DDR_addr           (DDR_addr),
        .DDR_ba             (DDR_ba),
        .DDR_cas_n          (DDR_cas_n),
        .DDR_ck_n           (DDR_ck_n),
        .DDR_ck_p           (DDR_ck_p),
        .DDR_cke            (DDR_cke),
        .DDR_cs_n           (DDR_cs_n),
        .DDR_dm             (DDR_dm),
        .DDR_dq             (DDR_dq),
        .DDR_dqs_n          (DDR_dqs_n),
        .DDR_dqs_p          (DDR_dqs_p),
        .DDR_odt            (DDR_odt),
        .DDR_ras_n          (DDR_ras_n),
        .DDR_reset_n        (DDR_reset_n),
        .DDR_we_n           (DDR_we_n),
        .FIXED_IO_ddr_vrn   (FIXED_IO_ddr_vrn),
        .FIXED_IO_ddr_vrp   (FIXED_IO_ddr_vrp),
        .FIXED_IO_mio       (FIXED_IO_mio),
        .FIXED_IO_ps_clk    (FIXED_IO_ps_clk),
        .FIXED_IO_ps_porb   (FIXED_IO_ps_porb),
        .FIXED_IO_ps_srstb  (FIXED_IO_ps_srstb),
        .gpio_from_ps_tri_o (gpio_from_ps),
        .gpio_to_ps_tri_i   (gpio_to_ps),
        .fclk_clk0          (fclk_50m)
    );

    // ------------------------------------------------------------------------
    // HARDWARE-IN-THE-LOOP (HIL) CONTROLLER
    // ------------------------------------------------------------------------
    hil_controller u_hil_ctrl (
        .clk           (clk_31m),
        .rst_n         (rst_n),
        .btn_sec       (BTN1),
        .btn_ded       (BTN2),
        .btn_tmr       (BTN3),
        .sw_mode       (SW0),
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
