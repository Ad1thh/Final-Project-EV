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
    input  logic        CLK100MHZ,  // 100 MHz input clock (Nexys 4 Pin E3)
    input  logic        CPU_RESETN, // Active-low reset button (Nexys 4 Pin C12)
    output logic [15:0] LED,        // 16 On-board LEDs
    output logic        UART_TXD    // UART Transmit Data
);

    // ------------------------------------------------------------------------
    // CLOCK DIVISION: 100 MHz to 25 MHz
    // ------------------------------------------------------------------------
    logic [1:0] clk_div_cnt = 2'b00;
    logic       clk_25m_raw;
    logic       clk_25m;

    always_ff @(posedge CLK100MHZ) begin
        clk_div_cnt <= clk_div_cnt + 1'b1;
    end

    assign clk_25m_raw = clk_div_cnt[1];

    // Global Clock Buffer for clean internal clock distribution
    BUFG u_bufg (
        .I (clk_25m_raw),
        .O (clk_25m)
    );

    // ------------------------------------------------------------------------
    // AUTOMATIC POWER-ON & BUTTON RESET GENERATOR (Pin E16 BTNC)
    // ------------------------------------------------------------------------
    logic [7:0] por_cnt = 8'h00;
    logic       rst_n;

    always_ff @(posedge clk_25m) begin
        if (CPU_RESETN) begin // Active-high BTNC button pressed
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

    // ------------------------------------------------------------------------
    // CPU CORE INSTANTIATION (IMMUTABLE ASIC IP)
    // ------------------------------------------------------------------------
    riscv_core_top #(
        .DATA_WIDTH (32),
        .REG_COUNT  (16),
        .ADDR_WIDTH (4)
    ) u_riscv_core (
        .clk        (clk_25m),
        .rst_n      (rst_n),
        .imem_addr  (imem_addr),
        .imem_rdata (imem_rdata),
        .dmem_addr  (dmem_addr),
        .dmem_wdata (dmem_wdata),
        .dmem_wmask (dmem_wmask),
        .dmem_we    (dmem_we),
        .dmem_rdata (dmem_rdata),
        .pc_debug   (pc_debug),
        .trap       (trap)
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

    always_ff @(posedge clk_25m) begin
        if (dmem_we && !dmem_addr[31] && (dmem_idx < MEM_DEPTH)) begin
            if (dmem_wmask[0]) mem[dmem_idx][7:0]   <= dmem_wdata[7:0];
            if (dmem_wmask[1]) mem[dmem_idx][15:8]  <= dmem_wdata[15:8];
            if (dmem_wmask[2]) mem[dmem_idx][23:16] <= dmem_wdata[23:16];
            if (dmem_wmask[3]) mem[dmem_idx][31:24] <= dmem_wdata[31:24];
        end
    end

    // ------------------------------------------------------------------------
    // MMIO MAPPING: 0x8000_0000 -> BOARD LEDS, 0x8000_0008 -> UART TX
    // ------------------------------------------------------------------------
    logic [15:0] led_reg = 16'h0001;
    logic        uart_valid;
    logic [7:0]  uart_tx_data;
    logic        uart_ready;

    always_ff @(posedge clk_25m or negedge rst_n) begin
        if (!rst_n) begin
            led_reg <= 16'h0001; // Power/Reset indicator (LED 0 active on reset)
            uart_valid <= 1'b0;
            uart_tx_data <= 8'h00;
        end else begin
            uart_valid <= 1'b0; // Default: 1-cycle pulse
            
            if (dmem_we && dmem_addr[31]) begin // Address 0x8000_0000 region
                if (dmem_addr[7:0] == 8'h00) begin
                    if (dmem_wmask[0]) led_reg[7:0]  <= dmem_wdata[7:0];
                    if (dmem_wmask[1]) led_reg[15:8] <= dmem_wdata[15:8];
                end else if (dmem_addr[7:0] == 8'h08) begin
                    if (dmem_wmask[0]) begin
                        uart_tx_data <= dmem_wdata[7:0];
                        uart_valid <= 1'b1;
                    end
                end
            end
        end
    end

    assign LED = led_reg;

    // ------------------------------------------------------------------------
    // UART TRANSMITTER
    // ------------------------------------------------------------------------
    uart_tx #(
        .BAUD_DIVIDER(217), // 25MHz / 115200
        .PARITY("NONE")
    ) u_uart_tx (
        .clk     (clk_25m),
        .rstn    (rst_n),
        .valid   (uart_valid),
        .ready   (uart_ready),
        .tx_data (uart_tx_data),
        .tx      (UART_TXD)
    );

    // Data Memory Read (MMIO at 0x8000_0000 vs BRAM read)
    assign dmem_rdata = (dmem_addr[31]) ? 
                            ((dmem_addr[7:0] == 8'h0C) ? {31'h0, uart_ready} : {16'h0000, led_reg}) :
                        ((dmem_idx < MEM_DEPTH) ? mem[dmem_idx] : 32'h0000_0000);

endmodule
