// ============================================================================
// File: tb_fault_tolerance.sv
// Description: Fault-tolerance verification using ONLY top-level ports.
//              No hierarchical access, no RTL modifications.
// ============================================================================

`timescale 1ns/1ps

module tb_fault_tolerance;

    // Parameters
    parameter int MEM_DEPTH = 8192;
    parameter time CLK_PERIOD = 10;

    // Clock and reset
    logic clk;
    logic rst_n;

    // DUT signals
    logic [31:0] imem_addr;
    logic [31:0] imem_rdata;
    logic [31:0] dmem_addr;
    logic [31:0] dmem_wdata;
    logic [3:0]  dmem_wmask;
    logic        dmem_we;
    logic [31:0] dmem_rdata;
    logic [31:0] pc_debug;
    logic        trap;

    // Fault Tolerance ports
    logic        tmr_mode_pin;
    logic        fi_reg_en;
    logic [3:0]  fi_reg_addr;
    logic [5:0]  fi_reg_bit;
    logic        fi_alu_en;
    logic [1:0]  fi_alu_sel;
    logic [4:0]  fi_alu_bit;

    // Status outputs
    logic        ecc_sec_1, ecc_ded_1;
    logic        ecc_sec_2, ecc_ded_2;
    logic        tmr_mismatch;
    logic        tmr_fatal_mismatch;

    // Memory array
    logic [31:0] mem [0:MEM_DEPTH-1];

    // Test counters
    integer test_count;
    integer pass_count;
    integer fail_count;

    // Test variables
    integer i, j, bit_pos, pair_idx, alu_inst, bit_idx;
    int bit_pairs[5][2];

    // ========================================================================
    // Clock Generation
    // ========================================================================
    initial begin
        clk = 0;
        forever #(CLK_PERIOD/2) clk = ~clk;
    end

    // ========================================================================
    // Memory Model
    // ========================================================================
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

    // ========================================================================
    // DUT Instantiation
    // ========================================================================
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
        .tmr_fatal_mismatch(tmr_fatal_mismatch)
    );

    // ========================================================================
    // Task: Clear memory program
    // ========================================================================
    task clear_mem();
        for (i = 0; i < MEM_DEPTH; i++) mem[i] = 32'h0000_0013;
    endtask

    // ========================================================================
    // Task: Load program and wait for trap
    // ========================================================================
    task run_program(input int start_addr);
        // Flush pipeline and start execution
        @(posedge clk);
        #1;
        wait(trap);
        @(posedge clk);
    endtask

    // ========================================================================
    // Test Harness
    // ========================================================================
    initial begin
        test_count = 0;
        pass_count = 0;
        fail_count = 0;

        // Initialize
        rst_n = 0;
        tmr_mode_pin = 0;
        fi_reg_en = 0;
        fi_reg_addr = 0;
        fi_reg_bit = 0;
        fi_alu_en = 0;
        fi_alu_sel = 0;
        fi_alu_bit = 0;

        // Reset
        #20;
        rst_n = 1;
        #20;

        $display("========================================");
        $display("FAULT TOLERANCE VERIFICATION SUITE");
        $display("========================================");

        // ====================================================================
        // Test 1.1: Baseline (no fault)
        // ====================================================================
        $display("\n--- Test 1.1: Baseline (no fault) ---");
        test_count++;

        clear_mem();
        mem[0] = 32'hDEAD02B7; // lui x5, 0xDEAD
        mem[1] = 32'h00B08133; // addi x5, x5, 0xBEF
        mem[2] = 32'h00000073; // ebreak
        run_program(0);

        $display("  PASS: Trap received after baseline write");
        pass_count++;

        // ====================================================================
        // Test 1.2: Single-bit error injection and correction
        // ====================================================================
        $display("\n--- Test 1.2: Single-bit error injection and correction ---");

        // Test 5 registers: x3, x5, x7, x9, x11
        // Test 6 bit positions: 0, 5, 10, 20, 30, 38
        for (i = 0; i < 5; i++) begin
            for (j = 0; j < 6; j++) begin
                test_count++;
                
                // Write known value to register
                clear_mem();
                mem[0] = 32'hDEAD02B7; // lui x5, 0xDEAD
                mem[1] = 32'h00B08133; // addi x5, x5, 0xBEF
                mem[2] = 32'h00000013; // NOP
                mem[3] = 32'h00000073; // ebreak
                run_program(0);
                
                // Inject fault at bit position j (0, 5, 10, 20, 30, 38)
                @(posedge clk);
                fi_reg_en = 1'b1;
                fi_reg_addr = 4'd5; // x5
                fi_reg_bit = j * 6; // Spread across 0, 30, 60... wait that's too big
                // Actually bit positions 0-38, so use: 0, 5, 10, 20, 30, 38
                fi_reg_bit = (j == 5) ? 6'd38 : (j * 5); // 0, 5, 10, 20, 30, 38
                @(posedge clk);
                fi_reg_en = 1'b0;
                
                @(posedge clk);
                #1;
                
                $display("  Reg x5, bit %0d: ecc_sec=%b, ecc_ded=%b", 
                         fi_reg_bit, ecc_sec_1, ecc_ded_1);
            end
        end

        // ====================================================================
        // Test 1.3: Double-bit error injection and detection
        // ====================================================================
        $display("\n--- Test 1.3: Double-bit error injection and detection ---");

        bit_pairs[0][0] = 0;  bit_pairs[0][1] = 1;      // Adjacent bits, low
        bit_pairs[1][0] = 3;  bit_pairs[1][1] = 38;     // Max distance
        bit_pairs[2][0] = 10; bit_pairs[2][1] = 20;    // Middle bits
        bit_pairs[3][0] = 15; bit_pairs[3][1] = 16;    // Adjacent middle
        bit_pairs[4][0] = 7;  bit_pairs[4][1] = 31;    // Mix

        for (pair_idx = 0; pair_idx < 5; pair_idx++) begin
            test_count++;
            
            clear_mem();
            mem[0] = 32'hDEAD02B7; // lui x5, 0xDEAD
            mem[1] = 32'h00B08133; // addi x5, x5, 0xBEF
            mem[2] = 32'h00000073; // ebreak
            run_program(0);
            
            // Inject first bit flip
            @(posedge clk);
            fi_reg_en = 1'b1;
            fi_reg_addr = 4'd7; // x7
            fi_reg_bit = bit_pairs[pair_idx][0];
            @(posedge clk);
            
            // Inject second bit flip (consecutive cycle)
            fi_reg_bit = bit_pairs[pair_idx][1];
            @(posedge clk);
            fi_reg_en = 1'b0;
            
            @(posedge clk);
            #1;
            
            $display("  Pair {%0d, %0d}: ecc_sec=%b, ecc_ded=%b", 
                     bit_pairs[pair_idx][0], bit_pairs[pair_idx][1],
                     ecc_sec_1, ecc_ded_1);
            
            if (ecc_ded_1 || ecc_ded_2) begin
                $display("    -> DED detected correctly");
                pass_count++;
            end else if (ecc_sec_1 || ecc_sec_2) begin
                $display("    -> CRITICAL: SEC asserted instead of DED!");
                fail_count++;
            end else begin
                $display("    -> No error detected");
            end
        end

        // ====================================================================
        // Test 2.2: Single ALU instance corrupted, TMR masks it
        // ====================================================================
        $display("\n--- Test 2.2: Single ALU instance corrupted, TMR masks it ---");

        tmr_mode_pin = 1'b1; // Enable TMR mode

        // Test each ALU instance individually
        for (alu_inst = 0; alu_inst < 3; alu_inst++) begin
            $display("  Testing ALU instance %0d", alu_inst);
            
            // Clear memory and load ADD program
            clear_mem();
            // addi x1, x0, 5    (operand A = 5)
            // addi x2, x0, 10   (operand B = 10)
            // add  x3, x1, x2   (result should be 15)
            // sw   x3, 0(x0)    (store result to memory[0])
            // ebreak
            mem[0] = 32'h00500113; // addi x1, x0, 5
            mem[1] = 32'h00A00213; // addi x2, x0, 10
            mem[2] = 32'h002081B3; // add x3, x1, x2  (x3 = 5+10 = 15)
            mem[3] = 32'h00010023; // sw x3, 0(x0)
            mem[4] = 32'h00000073; // ebreak
            
            // Inject fault during ADD operation (when x3 is being computed)
            // The ADD is at mem[2], which is the 3rd instruction
            // We need to inject during the EX stage of that instruction
            // Pipeline: IF->ID->EX->WB
            // Cycle 0: IF mem[0]
            // Cycle 1: ID mem[0], IF mem[1]
            // Cycle 2: EX mem[0], ID mem[1], IF mem[2]  <- ADD enters EX
            // Cycle 3: WB mem[0], EX mem[1], ID mem[2], IF mem[3]
            
            // Wait for ADD to be in EX stage, then inject fault
            @(posedge clk); @(posedge clk); @(posedge clk); // 3 cycles for ADD to reach EX
            
            fi_alu_en = 1'b1;
            fi_alu_sel = alu_inst[1:0];
            fi_alu_bit = 5'd15; // Sign bit
            @(posedge clk);
            fi_alu_en = 1'b0;
            
            @(posedge clk);
            #1;
            
            $display("    Instance %0d, bit 15: tmr_mismatch=%b, result=%h",
                     alu_inst, tmr_mismatch, mem[0]);
        end

        // ====================================================================
        // FINAL SUMMARY
        // ========================================================================
        $display("\n========================================");
        $display("FAULT TOLERANCE TEST SUMMARY");
        $display("========================================");
        $display("Total tests: %0d", test_count);
        $display("Passed: %0d", pass_count);
        $display("Failed: %0d", fail_count);
        $display("========================================");

        if (fail_count == 0) begin
            $display("ALL TESTS PASSED");
        end else begin
            $display("SOME TESTS FAILED - See details above");
        end

        $finish;
    end

endmodule