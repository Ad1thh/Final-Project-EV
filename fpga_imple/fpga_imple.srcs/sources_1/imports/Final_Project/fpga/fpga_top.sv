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
    output logic [15:0] LED         // 16 On-board LEDs
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
    // RESET SYNCHRONIZATION (Button Pressed = Reset Active)
    // ------------------------------------------------------------------------
    logic rst_n_sync_1;
    logic rst_n;

    always_ff @(posedge clk_25m or posedge CPU_RESETN) begin
        if (CPU_RESETN) begin
            rst_n_sync_1 <= 1'b0;
            rst_n        <= 1'b0;
        end else begin
            rst_n_sync_1 <= 1'b1;
            rst_n        <= rst_n_sync_1;
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
    // MMIO MAPPING: 0x8000_0000 -> BOARD LEDS
    // ------------------------------------------------------------------------
    logic [15:0] led_reg = 16'h0001;

    always_ff @(posedge clk_25m or negedge rst_n) begin
        if (!rst_n) begin
            led_reg <= 16'h0001; // Power/Reset indicator (LED 0 active on reset)
        end else if (dmem_we && dmem_addr[31]) begin // Address 0x8000_0000 region
            if (dmem_wmask[0]) led_reg[7:0]  <= dmem_wdata[7:0];
            if (dmem_wmask[1]) led_reg[15:8] <= dmem_wdata[15:8];
        end
    end

    assign LED = led_reg;

    // Data Memory Read (MMIO at 0x8000_0000 vs BRAM read)
    assign dmem_rdata = (dmem_addr[31]) ? {16'h0000, led_reg} :
                        ((dmem_idx < MEM_DEPTH) ? mem[dmem_idx] : 32'h0000_0000);

endmodule
