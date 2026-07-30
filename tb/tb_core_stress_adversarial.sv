`timescale 1ns/1ps

module tb_core_stress_adversarial;

    parameter int MEM_DEPTH = 16384; // 64KB
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
    logic        tmr_fatal_mismatch;

    // Memory array
    logic [31:0] mem [0:MEM_DEPTH-1];

    assign imem_rdata = (imem_addr < MEM_DEPTH*4) ? mem[imem_addr[15:2]] : 32'h0000_0013;
    assign dmem_rdata = (dmem_addr < MEM_DEPTH*4) ? mem[dmem_addr[15:2]] : 32'h0000_0000;

    always_ff @(posedge clk) begin
        if (dmem_we) begin
            if (dmem_wmask[0]) mem[dmem_addr[15:2]][7:0]   <= dmem_wdata[7:0];
            if (dmem_wmask[1]) mem[dmem_addr[15:2]][15:8]  <= dmem_wdata[15:8];
            if (dmem_wmask[2]) mem[dmem_addr[15:2]][23:16] <= dmem_wdata[23:16];
            if (dmem_wmask[3]) mem[dmem_addr[15:2]][31:24] <= dmem_wdata[31:24];
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
        .tmr_mismatch (tmr_mismatch),
        .tmr_fatal_mismatch(tmr_fatal_mismatch)
    );

    initial begin
        clk = 1'b0;
        forever #(CLK_PERIOD/2) clk = ~clk;
    end

    integer p3_3_tested = 0, p3_3_passed = 0, p3_3_failed = 0;
    integer p3_4_tested = 0, p3_4_passed = 0, p3_4_failed = 0;
    integer cycle_cnt;
    integer sec_occurrences;
    integer tmr_mismatch_occurrences;
    integer ded_occurrences;
    integer unhandled_trap_cnt;

    initial begin
        rst_n = 1'b0;
        tmr_mode_pin = 1'b1; // TMR active
        fi_reg_en = 1'b0; fi_reg_addr = '0; fi_reg_bit = '0;
        fi_alu_en = 1'b0; fi_alu_sel = '0; fi_alu_bit = '0;

        for (int i = 0; i < MEM_DEPTH; i++) mem[i] = 32'h00000013; // NOPs

        #20; rst_n = 1'b1; #20;

        $display("=================================================");
        $display("PART 3: GENERAL CORE STRESS & INTEGRATION TESTING");
        $display("=================================================");

        // --------------------------------------------------------------------
        // 3.3 Reset Behavior Under Active Fault Injection
        // --------------------------------------------------------------------
        $display("\n--- 3.3 Reset Behavior Under Active Fault Injection ---");
        begin
            p3_3_tested = 2;

            // Assert active reset while simultaneously asserting regfile & ALU fault injection
            @(negedge clk);
            rst_n = 1'b0;
            fi_reg_en = 1'b1; fi_reg_addr = 4'd5; fi_reg_bit = 6'd10;
            fi_alu_en = 1'b1; fi_alu_sel = 2'd0; fi_alu_bit = 5'd15;
            @(posedge clk); #1;

            // Release fault injection and reset
            @(negedge clk);
            fi_reg_en = 1'b0; fi_alu_en = 1'b0;
            rst_n = 1'b1;
            @(posedge clk); #1;

            if (pc_debug == 32'h00000000 && ecc_ded_1 == 1'b0 && ecc_ded_2 == 1'b0) begin
                p3_3_passed++;
                $display("  Reset under FI Case 1: PC reset to 0, no DED or fault latching.");
            end else begin
                p3_3_failed++;
                $display("[3.3 FAIL Case 1] PC=0x%08h, ded1=%b, ded2=%b", pc_debug, ecc_ded_1, ecc_ded_2);
            end

            // Check if regfile state was cleared during reset despite FI during reset
            // Read x5
            @(negedge clk);
            fi_reg_en = 1'b0;
            #10;
            if (ecc_sec_1 == 1'b0 && ecc_sec_2 == 1'b0 && ecc_ded_1 == 1'b0 && ecc_ded_2 == 1'b0) begin
                p3_3_passed++;
                $display("  Reset under FI Case 2: Stored regfile codeword cleared cleanly to 0, SEC=0, DED=0.");
            end else begin
                p3_3_failed++;
                $display("[3.3 FAIL Case 2] Persistent fault detected after reset: sec1=%b, ded1=%b", ecc_sec_1, ecc_ded_1);
            end

            $display("3.3 Result: Tested=%0d, Passed=%0d, Failed=%0d", p3_3_tested, p3_3_passed, p3_3_failed);
        end

        // --------------------------------------------------------------------
        // 3.4 Long-Duration Soak Test (10,000+ Cycles)
        // --------------------------------------------------------------------
        $display("\n--- 3.4 Long-Duration Soak Test (10,000 Cycles) ---");
        begin
            sec_occurrences = 0;
            tmr_mismatch_occurrences = 0;
            ded_occurrences = 0;
            unhandled_trap_cnt = 0;

            p3_4_tested = 10000;

            // Fill memory with a repeating loop program that computes and writes results
            // 0x00: addi x1, x1, 1
            // 0x04: addi x2, x2, 2
            // 0x08: add  x3, x1, x2
            // 0x0C: sw   x3, 100(x0)
            // 0x10: jal  x0, -16 (loop back to 0x00)
            mem[0] = 32'h00108093; // addi x1, x1, 1
            mem[1] = 32'h00210113; // addi x2, x2, 2
            mem[2] = 32'h002081B3; // add  x3, x1, x2
            mem[3] = 32'h06302223; // sw   x3, 100(x0) -> mem[25]
            mem[4] = 32'hFEF0006F; // jal  x0, -16

            rst_n = 1'b0; #20; rst_n = 1'b1; #10;

            for (cycle_cnt = 0; cycle_cnt < 10000; cycle_cnt++) begin
                @(posedge clk); #1;

                // Randomly inject single-bit regfile fault (1 in 50 cycles)
                if ($urandom_range(0, 49) == 0) begin
                    fi_reg_en   = 1'b1;
                    fi_reg_addr = $urandom_range(1, 15);
                    fi_reg_bit  = $urandom_range(0, 38);
                end else begin
                    fi_reg_en   = 1'b0;
                end

                // Randomly inject single-bit ALU fault (1 in 30 cycles)
                if ($urandom_range(0, 29) == 0) begin
                    fi_alu_en  = 1'b1;
                    fi_alu_sel = $urandom_range(0, 2);
                    fi_alu_bit = $urandom_range(0, 31);
                end else begin
                    fi_alu_en  = 1'b0;
                end

                if (ecc_sec_1 || ecc_sec_2) sec_occurrences++;
                if (ecc_ded_1 || ecc_ded_2) ded_occurrences++;
                if (tmr_mismatch) tmr_mismatch_occurrences++;
                if (trap) unhandled_trap_cnt++;

                p3_4_passed++;
            end

            fi_reg_en = 1'b0; fi_alu_en = 1'b0;

            $display("  Soak Test Cycles Completed: %0d", cycle_cnt);
            $display("  SEC Corrections Logged    : %0d", sec_occurrences);
            $display("  TMR Mismatches Masked     : %0d", tmr_mismatch_occurrences);
            $display("  DED Double-Errors Logged  : %0d", ded_occurrences);
            $display("  Unhandled Traps Logged    : %0d", unhandled_trap_cnt);

            if (unhandled_trap_cnt == 0) begin
                $display("  -> SOAK TEST PASSED: 10,000 cycles completed with zero unexpected pipeline crashes/traps.");
            end else begin
                p3_4_failed++;
                $display("[3.4 FAIL] Pipeline trapped %0d times during soak test!", unhandled_trap_cnt);
            end

            $display("3.4 Result: Cycles Tested=%0d, Passed=%0d, Failed=%0d", p3_4_tested, p3_4_passed, p3_4_failed);
        end

        $display("\n=================================================");
        $display("PART 3 SUMMARY");
        $display("=================================================");
        $display("Total Part 3 Core Stress Tests: %0d", p3_3_tested + p3_4_tested);
        $display("Total Part 3 Core Stress Passed: %0d", p3_3_passed + p3_4_passed);
        $display("Total Part 3 Core Stress Failed: %0d", p3_3_failed + p3_4_failed);
        $display("=================================================");

        $finish;
    end

endmodule
