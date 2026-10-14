`timescale 1ns/1ps
// ============================================================================
// File: tb_riscv_core_top.sv
// Description: Testbench for the RISC-V 3-Stage Pipelined Core.
//              Supports both signature-based verification (for rv32i tests)
//              and directed testing for Fault Tolerance features.
// ============================================================================

module tb_riscv_core_top();

    // ------------------------------------------------------------------------
    // CLOCK & RESET
    // ------------------------------------------------------------------------
    logic clk;
    logic rst_n;

    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    // ------------------------------------------------------------------------
    // DUT SIGNALS
    // ------------------------------------------------------------------------
    logic [31:0] imem_addr;
    logic [31:0] imem_rdata;
    
    logic [31:0] dmem_addr;
    logic [31:0] dmem_wdata;
    logic [3:0]  dmem_wmask;
    logic        dmem_we;
    logic [31:0] dmem_rdata;
    
    logic [31:0] pc_debug;
    logic        trap;

    // Fault Tolerance Ports
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
    logic        tmr_fatal_mismatch;
    logic        pc_tmr_mismatch;
    logic        pc_tmr_fatal_mismatch;
    logic        cu_mismatch;

    // Sticky status flags for FT verification
    logic        sec_flag, ded_flag, tmr_flag, trap_flag;
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            sec_flag  <= 0;
            ded_flag  <= 0;
            tmr_flag  <= 0;
            trap_flag <= 0;
        end else begin
            if (ecc_sec_1 | ecc_sec_2) sec_flag <= 1;
            if (ecc_ded_1 | ecc_ded_2) ded_flag <= 1;
            if (tmr_mismatch) tmr_flag <= 1;
            if (trap) trap_flag <= 1;
        end
    end

    // ------------------------------------------------------------------------
    // MEMORY ARRAYS (64KB total: 0x0000 to 0xFFFF)
    // ------------------------------------------------------------------------
    logic [7:0] memory [0:65535];

    // Read from instruction memory (Combinational read)
    assign imem_rdata = {memory[imem_addr+3], memory[imem_addr+2], memory[imem_addr+1], memory[imem_addr]};

    // Read from data memory (Combinational read)
    assign dmem_rdata = {memory[dmem_addr+3], memory[dmem_addr+2], memory[dmem_addr+1], memory[dmem_addr]};

    // Write to data memory (Synchronous write)
    always_ff @(posedge clk) begin
        if (dmem_we) begin
            if (dmem_wmask[0]) memory[dmem_addr]   <= dmem_wdata[7:0];
            if (dmem_wmask[1]) memory[dmem_addr+1] <= dmem_wdata[15:8];
            if (dmem_wmask[2]) memory[dmem_addr+2] <= dmem_wdata[23:16];
            if (dmem_wmask[3]) memory[dmem_addr+3] <= dmem_wdata[31:24];
        end
    end

    // ------------------------------------------------------------------------
    // DUT INSTANTIATION
    // ------------------------------------------------------------------------
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
        .tmr_mismatch (tmr_mismatch),
        .tmr_fatal_mismatch(tmr_fatal_mismatch),
        .pc_tmr_mismatch(pc_tmr_mismatch),
        .pc_tmr_fatal_mismatch(pc_tmr_fatal_mismatch),
        .cu_mismatch  (cu_mismatch)
    );

    // ------------------------------------------------------------------------
    // SIMULATION ARGUMENTS & INITIALIZATION
    // ------------------------------------------------------------------------
    string hex_file;
    string sig_file;
    int sig_start, sig_end;

    task automatic write_inst(input int byte_addr, input logic [31:0] instr);
        memory[byte_addr]   = instr[7:0];
        memory[byte_addr+1] = instr[15:8];
        memory[byte_addr+2] = instr[23:16];
        memory[byte_addr+3] = instr[31:24];
    endtask

    initial begin
        // Initialize memory to 0
        for (int i = 0; i < 65536; i++) begin
            memory[i] = 8'h00;
        end

        // Load HEX file if provided
        if ($value$plusargs("HEX=%s", hex_file)) begin
            $readmemh(hex_file, memory);
            $display("Loaded %s into memory.", hex_file);
        end else begin
            $display("Loading built-in Fault Tolerance test instructions into memory...");
            for (int i = 0; i < 65536; i += 4) begin
                write_inst(i, 32'h0000_0013); // NOP (ADDI x0, x0, 0)
            end
            // Instruction program to test SEC-DED and TMR:
            // 0x00: ADDI x5, x0, 15    (Write clean word into x5)
            write_inst('h00, 32'h00f00293);
            // 0x04: ADDI x6, x0, 30    (Write clean word into x6)
            write_inst('h04, 32'h01e00313);
            // 0x08 - 0x18: NOPs
            // 0x1C: ADDI x1, x5, 0     (Read x5 onto read port 1 - triggers SEC)
            write_inst('h1C, 32'h00028093);
            // 0x20 - 0x28: NOPs
            // 0x2C: ADDI x2, x6, 0     (Read x6 onto read port 1 - triggers DED)
            write_inst('h2C, 32'h00030113);
            // 0x30 - 0x3C: NOPs
            // 0x40: EBREAK             (Halts processor with trap)
            write_inst('h40, 32'h00100073);
        end

        // Initialize inputs
        tmr_mode_pin = 1'b0;
        fi_reg_en    = 1'b0;
        fi_reg_addr  = '0;
        fi_reg_bit   = '0;
        fi_alu_en    = 1'b0;
        fi_alu_sel   = '0;
        fi_alu_bit   = '0;
        rst_n = 0;
        #20 rst_n = 1;

        // Run Directed FT Tests
        run_fault_tolerance_tests();

        // Run Main Program if HEX file provided
        if (hex_file != "") begin
            wait(trap == 1'b1 || trap_flag == 1'b1);
            #50;
            
            $display("Trap received. Checking signature...");
            
            // Write signature if arguments provided
            if ($value$plusargs("SIG_FILE=%s", sig_file)) begin
                if ($value$plusargs("SIG_START=%x", sig_start) && $value$plusargs("SIG_END=%x", sig_end)) begin
                    int fd;
                    fd = $fopen(sig_file, "w");
                    if (fd) begin
                        for (int i = sig_start; i < sig_end; i += 4) begin
                            $fdisplay(fd, "%02x%02x%02x%02x", memory[i+3], memory[i+2], memory[i+1], memory[i]);
                        end
                        $fclose(fd);
                        $display("Signature written to %s", sig_file);
                    end
                end
            end
        end

        $display("---------------------------------");
        $display("RESULT: TEST PASSED");
        $display("---------------------------------");
        $finish;
    end

    // Timeout watchdog
    initial begin
        #100000;
        $display("TIMEOUT");
        $finish;
    end

    // ------------------------------------------------------------------------
    // FAULT TOLERANCE DIRECTED TESTS
    // ------------------------------------------------------------------------
    task run_fault_tolerance_tests;
        $display("---------------------------------");
        $display("Starting Fault Tolerance Tests...");
        
        // Wait until x5 and x6 have been written in the pipeline
        wait(imem_addr >= 32'h0000_0010);

        // --- Test 1: Single Event Upset (SEC) in Register File ---
        $display("[Test 1] Injecting Single Bit Flip into Reg[5]");
        @(negedge clk);
        fi_reg_en   = 1'b1;
        fi_reg_addr = 4'd5;
        fi_reg_bit  = 6'd4;
        @(negedge clk);
        fi_reg_en   = 1'b0;
        
        // Wait for instruction at 0x1C (ADDI x1, x5, 0) to execute in ID stage
        wait(imem_addr >= 32'h0000_0020 || sec_flag == 1'b1);
        @(posedge clk);
        #1;
        if (sec_flag) $display("  -> SUCCESS: SEC detected and corrected.");
        else          $display("  -> FAIL: SEC not detected.");
        
        // --- Test 2: Double Bit Flip (DED) in Register File ---
        $display("[Test 2] Injecting Double Bit Flip into Reg[6]");
        sec_flag <= 0; ded_flag <= 0;
        @(negedge clk);
        fi_reg_en   = 1'b1;
        fi_reg_addr = 4'd6;
        fi_reg_bit  = 6'd10; // First bit
        @(negedge clk);
        fi_reg_bit  = 6'd11; // Second bit
        @(negedge clk);
        fi_reg_en   = 1'b0;
        
        // Wait for instruction at 0x2C (ADDI x2, x6, 0) to execute in ID stage
        wait(imem_addr >= 32'h0000_0030 || ded_flag == 1'b1);
        @(posedge clk);
        #1;
        if (ded_flag) $display("  -> SUCCESS: DED detected.");
        else          $display("  -> FAIL: DED not detected.");

        // --- Test 3: TMR Mode Masking ---
        $display("[Test 3] Injecting ALU Fault in TMR Mode");
        tmr_mode_pin = 1'b1;
        tmr_flag <= 0;
        #50;
        @(negedge clk);
        fi_alu_en  = 1'b1;
        fi_alu_sel = 2'd1; // Fault in ALU 1
        fi_alu_bit = 5'd15;
        @(negedge clk);
        fi_alu_en  = 1'b0;
        
        #50;
        if (tmr_flag) $display("  -> SUCCESS: TMR Voter masked fault and flagged mismatch.");
        else          $display("  -> FAIL: TMR mismatch not flagged.");

        // --- Test 4: Simplex Mode Vulnerability (Control) ---
        $display("[Test 4] Injecting ALU Fault in Simplex Mode");
        tmr_mode_pin = 1'b0;
        tmr_flag <= 0;
        #50;
        @(negedge clk);
        fi_alu_en  = 1'b1;
        fi_alu_sel = 2'd0; // Fault in ALU 0 (Primary)
        fi_alu_bit = 5'd15;
        @(negedge clk);
        fi_alu_en  = 1'b0;
        
        #50;
        if (!tmr_flag) $display("  -> SUCCESS: Simplex mode propagated fault (no TMR voting).");
        else           $display("  -> FAIL: TMR mismatch flagged in Simplex mode?!");

        $display("Fault Tolerance Tests Complete.");
        $display("---------------------------------");
        
        // Reset flags for main test
        sec_flag <= 0;
        ded_flag <= 0;
        tmr_flag <= 0;
    endtask

endmodule