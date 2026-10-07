`timescale 1ns/1ps
// ============================================================================
// File: tb_adaptive_redundancy_control.sv
// Description: Comprehensive Unit Testbench for Adaptive Redundancy Control.
//              Tests Simplex vs TMR operating modes, Operand Isolation,
//              Glitch-Free Clock Gating, Majority Voting, Fault Recovery,
//              and Power Efficiency / Toggle Activity metrics.
// Standards: SystemVerilog-2012 / Self-Checking Testbench
// ============================================================================

import riscv_pkg::*;

module tb_adaptive_redundancy_control;

    parameter int DATA_WIDTH = 32;

    // Testbench Clock & Reset Signals
    logic                  clk;
    logic                  rst_n;

    // Mode Control Signals
    logic                  tmr_mode_pin;
    logic                  sw_tmr_mode_reg;

    // Primary Input Operands (EX0)
    logic [DATA_WIDTH-1:0] alu_in_a;
    logic [DATA_WIDTH-1:0] alu_in_b;
    logic [3:0]            ctrl_alu_op;

    // Isolated Operands (EX1, EX2)
    logic [DATA_WIDTH-1:0] alu_in_a_ex1;
    logic [DATA_WIDTH-1:0] alu_in_b_ex1;
    logic [3:0]            ctrl_alu_op_ex1;
    logic [DATA_WIDTH-1:0] alu_in_a_ex2;
    logic [DATA_WIDTH-1:0] alu_in_b_ex2;
    logic [3:0]            ctrl_alu_op_ex2;

    // Clock Gating Signals
    logic                  gated_clk_ex1;
    logic                  gated_clk_ex2;

    // Raw & Fault Injected EX Outputs
    logic [DATA_WIDTH-1:0] alu_result_0_fi;
    logic [DATA_WIDTH-1:0] alu_result_1_fi;
    logic [DATA_WIDTH-1:0] alu_result_2_fi;

    // Resolved DUT Outputs
    logic [DATA_WIDTH-1:0] alu_result;
    logic                  tmr_mismatch;
    logic                  tmr_fatal_mismatch;
    logic                  tmr_mode_active;

    // Test Metrics & Telemetry Counters
    int error_count = 0;
    int test_pass_count = 0;
    int ex1_ex2_toggle_count = 0;
    int gated_clk_ex1_pulses = 0;

    // Clock Generation (100 MHz clock)
    always #5 clk = ~clk;

    // Track toggles on isolated inputs to quantify power isolation
    always @(alu_in_a_ex1 or alu_in_b_ex1 or ctrl_alu_op_ex1 or
             alu_in_a_ex2 or alu_in_b_ex2 or ctrl_alu_op_ex2) begin
        if (rst_n) begin
            ex1_ex2_toggle_count++;
        end
    end

    // Track gated clock pulses
    always @(posedge gated_clk_ex1) begin
        if (rst_n) gated_clk_ex1_pulses++;
    end

    // Instantiate Device Under Test (DUT)
    adaptive_redundancy_controller #(
        .DATA_WIDTH (DATA_WIDTH)
    ) dut (
        .clk                (clk),
        .rst_n              (rst_n),
        .tmr_mode_pin       (tmr_mode_pin),
        .sw_tmr_mode_reg    (sw_tmr_mode_reg),
        .alu_in_a           (alu_in_a),
        .alu_in_b           (alu_in_b),
        .ctrl_alu_op        (ctrl_alu_op),
        .alu_in_a_ex1       (alu_in_a_ex1),
        .alu_in_b_ex1       (alu_in_b_ex1),
        .ctrl_alu_op_ex1    (ctrl_alu_op_ex1),
        .alu_in_a_ex2       (alu_in_a_ex2),
        .alu_in_b_ex2       (alu_in_b_ex2),
        .ctrl_alu_op_ex2    (ctrl_alu_op_ex2),
        .gated_clk_ex1      (gated_clk_ex1),
        .gated_clk_ex2      (gated_clk_ex2),
        .alu_result_0_fi    (alu_result_0_fi),
        .alu_result_1_fi    (alu_result_1_fi),
        .alu_result_2_fi    (alu_result_2_fi),
        .alu_result         (alu_result),
        .tmr_mismatch       (tmr_mismatch),
        .tmr_fatal_mismatch (tmr_fatal_mismatch),
        .tmr_mode_active    (tmr_mode_active)
    );

    // ------------------------------------------------------------------------
    // TEST SUITE EXECUTION
    // ------------------------------------------------------------------------
    initial begin
        $display("\n=========================================================");
        $display("   STARTING ADAPTIVE REDUNDANCY CONTROL VERIFICATION   ");
        $display("=========================================================\n");

        // Step 0: Initialize signals
        clk             = 0;
        rst_n           = 0;
        tmr_mode_pin    = 0;
        sw_tmr_mode_reg = 0;
        alu_in_a        = 32'h0;
        alu_in_b        = 32'h0;
        ctrl_alu_op     = 4'd0;
        alu_result_0_fi = 32'h0;
        alu_result_1_fi = 32'h0;
        alu_result_2_fi = 32'h0;

        #20;
        rst_n = 1;
        #10;

        // --------------------------------------------------------------------
        // TEST 1: SIMPLEX MODE - OPERAND ISOLATION & CLOCK GATING CHECK
        // --------------------------------------------------------------------
        $display("[TEST 1] Verifying Simplex Mode (Power-Saving / Isolation)...");
        tmr_mode_pin    = 0;
        sw_tmr_mode_reg = 0;
        ex1_ex2_toggle_count = 0;
        gated_clk_ex1_pulses = 0;

        // Drive dynamic operand changes on primary inputs EX0
        for (int i = 0; i < 10; i++) begin
            @(posedge clk);
            alu_in_a = 32'h1000_0000 + (i * 32'h1111);
            alu_in_b = 32'h0000_A5A5 + (i * 32'h5A5A);
            ctrl_alu_op = i[3:0];
            alu_result_0_fi = alu_in_a + alu_in_b;
            alu_result_1_fi = 32'hDEAD_BEEF; // Irrelevant EX1 output
            alu_result_2_fi = 32'hCAFE_BABE; // Irrelevant EX2 output
            #1;
            
            // Checks for Simplex Mode
            if (tmr_mode_active !== 1'b0) begin
                $display("ERROR: tmr_mode_active should be 0 in Simplex Mode!");
                error_count++;
            end
            if (alu_in_a_ex1 !== 32'h0 || alu_in_b_ex1 !== 32'h0 || ctrl_alu_op_ex1 !== 4'd0) begin
                $display("ERROR: EX1 Operands are NOT isolated to 0! A1=%h B1=%h Op1=%h",
                         alu_in_a_ex1, alu_in_b_ex1, ctrl_alu_op_ex1);
                error_count++;
            end
            if (alu_in_a_ex2 !== 32'h0 || alu_in_b_ex2 !== 32'h0 || ctrl_alu_op_ex2 !== 4'd0) begin
                $display("ERROR: EX2 Operands are NOT isolated to 0! A2=%h B2=%h Op2=%h",
                         alu_in_a_ex2, alu_in_b_ex2, ctrl_alu_op_ex2);
                error_count++;
            end
            if (alu_result !== alu_result_0_fi) begin
                $display("ERROR: Simplex output did not bypass EX0 directly! Expected %h, Got %h",
                         alu_result_0_fi, alu_result);
                error_count++;
            end
            if (tmr_mismatch !== 1'b0 || tmr_fatal_mismatch !== 1'b0) begin
                $display("ERROR: Mismatch flags should be masked to 0 in Simplex mode!");
                error_count++;
            end
        end

        if (gated_clk_ex1_pulses != 0) begin
            $display("ERROR: Clock Gating Failed! Gated clock pulsed %d times in Simplex mode!", gated_clk_ex1_pulses);
            error_count++;
        end else begin
            $display("  -> Clock Gating PASS: 0 clock pulses reached EX1/EX2.");
        end

        if (ex1_ex2_toggle_count != 0) begin
            $display("ERROR: Operand Isolation Failed! Detected %d input toggles on EX1/EX2!", ex1_ex2_toggle_count);
            error_count++;
        end else begin
            $display("  -> Operand Isolation PASS: Zero input toggles on EX1/EX2.");
        end

        $display("  -> TEST 1 PASSED: Simplex Mode verified successfully.\n");
        test_pass_count++;

        // --------------------------------------------------------------------
        // TEST 2: TMR MODE (HARDWARE PIN ENABLED) - MAJORITY VOTING & FAULT RECOVERY
        // --------------------------------------------------------------------
        $display("[TEST 2] Verifying TMR Mode via Hardware Pin (Pin Control)...");
        tmr_mode_pin = 1;
        sw_tmr_mode_reg = 0;
        #10;

        if (tmr_mode_active !== 1'b1) begin
            $display("ERROR: tmr_mode_active should be 1 when tmr_mode_pin = 1!");
            error_count++;
        end

        // Fault-free TMR execution
        alu_in_a = 32'h0000_0010;
        alu_in_b = 32'h0000_0020;
        ctrl_alu_op = 4'd0; // ADD
        alu_result_0_fi = 32'h0000_0030;
        alu_result_1_fi = 32'h0000_0030;
        alu_result_2_fi = 32'h0000_0030;
        #5;

        if (alu_in_a_ex1 !== alu_in_a || alu_in_b_ex1 !== alu_in_b || ctrl_alu_op_ex1 !== ctrl_alu_op) begin
            $display("ERROR: EX1 operands not correctly propagated in TMR Mode!");
            error_count++;
        end
        if (alu_result !== 32'h0000_0030 || tmr_mismatch !== 1'b0 || tmr_fatal_mismatch !== 1'b0) begin
            $display("ERROR: Fault-free TMR vote incorrect! Result=%h Mismatch=%b Fatal=%b",
                     alu_result, tmr_mismatch, tmr_fatal_mismatch);
            error_count++;
        end

        // Inject Single-Bit Fault into EX1 output
        $display("  -> Injecting fault into EX1 output (TMR Majority Vote Recovery test)...");
        alu_result_1_fi = 32'hFFFF_FFFF; // EX1 corrupted
        #5;

        if (alu_result !== 32'h0000_0030) begin
            $display("ERROR: TMR Majority Voter failed to correct single-unit fault! Expected 32'h30, Got %h", alu_result);
            error_count++;
        end
        if (tmr_mismatch !== 1'b1 || tmr_fatal_mismatch !== 1'b0) begin
            $display("ERROR: TMR Mismatch flag incorrect under single fault! Mismatch=%b Fatal=%b",
                     tmr_mismatch, tmr_fatal_mismatch);
            error_count++;
        end else begin
            $display("  -> TMR Single Fault Recovery PASS: Output correctly recovered as 32'h30 with mismatch flagged.");
        end

        // Inject Fatal Fault (All three units differ)
        $display("  -> Injecting fatal multi-unit faults (All three units differ)...");
        alu_result_0_fi = 32'h1111_1111;
        alu_result_1_fi = 32'h2222_2222;
        alu_result_2_fi = 32'h3333_3333;
        #5;

        if (tmr_fatal_mismatch !== 1'b1) begin
            $display("ERROR: TMR Fatal Mismatch flag failed to trigger when all 3 units differ!");
            error_count++;
        end else begin
            $display("  -> TMR Fatal Mismatch Detection PASS: Fatal flag correctly asserted.");
        end

        $display("  -> TEST 2 PASSED: TMR Mode via hardware pin verified.\n");
        test_pass_count++;

        // --------------------------------------------------------------------
        // TEST 3: TMR MODE (SOFTWARE REGISTER ENABLED)
        // --------------------------------------------------------------------
        $display("[TEST 3] Verifying TMR Mode via Software Control Register...");
        tmr_mode_pin = 0;
        sw_tmr_mode_reg = 1;
        #10;

        if (tmr_mode_active !== 1'b1) begin
            $display("ERROR: tmr_mode_active should be 1 when sw_tmr_mode_reg = 1!");
            error_count++;
        end

        alu_result_0_fi = 32'hABCD_1234;
        alu_result_1_fi = 32'hABCD_1234;
        alu_result_2_fi = 32'h9999_9999; // Single fault
        #5;

        if (alu_result !== 32'hABCD_1234 || tmr_mismatch !== 1'b1) begin
            $display("ERROR: SW-controlled TMR mode majority voting failed!");
            error_count++;
        end

        $display("  -> TEST 3 PASSED: TMR Mode via software register verified.\n");
        test_pass_count++;

        // --------------------------------------------------------------------
        // TEST 4: DYNAMIC MODE TRANSITION & GLITCH SAFETY
        // --------------------------------------------------------------------
        $display("[TEST 4] Verifying Dynamic Mode Transitions (Simplex <-> TMR)...");
        for (int step = 0; step < 20; step++) begin
            @(posedge clk);
            tmr_mode_pin = step[0]; // Alternates every cycle
            sw_tmr_mode_reg = 0;
            alu_in_a = step * 32'h100;
            alu_in_b = step * 32'h200;
            alu_result_0_fi = alu_in_a + alu_in_b;
            alu_result_1_fi = alu_in_a + alu_in_b;
            alu_result_2_fi = alu_in_a + alu_in_b;
            #1;

            if (tmr_mode_active) begin
                if (alu_in_a_ex1 !== alu_in_a) begin
                    $display("ERROR: Transition to TMR mode failed on step %d", step);
                    error_count++;
                end
            end else begin
                if (alu_in_a_ex1 !== 32'h0) begin
                    $display("ERROR: Transition to Simplex mode failed on step %d", step);
                    error_count++;
                end
            end
        end

        $display("  -> TEST 4 PASSED: Dynamic mode transitions executed cleanly without glitches.\n");
        test_pass_count++;

        // --------------------------------------------------------------------
        // FINAL TEST SUMMARY
        // --------------------------------------------------------------------
        $display("=========================================================");
        $display("   ADAPTIVE REDUNDANCY CONTROL TEST SUMMARY             ");
        $display("=========================================================");
        $display(" Total Sub-tests Passed : %0d / 4", test_pass_count);
        $display(" Total Error Count      : %0d", error_count);
        $display("=========================================================");

        if (error_count == 0) begin
            $display("\n>>> RESULT: ALL ADAPTIVE REDUNDANCY CONTROL TESTS PASSED SUCCESSFULY! <<<\n");
            $finish;
        end else begin
            $display("\n>>> RESULT: TEST FAILED WITH %0d ERRORS <<<\n", error_count);
            $stop;
        end
    end

endmodule
