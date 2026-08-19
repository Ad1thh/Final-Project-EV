`timescale 1ns/1ps

import riscv_pkg::*;

module tb_tmr_adversarial;

    parameter int DATA_WIDTH = 32;
    parameter time CLK_PERIOD = 10;

    logic clk;
    logic rst_n;

    logic [DATA_WIDTH-1:0] alu_in_a;
    logic [DATA_WIDTH-1:0] alu_in_b;
    logic [3:0]            alu_op;
    logic                  tmr_mode;

    logic                  fi_alu_en;
    logic [1:0]            fi_alu_sel;
    logic [4:0]            fi_alu_bit;

    // Additional manual override vectors for multi-bit and 3-way disagree testing of voter
    logic                  use_manual_voter_in;
    logic [DATA_WIDTH-1:0] man_a, man_b, man_c;

    logic [DATA_WIDTH-1:0] alu_result_0, alu_result_1, alu_result_2;
    logic [DATA_WIDTH-1:0] alu_in_a_tmr, alu_in_b_tmr;
    logic [DATA_WIDTH-1:0] fi_mask;
    logic [DATA_WIDTH-1:0] alu_result_0_fi, alu_result_1_fi, alu_result_2_fi;

    logic [DATA_WIDTH-1:0] voter_a_in, voter_b_in, voter_c_in;
    logic [DATA_WIDTH-1:0] voter_result;
    logic                  voter_mismatch;
    logic                  voter_fatal_mismatch;
    logic                  voter_no_maj;

    logic [DATA_WIDTH-1:0] final_alu_result;
    logic                  final_tmr_mismatch;
    logic                  final_tmr_fatal_mismatch;

    // ALU 0
    alu #(.DATA_WIDTH(DATA_WIDTH)) u_alu_0 (
        .a      (alu_in_a),
        .b      (alu_in_b),
        .alu_op (alu_op),
        .result (alu_result_0),
        .zero   ()
    );

    // Operand isolation for Simplex mode
    assign alu_in_a_tmr = (tmr_mode) ? alu_in_a : '0;
    assign alu_in_b_tmr = (tmr_mode) ? alu_in_b : '0;

    // ALU 1 & 2
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

    assign fi_mask = (fi_alu_en) ? (32'd1 << fi_alu_bit) : '0;
    assign alu_result_0_fi = alu_result_0 ^ ((fi_alu_sel == 2'd0) ? fi_mask : '0);
    assign alu_result_1_fi = alu_result_1 ^ ((fi_alu_sel == 2'd1) ? fi_mask : '0);
    assign alu_result_2_fi = alu_result_2 ^ ((fi_alu_sel == 2'd2) ? fi_mask : '0);

    assign voter_a_in = (use_manual_voter_in) ? man_a : alu_result_0_fi;
    assign voter_b_in = (use_manual_voter_in) ? man_b : alu_result_1_fi;
    assign voter_c_in = (use_manual_voter_in) ? man_c : alu_result_2_fi;

    tmr_voter #(.WIDTH(DATA_WIDTH)) u_tmr_voter (
        .a                (voter_a_in),
        .b                (voter_b_in),
        .c                (voter_c_in),
        .result           (voter_result),
        .mismatch_detected(voter_mismatch),
        .tmr_fatal_mismatch(voter_fatal_mismatch)
    );

    assign final_alu_result   = (tmr_mode) ? voter_result : alu_result_0_fi;
    assign final_tmr_mismatch = (tmr_mode) ? voter_mismatch : 1'b0;
    assign final_tmr_fatal_mismatch = (tmr_mode) ? voter_fatal_mismatch : 1'b0;

    initial begin
        clk = 1'b0;
        forever #(CLK_PERIOD/2) clk = ~clk;
    end

    integer p2_1_tested = 0, p2_1_passed = 0, p2_1_failed = 0;
    integer p2_2_tested = 0, p2_2_passed = 0, p2_2_failed = 0;
    integer p2_3_tested = 0, p2_3_passed = 0, p2_3_failed = 0;
    integer p2_4_tested = 0, p2_4_passed = 0, p2_4_failed = 0;
    integer p2_5_tested = 0, p2_5_passed = 0, p2_5_failed = 0;
    integer p2_6_tested = 0, p2_6_passed = 0, p2_6_failed = 0;

    initial begin
        rst_n = 1'b0;
        alu_in_a = '0; alu_in_b = '0; alu_op = 4'b0000; tmr_mode = 1'b1;
        fi_alu_en = 1'b0; fi_alu_sel = '0; fi_alu_bit = '0;
        use_manual_voter_in = 1'b0; man_a = '0; man_b = '0; man_c = '0;

        #20; rst_n = 1'b1; #10;

        $display("=================================================");
        $display("PART 2: ADVERSARIAL SELECTIVE TMR STRESS");
        $display("=================================================");

        // --------------------------------------------------------------------
        // 2.1 Every ALU operation type under fault
        // --------------------------------------------------------------------
        $display("\n--- 2.1 Every ALU Operation Type Under Fault ---");
        begin
            logic [3:0] ops[11];
            string op_names[11];
            logic [DATA_WIDTH-1:0] op_a, op_b, expected_clean;
            int op_idx, inst_idx, bit_pos;

            ops[0] = ALU_ADD;    op_names[0] = "ADD";
            ops[1] = ALU_SUB;    op_names[1] = "SUB";
            ops[2] = ALU_AND;    op_names[2] = "AND";
            ops[3] = ALU_OR;     op_names[3] = "OR";
            ops[4] = ALU_XOR;    op_names[4] = "XOR";
            ops[5] = ALU_SLL;    op_names[5] = "SLL";
            ops[6] = ALU_SRL;    op_names[6] = "SRL";
            ops[7] = ALU_SRA;    op_names[7] = "SRA";
            ops[8] = ALU_SLT;    op_names[8] = "SLT";
            ops[9] = ALU_SLTU;   op_names[9] = "SLTU";
            ops[10]= ALU_PASS_B; op_names[10]= "PASS_B";

            op_a = 32'h800000FE;
            op_b = 32'h00000004;

            tmr_mode = 1'b1;
            use_manual_voter_in = 1'b0;

            for (op_idx = 0; op_idx < 11; op_idx++) begin
                alu_in_a = op_a; alu_in_b = op_b; alu_op = ops[op_idx];
                #1;
                expected_clean = alu_result_0; // baseline

                for (inst_idx = 0; inst_idx < 3; inst_idx++) begin
                    for (bit_pos = 0; bit_pos < 32; bit_pos += 8) begin // Sample bit positions per op
                        p2_1_tested++;
                        fi_alu_en = 1'b1;
                        fi_alu_sel = inst_idx[1:0];
                        fi_alu_bit = bit_pos[4:0];
                        #1;

                        if (final_alu_result == expected_clean && final_tmr_mismatch == 1'b1) begin
                            p2_1_passed++;
                        end else begin
                            p2_1_failed++;
                            $display("[2.1 FAIL] Op %s, Inst %0d, Bit %0d: result=0x%08h (exp 0x%08h), mismatch=%b",
                                     op_names[op_idx], inst_idx, bit_pos, final_alu_result, expected_clean, final_tmr_mismatch);
                        end
                    end
                end
            end
            $display("2.1 Result: Tested=%0d, Passed=%0d, Failed=%0d", p2_1_tested, p2_1_passed, p2_1_failed);
            fi_alu_en = 1'b0;
        end

        // --------------------------------------------------------------------
        // 2.2 Multi-bit corruption in a single ALU instance (2, 4, 16, 32 bits)
        // --------------------------------------------------------------------
        $display("\n--- 2.2 Multi-Bit Corruption in Single ALU Instance ---");
        begin
            logic [DATA_WIDTH-1:0] clean_val = 32'h12345678;
            logic [DATA_WIDTH-1:0] masks[4];
            int m_idx, inst_idx;

            masks[0] = 32'h00000003;  // 2 bits flipped
            masks[1] = 32'h0000000F;  // 4 bits flipped
            masks[2] = 32'h0000FFFF;  // 16 bits flipped
            masks[3] = 32'hFFFFFFFF;  // 32 bits flipped

            use_manual_voter_in = 1'b1;

            for (inst_idx = 0; inst_idx < 3; inst_idx++) begin
                for (m_idx = 0; m_idx < 4; m_idx++) begin
                    p2_2_tested++;
                    man_a = clean_val; man_b = clean_val; man_c = clean_val;

                    if (inst_idx == 0) man_a = clean_val ^ masks[m_idx];
                    else if (inst_idx == 1) man_b = clean_val ^ masks[m_idx];
                    else man_c = clean_val ^ masks[m_idx];

                    #1;

                    if (voter_result == clean_val && voter_mismatch == 1'b1) begin
                        p2_2_passed++;
                    end else begin
                        p2_2_failed++;
                        $display("[2.2 FAIL] Multi-bit flip (inst %0d, mask 0x%08h): result=0x%08h, mismatch=%b",
                                 inst_idx, masks[m_idx], voter_result, voter_mismatch);
                    end
                end
            end
            $display("2.2 Result: Tested=%0d, Passed=%0d, Failed=%0d", p2_2_tested, p2_2_passed, p2_2_failed);
            use_manual_voter_in = 1'b0;
        end

        // --------------------------------------------------------------------
        // 2.3 Corrupt SAME bit position in two different instances differently
        // --------------------------------------------------------------------
        $display("\n--- 2.3 Bitwise Majority under Differing Disagreements ---");
        begin
            use_manual_voter_in = 1'b1;
            p2_3_tested = 2;

            // Test case A: Bit 5 -> inst0=1, inst1=0, inst2=1 -> majority=1
            man_a = 32'h00000020;
            man_b = 32'h00000000;
            man_c = 32'h00000020;
            #1;
            if (voter_result == 32'h00000020 && voter_mismatch == 1'b1) begin
                p2_3_passed++;
            end else begin
                p2_3_failed++;
                $display("[2.3 FAIL Case A] result=0x%08h, mismatch=%b", voter_result, voter_mismatch);
            end

            // Test case B: Bit 5 -> inst0=0, inst1=1, inst2=0 -> majority=0
            man_a = 32'h00000000;
            man_b = 32'h00000020;
            man_c = 32'h00000000;
            #1;
            if (voter_result == 32'h00000000 && voter_mismatch == 1'b1) begin
                p2_3_passed++;
            end else begin
                p2_3_failed++;
                $display("[2.3 FAIL Case B] result=0x%08h, mismatch=%b", voter_result, voter_mismatch);
            end

            $display("2.3 Result: Tested=%0d, Passed=%0d, Failed=%0d", p2_3_tested, p2_3_passed, p2_3_failed);
            use_manual_voter_in = 1'b0;
        end

        // --------------------------------------------------------------------
        // 2.4 All-three-disagree edge case (beyond spec)
        // --------------------------------------------------------------------
        $display("\n--- 2.4 All-Three-Disagree Edge Case ---");
        begin
            use_manual_voter_in = 1'b1;
            p2_4_tested = 1;

            // Inst 0 = 0xFF000000 (bits 31:24 = 1)
            // Inst 1 = 0x00FF0000 (bits 23:16 = 1)
            // Inst 2 = 0x0000FF00 (bits 15:8  = 1)
            // For every single bit, exactly one instance is 1 and two instances are 0.
            man_a = 32'hFF000000;
            man_b = 32'h00FF0000;
            man_c = 32'h0000FF00;
            #1;

            $display("  Input A = 0x%08h", man_a);
            $display("  Input B = 0x%08h", man_b);
            $display("  Input C = 0x%08h", man_c);
            $display("  Voter Output Result  = 0x%08h", voter_result);
            $display("  Voter Mismatch Flag  = %b", voter_mismatch);
            $display("  Voter Fatal Mismatch = %b", voter_fatal_mismatch);

            if (voter_result == 32'h00000000 && voter_mismatch == 1'b1 && voter_fatal_mismatch == 1'b1) begin
                p2_4_passed++;
            end else begin
                p2_4_failed++;
                $display("[2.4 FAIL] result=0x%08h, mismatch=%b, fatal_mismatch=%b", voter_result, voter_mismatch, voter_fatal_mismatch);
            end

            $display("  -> OBSERVED BEHAVIOR: For all-three-disagree non-overlapping 1-bits, majority equation (a&b)|(a&c)|(b&c) evaluates to 0x00000000. Mismatch_detected is 1, tmr_fatal_mismatch is 1.");
            $display("2.4 Result: Tested=%0d, Passed=%0d, Failed=%0d", p2_4_tested, p2_4_passed, p2_4_failed);
            use_manual_voter_in = 1'b0;
        end

        // --------------------------------------------------------------------
        // 2.5 Every mode-switch timing edge & rapid toggling
        // --------------------------------------------------------------------
        $display("\n--- 2.5 Mode-Switch Timing Edges & Rapid Toggling ---");
        begin
            integer i;
            logic [DATA_WIDTH-1:0] res_toggled;

            p2_5_tested = 20;

            alu_in_a = 32'h00000010;
            alu_in_b = 32'h00000020;
            alu_op   = ALU_ADD;

            // Rapid toggle tmr_mode every clock cycle for 20 cycles
            for (i = 0; i < 20; i++) begin
                @(negedge clk);
                tmr_mode = ~tmr_mode;
                @(posedge clk); #1;

                if (final_alu_result == 32'h00000030 && final_tmr_mismatch == 1'b0) begin
                    p2_5_passed++;
                end else begin
                    p2_5_failed++;
                    $display("[2.5 FAIL Cycle %0d] tmr_mode=%b, result=0x%08h, mismatch=%b",
                             i, tmr_mode, final_alu_result, final_tmr_mismatch);
                end
            end
            $display("2.5 Result: Cycles Tested=%0d, Passed=%0d, Failed=%0d", p2_5_tested, p2_5_passed, p2_5_failed);
        end

        // --------------------------------------------------------------------
        // 2.6 Fault injection during mode transition
        // --------------------------------------------------------------------
        $display("\n--- 2.6 Fault Injection During Mode Transition ---");
        begin
            p2_6_tested = 2;

            alu_in_a = 32'h00000005;
            alu_in_b = 32'h00000005;
            alu_op   = ALU_ADD;

            // Case 1: tmr_mode toggles 0 -> 1 on same cycle fi_alu_en asserts for inst 1 (corrupted inst)
            @(negedge clk);
            tmr_mode = 1'b1;
            fi_alu_en = 1'b1; fi_alu_sel = 2'd1; fi_alu_bit = 5'd0;
            #1;

            if (final_alu_result == 32'h0000000A && final_tmr_mismatch == 1'b1) begin
                p2_6_passed++;
                $display("  Case 1 (Mode 0->1 during FI on Inst 1): Masked cleanly, mismatch flagged.");
            end else begin
                p2_6_failed++;
                $display("[2.6 FAIL Case 1] result=0x%08h, mismatch=%b", final_alu_result, final_tmr_mismatch);
            end

            // Case 2: tmr_mode toggles 1 -> 0 on same cycle fi_alu_en asserts for inst 0 (primary inst)
            @(negedge clk);
            tmr_mode = 1'b0;
            fi_alu_en = 1'b1; fi_alu_sel = 2'd0; fi_alu_bit = 5'd0;
            #1;

            if (final_alu_result == (32'h0000000A ^ 32'h00000001) && final_tmr_mismatch == 1'b0) begin
                p2_6_passed++;
                $display("  Case 2 (Mode 1->0 during FI on Inst 0): Unmasked in Simplex mode, fault propagated, no TMR mismatch.");
            end else begin
                p2_6_failed++;
                $display("[2.6 FAIL Case 2] result=0x%08h, mismatch=%b", final_alu_result, final_tmr_mismatch);
            end

            $display("2.6 Result: Tested=%0d, Passed=%0d, Failed=%0d", p2_6_tested, p2_6_passed, p2_6_failed);
            fi_alu_en = 1'b0;
        end

        $display("\n=================================================");
        $display("PART 2 SUMMARY");
        $display("=================================================");
        $display("Total Part 2 Tests: %0d", p2_1_tested + p2_2_tested + p2_3_tested + p2_4_tested + p2_5_tested + p2_6_tested);
        $display("Total Part 2 Passed: %0d", p2_1_passed + p2_2_passed + p2_3_passed + p2_4_passed + p2_5_passed + p2_6_passed);
        $display("Total Part 2 Failed: %0d", p2_1_failed + p2_2_failed + p2_3_failed + p2_4_failed + p2_5_failed + p2_6_failed);
        $display("=================================================");

        $finish;
    end

endmodule
