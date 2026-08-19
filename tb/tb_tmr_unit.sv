// ============================================================================
// Project 2: tb_tmr_unit.sv
// Standalone isolated testbench for tmr_voter.sv + 3x alu.sv
// ============================================================================

`timescale 1ns/1ps

module tb_tmr_unit;

    parameter int DATA_WIDTH = 32;
    parameter time CLK_PERIOD = 10;

    logic clk;
    logic rst_n;

    // ALU command inputs
    logic [DATA_WIDTH-1:0] alu_in_a;
    logic [DATA_WIDTH-1:0] alu_in_b;
    logic [3:0]            alu_op;

    // TMR mode
    logic                  tmr_mode;

    // Fault injection
    logic                  fi_alu_en;
    logic [1:0]            fi_alu_sel;
    logic [4:0]            fi_alu_bit;

    // Raw ALU outputs
    logic [DATA_WIDTH-1:0] alu_result_0;
    logic [DATA_WIDTH-1:0] alu_result_1;
    logic [DATA_WIDTH-1:0] alu_result_2;

    // Voter outputs
    logic [DATA_WIDTH-1:0] voter_result;
    logic                  voter_mismatch;

    // Internal corrupted signals (exact wiring from id_ex_stage.sv)
    logic [DATA_WIDTH-1:0] alu_in_a_tmr;
    logic [DATA_WIDTH-1:0] alu_in_b_tmr;
    logic [DATA_WIDTH-1:0] fi_mask;
    logic [DATA_WIDTH-1:0] alu_result_0_fi;
    logic [DATA_WIDTH-1:0] alu_result_1_fi;
    logic [DATA_WIDTH-1:0] alu_result_2_fi;

    // DUT: three ALU instances
    alu #(.DATA_WIDTH(DATA_WIDTH)) u_alu_0 (
        .a      (alu_in_a),
        .b      (alu_in_b),
        .alu_op (alu_op),
        .result (alu_result_0),
        .zero   ()
    );

    alu #(.DATA_WIDTH(DATA_WIDTH)) u_alu_1 (
        .a      (alu_in_a_tmr),
        .b      (alu_in_b_tmr),
        .alu_op (alu_op),
        .result (alu_result_1),
        .zero   ()
    );

    alu #(.DATA_WIDTH(DATA_WIDTH)) u_alu_2 (
        .a      (alu_in_a_tmr),
        .b      (alu_in_b_tmr),
        .alu_op (alu_op),
        .result (alu_result_2),
        .zero   ()
    );

    // Fault injection masks (exact wiring from id_ex_stage.sv)
    assign fi_mask = (fi_alu_en) ? (32'd1 << fi_alu_bit) : '0;
    assign alu_result_0_fi = alu_result_0 ^ ((fi_alu_sel == 2'd0) ? fi_mask : '0);
    assign alu_result_1_fi = alu_result_1 ^ ((fi_alu_sel == 2'd1) ? fi_mask : '0);
    assign alu_result_2_fi = alu_result_2 ^ ((fi_alu_sel == 2'd2) ? fi_mask : '0);

    // Operand isolation for TMR mode
    assign alu_in_a_tmr = (tmr_mode) ? alu_in_a : '0;
    assign alu_in_b_tmr = (tmr_mode) ? alu_in_b : '0;

    // TMR Voter
    tmr_voter #(.WIDTH(DATA_WIDTH)) u_tmr_voter (
        .a               (alu_result_0_fi),
        .b               (alu_result_1_fi),
        .c               (alu_result_2_fi),
        .result          (voter_result),
        .mismatch_detected (voter_mismatch),
        .tmr_fatal_mismatch ()
    );

    // Clock
    initial begin
        clk = 0;
        forever #(CLK_PERIOD/2) clk = ~clk;
    end

    // Waveform dump
    initial begin
        $dumpfile("tb_tmr_unit.vcd");
        $dumpvars(0, tb_tmr_unit);
    end

    integer test_count;
    integer pass_count;
    integer fail_count;
    integer k;

    initial begin
        test_count = 0;
        pass_count = 0;
        fail_count = 0;

        rst_n = 0;
        alu_in_a = 0;
        alu_in_b = 0;
        alu_op = 4'b0000;
        tmr_mode = 0;
        fi_alu_en = 0;
        fi_alu_sel = 0;
        fi_alu_bit = 0;

        #20;
        rst_n = 1;
        #10;
        @(posedge clk);

        $display("========================================");
        $display("UNIT TEST: tmr_voter + alu TMR logic");
        $display("========================================");

        // ====================================================================
        // Test 1: Baseline, TMR mode, no fault
        // ====================================================================
        $display("\n--- Test 1: TMR baseline, no fault ---");
        test_count = test_count + 1;

        tmr_mode = 1'b1;
        alu_in_a = 32'd5;
        alu_in_b = 32'd10;
        alu_op   = 4'b0000; // ADD

        @(posedge clk);
        #1;

        $display("  ADD 5 + 10:");
        $display("    alu_result_0 = 0x%h", alu_result_0);
        $display("    alu_result_1 = 0x%h", alu_result_1);
        $display("    alu_result_2 = 0x%h", alu_result_2);
        $display("    voter_result = 0x%h", voter_result);
        $display("    tmr_mismatch = %b", voter_mismatch);

        if (alu_result_0 == 32'd15 && alu_result_1 == 32'd15 && alu_result_2 == 32'd15 &&
            voter_result == 32'd15 && voter_mismatch == 1'b0) begin
            $display("  PASS");
            pass_count = pass_count + 1;
        end else begin
            $display("  FAIL");
            fail_count = fail_count + 1;
        end

        // ====================================================================
        // Test 2: Corrupt instance 0, check mismatch
        // ====================================================================
        $display("\n--- Test 2: Corrupt instance 0 ---");

        tmr_mode = 1'b1;
        alu_in_a = 32'd5;
        alu_in_b = 32'd10;
        alu_op   = 4'b0000;

        // Issue operation and assert fault injection BEFORE posedge so it is active on this cycle
        fi_alu_en  = 1'b1;
        fi_alu_sel = 2'd0;
        fi_alu_bit = 5'd15;

        @(posedge clk);
        #1;

        $display("  With fault active (instance 0, bit 15):");
        $display("    fi_alu_en      = %b", fi_alu_en);
        $display("    fi_mask        = 0x%h", fi_mask);
        $display("    alu_result_0   = 0x%h (raw)", alu_result_0);
        $display("    alu_result_0_fi= 0x%h (corrupted)", alu_result_0_fi);
        $display("    alu_result_1_fi= 0x%h", alu_result_1_fi);
        $display("    alu_result_2_fi= 0x%h", alu_result_2_fi);
        $display("    voter_result   = 0x%h", voter_result);
        $display("    tmr_mismatch   = %b", voter_mismatch);

        test_count = test_count + 1;
        if (alu_result_0_fi == 32'd15 + 32'h00008000 && alu_result_1_fi == 32'd15 && alu_result_2_fi == 32'd15 &&
            voter_result == 32'd15 && voter_mismatch == 1'b1) begin
            $display("  PASS");
            pass_count = pass_count + 1;
        end else begin
            $display("  FAIL");
            fail_count = fail_count + 1;
        end

        // Deassert fault on next cycle
        fi_alu_en = 1'b0;
        @(posedge clk);
        #1;
        $display("  After deassert: tmr_mismatch=%b (expected 0)", voter_mismatch);

        // ====================================================================
        // Test 3: Corrupt instance 1
        // ====================================================================
        $display("\n--- Test 3: Corrupt instance 1 ---");

        fi_alu_en  = 1'b1;
        fi_alu_sel = 2'd1;
        fi_alu_bit = 5'd7;

        @(posedge clk);
        #1;

        $display("  With fault active (instance 1, bit 7):");
        $display("    fi_alu_en      = %b", fi_alu_en);
        $display("    fi_mask        = 0x%h", fi_mask);
        $display("    alu_result_0_fi= 0x%h", alu_result_0_fi);
        $display("    alu_result_1   = 0x%h (raw)", alu_result_1);
        $display("    alu_result_1_fi= 0x%h (corrupted)", alu_result_1_fi);
        $display("    alu_result_2_fi= 0x%h", alu_result_2_fi);
        $display("    voter_result   = 0x%h", voter_result);
        $display("    tmr_mismatch   = %b", voter_mismatch);

        test_count = test_count + 1;
        if (alu_result_0_fi == 32'd15 && alu_result_1_fi == 32'd15 + 32'h00000080 && alu_result_2_fi == 32'd15 &&
            voter_result == 32'd15 && voter_mismatch == 1'b1) begin
            $display("  PASS");
            pass_count = pass_count + 1;
        end else begin
            $display("  FAIL");
            fail_count = fail_count + 1;
        end

        fi_alu_en = 1'b0;
        @(posedge clk);
        #1;
        $display("  After deassert: tmr_mismatch=%b (expected 0)", voter_mismatch);

        // ====================================================================
        // Test 4: Corrupt instance 2
        // ====================================================================
        $display("\n--- Test 4: Corrupt instance 2 ---");

        fi_alu_en  = 1'b1;
        fi_alu_sel = 2'd2;
        fi_alu_bit = 5'd0;

        @(posedge clk);
        #1;

        $display("  With fault active (instance 2, bit 0):");
        $display("    fi_alu_en      = %b", fi_alu_en);
        $display("    fi_mask        = 0x%h", fi_mask);
        $display("    alu_result_0_fi= 0x%h", alu_result_0_fi);
        $display("    alu_result_1_fi= 0x%h", alu_result_1_fi);
        $display("    alu_result_2   = 0x%h (raw)", alu_result_2);
        $display("    alu_result_2_fi= 0x%h (corrupted)", alu_result_2_fi);
        $display("    voter_result   = 0x%h", voter_result);
        $display("    tmr_mismatch   = %b", voter_mismatch);

        test_count = test_count + 1;
        if (alu_result_0_fi == 32'd15 && alu_result_1_fi == 32'd15 && alu_result_2_fi == (32'd15 ^ 32'h00000001) &&
            voter_result == 32'd15 && voter_mismatch == 1'b1) begin
            $display("  PASS");
            pass_count = pass_count + 1;
        end else begin
            $display("  FAIL");
            fail_count = fail_count + 1;
        end

        fi_alu_en = 1'b0;
        @(posedge clk);
        #1;
        $display("  After deassert: tmr_mismatch=%b (expected 0)", voter_mismatch);

        // ====================================================================
        // Summary
        // ====================================================================
        $display("\n========================================");
        $display("RESULTS");
        $display("========================================");
        $display("Total:  %0d", test_count);
        $display("Passed: %0d", pass_count);
        $display("Failed: %0d", fail_count);
        $display("========================================");

        $finish;
    end

endmodule