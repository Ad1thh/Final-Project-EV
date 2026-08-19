// ============================================================================
// File: tb_fault_tolerance_debug2.sv
// Description: Targeted debug with memory result capture
// ============================================================================

`timescale 1ns/1ps

module tb_fault_tolerance_debug2;

    parameter int MEM_DEPTH = 8192;
    parameter time CLK_PERIOD = 10;

    logic clk;
    logic rst_n;
    logic [31:0] imem_addr;
    logic [31:0] imem_rdata;
    logic [31:0] dmem_addr;
    logic [31:0] dmem_wdata;
    logic [3:0]  dmem_wmask;
    logic        dmem_we;
    logic [31:0] dmem_rdata;
    logic [31:0] pc_debug;
    logic        trap;
    logic        tmr_mode_pin;
    logic        fi_reg_en;
    logic [3:0]  fi_reg_addr;
    logic [5:0]  fi_reg_bit;
    logic        fi_alu_en;
    logic [1:0]  fi_alu_sel;
    logic [4:0]  fi_alu_bit;
    logic        ecc_sec_1, ecc_ded_1;
    logic        ecc_sec_2, ecc_ded_2;
    logic        tmr_mismatch;

    logic [31:0] mem [0:MEM_DEPTH-1];
    integer i;

    initial begin
        clk = 0;
        forever #(CLK_PERIOD/2) clk = ~clk;
    end

    assign imem_rdata = (imem_addr < MEM_DEPTH*4) ? mem[imem_addr[13:2]] : 32'h0000_0013;
    assign dmem_rdata = (dmem_addr < MEM_DEPTH*4) ? mem[dmem_addr[13:2]] : 32'h0000_0000;

    always_ff @(posedge clk) begin
        if (dmem_we) begin
            if (dmem_wmask[0]) mem[dmem_addr[13:2]][7:0]   <= dmem_wdata[7:0];
            if (dmem_wmask[1]) mem[dmem_addr[13:2]][15:8]  <= dmem_wdata[15:8];
            if (dmem_wmask[2]) mem[dmem_addr[13:2]][23:16] <= dmem_wdata[23:16];
            if (dmem_wmask[3]) mem[dmem_addr[13:2]][31:24] <= dmem_wdata[31:24];
        end
    end

    riscv_core_top #(
        .DATA_WIDTH (32),
        .REG_COUNT  (16),
        .ADDR_WIDTH (4)
    ) dut (
        .clk          (clk),
        .rst_n        (rst_n),
        .imem_addr    (imem_addr),
        .imem_rdata   (imem_rdata),
        .dmem_addr    (dmem_addr),
        .dmem_wdata   (dmem_wdata),
        .dmem_wmask   (dmem_wmask),
        .dmem_we      (dmem_we),
        .dmem_rdata   (dmem_rdata),
        .pc_debug     (pc_debug),
        .trap         (trap),
        .tmr_mode_pin (tmr_mode_pin),
        .fi_reg_en    (fi_reg_en),
        .fi_reg_addr  (fi_reg_addr),
        .fi_reg_bit   (fi_reg_bit),
        .fi_alu_en    (fi_alu_en),
        .fi_alu_sel   (fi_alu_sel),
        .fi_alu_bit   (fi_alu_bit),
        .ecc_sec_1    (ecc_sec_1),
        .ecc_ded_1    (ecc_ded_1),
        .ecc_sec_2    (ecc_sec_2),
        .ecc_ded_2    (ecc_ded_2),
        .tmr_mismatch (tmr_mismatch)
    );

    initial begin
        // Initialize
        rst_n = 0;
        tmr_mode_pin = 0;
        fi_reg_en = 0;
        fi_reg_addr = 0;
        fi_reg_bit = 0;
        fi_alu_en = 0;
        fi_alu_sel = 0;
        fi_alu_bit = 0;

        for (i = 0; i < MEM_DEPTH; i++) mem[i] = 32'h0000_0013;

        #20;
        rst_n = 1;
        #20;

        $display("========================================");
        $display("DEBUG 2: Fault Tolerance with Memory Capture");
        $display("========================================");

        // --------------------------------------------------------------------
        // Test A: SEC-DED with memory readback
        // --------------------------------------------------------------------
        $display("\n--- Test A: SEC-DED single-bit fault with memory readback ---");

        // Write 0xDEADBEEF to x5, then store it to memory[0]
        mem[0] = 32'hDEAD02B7; // lui x5, 0xDEAD
        mem[1] = 32'h00B08133; // addi x5, x5, 0xBEF
        mem[2] = 32'h00010223; // sw x5, 0(x0)  -- store to memory[0]
        mem[3] = 32'h00000073; // ebreak

        wait(trap);
        @(posedge clk);
        
        $display("  Initial write: memory[0]=%h (expected DEADBEEF)", mem[0]);

        // Inject fault at bit 0 of x5's codeword
        @(posedge clk);
        fi_reg_en = 1'b1;
        fi_reg_addr = 4'd5; // x5
        fi_reg_bit = 6'd0;  // bit 0
        @(posedge clk);
        fi_reg_en = 1'b0;
        
        @(posedge clk);
        #1;
        
        $display("  After bit-0 fault injection:");
        $display("    ecc_sec_1=%b, ecc_ded_1=%b", ecc_sec_1, ecc_ded_1);
        $display("    ecc_sec_2=%b, ecc_ded_2=%b", ecc_sec_2, ecc_ded_2);

        // Now read x5 back via memory to see if value changed
        mem[4] = 32'h00010223; // sw x5, 0(x0) again
        mem[5] = 32'h00000073; // ebreak
        
        wait(trap);
        @(posedge clk);
        
        $display("  After re-read: memory[0]=%h (expected DEADBEEF)", mem[0]);

        // --------------------------------------------------------------------
        // Test B: TMR with memory result capture
        // --------------------------------------------------------------------
        $display("\n--- Test B: TMR ALU fault with memory result capture ---");

        tmr_mode_pin = 1'b1; // Enable TMR

        for (i = 0; i < MEM_DEPTH; i++) mem[i] = 32'h0000_0013;

        // ADD x3, x1, x2 (5 + 10 = 15)
        mem[0] = 32'h00500113; // addi x1, x0, 5
        mem[1] = 32'h00A00213; // addi x2, x0, 10
        mem[2] = 32'h002081B3; // add x3, x1, x2
        mem[3] = 32'h00010223; // sw x3, 0(x0)
        mem[4] = 32'h00000073; // ebreak

        // Let pipeline fill, then inject fault during ADD EX stage
        @(posedge clk); @(posedge clk); @(posedge clk);
        
        $display("  Before fault: pc=%h, trap=%b", pc_debug, trap);
        
        fi_alu_en = 1'b1;
        fi_alu_sel = 2'd0; // Instance 0
        fi_alu_bit = 5'd15; // Sign bit
        @(posedge clk);
        fi_alu_en = 1'b0;
        
        @(posedge clk);
        #1;
        
        $display("  After fault injection:");
        $display("    tmr_mismatch=%b", tmr_mismatch);
        $display("    trap=%b", trap);
        
        // Wait for SW to complete and check memory
        wait(trap);
        @(posedge clk);
        
        $display("  Result in memory[0]: %h (expected 0000000F for correct ADD 5+10)", mem[0]);

        $display("\n========================================");
        $display("DEBUG 2 COMPLETE");
        $display("========================================");

        $finish;
    end

endmodule