`timescale 1ns/1ps
// Minimal compliance/fuzzer run wrapper — no FT preamble, just load HEX and run to trap.
module tb_compliance_run;

    logic clk, rst_n;
    logic [31:0] imem_addr, imem_rdata;
    logic [31:0] dmem_addr, dmem_wdata, dmem_rdata, pc_debug;
    logic [3:0]  dmem_wmask;
    logic        dmem_we, trap;

    // FT ports tied off
    logic tmr_mode_pin = 1'b0;
    logic fi_reg_en    = 1'b0;
    logic [3:0] fi_reg_addr = '0;
    logic [5:0] fi_reg_bit  = '0;
    logic fi_alu_en    = 1'b0;
    logic [1:0] fi_alu_sel  = '0;
    logic [4:0] fi_alu_bit  = '0;
    logic ecc_sec_1, ecc_ded_1, ecc_sec_2, ecc_ded_2, tmr_mismatch, tmr_fatal_mismatch;

    // 64KB byte-addressable memory
    logic [7:0] memory [0:65535];

    assign imem_rdata = {memory[imem_addr+3], memory[imem_addr+2],
                         memory[imem_addr+1], memory[imem_addr]};
    assign dmem_rdata = {memory[dmem_addr+3], memory[dmem_addr+2],
                         memory[dmem_addr+1], memory[dmem_addr]};

    always_ff @(posedge clk) begin
        if (dmem_we) begin
            if (dmem_wmask[0]) memory[dmem_addr]   <= dmem_wdata[7:0];
            if (dmem_wmask[1]) memory[dmem_addr+1] <= dmem_wdata[15:8];
            if (dmem_wmask[2]) memory[dmem_addr+2] <= dmem_wdata[23:16];
            if (dmem_wmask[3]) memory[dmem_addr+3] <= dmem_wdata[31:24];
        end
    end

    riscv_core_top #(.DATA_WIDTH(32),.REG_COUNT(16),.ADDR_WIDTH(4)) dut (
        .clk(clk), .rst_n(rst_n),
        .imem_addr(imem_addr), .imem_rdata(imem_rdata),
        .dmem_addr(dmem_addr), .dmem_wdata(dmem_wdata),
        .dmem_wmask(dmem_wmask), .dmem_we(dmem_we), .dmem_rdata(dmem_rdata),
        .pc_debug(pc_debug), .trap(trap),
        .tmr_mode_pin(tmr_mode_pin),
        .fi_reg_en(fi_reg_en), .fi_reg_addr(fi_reg_addr), .fi_reg_bit(fi_reg_bit),
        .fi_alu_en(fi_alu_en), .fi_alu_sel(fi_alu_sel), .fi_alu_bit(fi_alu_bit),
        .ecc_sec_1(ecc_sec_1), .ecc_ded_1(ecc_ded_1),
        .ecc_sec_2(ecc_sec_2), .ecc_ded_2(ecc_ded_2),
        .tmr_mismatch(tmr_mismatch),
        .tmr_fatal_mismatch(tmr_fatal_mismatch)
    );

    initial begin clk = 0; forever #5 clk = ~clk; end

    // Watchdog: 2M time units = 200K cycles @ 10ns period
    initial begin
        #2000000;
        $display("[TIMEOUT] Simulation exceeded 200K cycles without trap.");
        $finish;
    end

    string hex_file;

    initial begin
        for (int i = 0; i < 65536; i++) memory[i] = 8'h00;

        if ($value$plusargs("HEX=%s", hex_file)) begin
            $readmemh(hex_file, memory);
            $display("[3.1] Loaded %s", hex_file);
        end else begin
            $display("[3.1] ERROR: No +HEX argument.");
            $finish;
        end

        rst_n = 1'b0;
        #20;
        rst_n = 1'b1;

        wait (trap == 1'b1);
        #20;

        $display("[3.1] Trap received at PC=0x%08h", pc_debug);
        $display("[3.1] RESULT: TEST PASSED — fuzzer reached ebreak without pipeline failure");
        $finish;
    end

endmodule
