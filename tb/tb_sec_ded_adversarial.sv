`timescale 1ns/1ps

module tb_sec_ded_adversarial;

    parameter int DATA_WIDTH = 32;
    parameter int REG_COUNT  = 16;
    parameter int ADDR_WIDTH = 4;
    parameter time CLK_PERIOD = 10;

    logic clk;
    logic rst_n;

    logic                  we;
    logic [ADDR_WIDTH-1:0] waddr;
    logic [DATA_WIDTH-1:0] wdata;

    logic [ADDR_WIDTH-1:0] raddr1;
    logic [DATA_WIDTH-1:0] rdata1;
    logic                  single_err_corrected_1;
    logic                  double_err_detected_1;

    logic [ADDR_WIDTH-1:0] raddr2;
    logic [DATA_WIDTH-1:0] rdata2;
    logic                  single_err_corrected_2;
    logic                  double_err_detected_2;

    logic                  fi_reg_en;
    logic [ADDR_WIDTH-1:0] fi_reg_addr;
    logic [5:0]            fi_reg_bit;

    regfile #(
        .DATA_WIDTH (DATA_WIDTH),
        .REG_COUNT  (REG_COUNT),
        .ADDR_WIDTH (ADDR_WIDTH)
    ) dut (
        .clk                    (clk),
        .rst_n                  (rst_n),
        .raddr1                 (raddr1),
        .rdata1                 (rdata1),
        .single_err_corrected_1 (single_err_corrected_1),
        .double_err_detected_1  (double_err_detected_1),
        .raddr2                 (raddr2),
        .rdata2                 (rdata2),
        .single_err_corrected_2 (single_err_corrected_2),
        .double_err_detected_2  (double_err_detected_2),
        .we                     (we),
        .waddr                  (waddr),
        .wdata                  (wdata),
        .fi_reg_en              (fi_reg_en),
        .fi_reg_addr            (fi_reg_addr),
        .fi_reg_bit             (fi_reg_bit)
    );

    initial begin
        clk = 1'b0;
        forever #(CLK_PERIOD / 2) clk = ~clk;
    end

    // Helper task to write a register
    task automatic write_reg(
        input logic [ADDR_WIDTH-1:0] addr,
        input logic [DATA_WIDTH-1:0] data
    );
        @(negedge clk);
        we    = 1'b1;
        waddr = addr;
        wdata = data;

        @(posedge clk);
        #1;

        @(negedge clk);
        we = 1'b0;
    endtask

    // Helper task to inject single fault
    task automatic inject_single_fault(
        input logic [ADDR_WIDTH-1:0] addr,
        input logic [5:0] bit_idx
    );
        @(negedge clk);
        fi_reg_en   = 1'b1;
        fi_reg_addr = addr;
        fi_reg_bit  = bit_idx;

        @(posedge clk);
        #1;

        @(negedge clk);
        fi_reg_en = 1'b0;
    endtask

    // Helper task to read Port 1
    task automatic read_reg_p1(
        input  logic [ADDR_WIDTH-1:0] addr,
        output logic [DATA_WIDTH-1:0] data_out,
        output logic sec_out,
        output logic ded_out
    );
        @(negedge clk);
        raddr1 = addr;
        #1;
        data_out = rdata1;
        sec_out  = single_err_corrected_1;
        ded_out  = double_err_detected_1;
        raddr1 = '0;
    endtask

    // Statistics counters
    integer p1_1_tested = 0, p1_1_passed = 0, p1_1_failed = 0;
    integer p1_2_tested = 0, p1_2_passed = 0, p1_2_failed = 0;
    integer p1_3_tested = 0, p1_3_passed = 0, p1_3_failed = 0;
    integer p1_4_tested = 0, p1_4_passed = 0, p1_4_failed = 0;
    integer p1_5_tested = 0, p1_5_passed = 0, p1_5_failed = 0;
    integer p1_6_tested = 0, p1_6_passed = 0, p1_6_failed = 0;

    initial begin
        rst_n       = 1'b0;
        we          = 1'b0;
        waddr       = '0;
        wdata       = '0;
        raddr1      = '0;
        raddr2      = '0;
        fi_reg_en   = 1'b0;
        fi_reg_addr = '0;
        fi_reg_bit  = '0;

        #20;
        rst_n = 1'b1;
        #10;

        $display("=================================================");
        $display("PART 1: ADVERSARIAL SEC-DED REGISTER FILE STRESS");
        $display("=================================================");

        // --------------------------------------------------------------------
        // 1.1 Exhaustive single-bit sweep (39 bits x 3 regs x 5 patterns)
        // --------------------------------------------------------------------
        $display("\n--- 1.1 Exhaustive Single-Bit Sweep ---");
        begin
            logic [ADDR_WIDTH-1:0] test_regs[3];
            logic [DATA_WIDTH-1:0] patterns[5];
            logic [DATA_WIDTH-1:0] rd_data;
            logic sec, ded;
            int bit_pos, r_idx, p_idx;

            test_regs[0] = 4'd1;
            test_regs[1] = 4'd7;
            test_regs[2] = 4'd14;

            patterns[0] = 32'h00000000;
            patterns[1] = 32'hFFFFFFFF;
            patterns[2] = 32'h55555555;
            patterns[3] = 32'hAAAAAAAA;
            patterns[4] = 32'h9E3779B9; // Random fixed pattern per run

            for (r_idx = 0; r_idx < 3; r_idx++) begin
                for (p_idx = 0; p_idx < 5; p_idx++) begin
                    for (bit_pos = 0; bit_pos < 39; bit_pos++) begin
                        p1_1_tested++;
                        // Write pattern
                        write_reg(test_regs[r_idx], patterns[p_idx]);
                        // Inject bit flip
                        inject_single_fault(test_regs[r_idx], bit_pos[5:0]);
                        // Read back
                        read_reg_p1(test_regs[r_idx], rd_data, sec, ded);

                        if (rd_data == patterns[p_idx] && sec == 1'b1 && ded == 1'b0) begin
                            p1_1_passed++;
                        end else begin
                            p1_1_failed++;
                            $display("[1.1 FAIL] Reg x%0d, Pattern 0x%08h, Bit %0d -> Read=0x%08h, sec=%b, ded=%b",
                                     test_regs[r_idx], patterns[p_idx], bit_pos, rd_data, sec, ded);
                        end
                    end
                end
            end
            $display("1.1 Result: Tested=%0d, Passed=%0d, Failed=%0d", p1_1_tested, p1_1_passed, p1_1_failed);
        end

        // --------------------------------------------------------------------
        // 1.2 Every possible bit-pair sweep (39 choose 2 = 741 pairs)
        // --------------------------------------------------------------------
        $display("\n--- 1.2 Exhaustive Bit-Pair Sweep (741 pairs) ---");
        begin
            int b1, b2;
            logic [DATA_WIDTH-1:0] rd_data;
            logic sec, ded;
            logic [DATA_WIDTH-1:0] pat = 32'hA5A5A5A5;

            for (b1 = 0; b1 < 39; b1++) begin
                for (b2 = b1 + 1; b2 < 39; b2++) begin
                    p1_2_tested++;
                    // Write reg
                    write_reg(4'd5, pat);
                    // Inject flip b1 then flip b2
                    @(negedge clk);
                    fi_reg_en   = 1'b1;
                    fi_reg_addr = 4'd5;
                    fi_reg_bit  = b1[5:0];
                    @(posedge clk); #1;

                    @(negedge clk);
                    fi_reg_bit  = b2[5:0];
                    @(posedge clk); #1;

                    @(negedge clk);
                    fi_reg_en   = 1'b0;

                    // Read reg
                    read_reg_p1(4'd5, rd_data, sec, ded);

                    if (ded == 1'b1 && sec == 1'b0) begin
                        p1_2_passed++;
                    end else begin
                        p1_2_failed++;
                        $display("[1.2 CRITICAL BUG] Pair {%0d, %0d} on Reg x5 -> Read=0x%08h, sec=%b, ded=%b",
                                 b1, b2, rd_data, sec, ded);
                    end
                end
            end
            $display("1.2 Result: Tested=%0d, Passed=%0d, Failed=%0d", p1_2_tested, p1_2_passed, p1_2_failed);
        end

        // --------------------------------------------------------------------
        // 1.3 Back-to-back operations with zero settling time
        // --------------------------------------------------------------------
        $display("\n--- 1.3 Back-to-Back Pipeline Stress ---");
        begin
            logic [DATA_WIDTH-1:0] rd_data;
            logic sec, ded;
            integer i;

            p1_3_tested = 10;
            for (i = 0; i < 10; i++) begin
                // Write x2, next cycle read x2 while writing x3, next cycle inject fault into x3, next cycle read x3
                @(negedge clk);
                we = 1'b1; waddr = 4'd2; wdata = 32'h11111111 + i;
                @(posedge clk); #1;

                @(negedge clk);
                we = 1'b1; waddr = 4'd3; wdata = 32'h22222222 + i;
                raddr1 = 4'd2; // Read x2 while writing x3
                fi_reg_en = 1'b0;
                @(posedge clk); #1;

                // Check read of x2
                if (rdata1 != 32'h11111111 + i || single_err_corrected_1 != 0 || double_err_detected_1 != 0) begin
                    $display("[1.3 FAIL] Back-to-back read x2 failed: data=0x%08h, sec=%b, ded=%b",
                             rdata1, single_err_corrected_1, double_err_detected_1);
                    p1_3_failed++;
                end

                // Now inject fault into x3 immediately on next cycle
                @(negedge clk);
                we = 1'b0;
                raddr1 = 4'd0;
                fi_reg_en = 1'b1; fi_reg_addr = 4'd3; fi_reg_bit = 6'd12;
                @(posedge clk); #1;

                // Next cycle immediately read x3
                @(negedge clk);
                fi_reg_en = 1'b0;
                raddr1 = 4'd3;
                #1;
                if (rdata1 == 32'h22222222 + i && single_err_corrected_1 == 1'b1 && double_err_detected_1 == 1'b0) begin
                    p1_3_passed++;
                end else begin
                    $display("[1.3 FAIL] Back-to-back fault read x3 failed: data=0x%08h, sec=%b, ded=%b",
                             rdata1, single_err_corrected_1, double_err_detected_1);
                    p1_3_failed++;
                end
                raddr1 = 4'd0;
            end
            $display("1.3 Result: Sequences Tested=%0d, Passed=%0d, Failed=%0d", p1_3_tested, p1_3_passed, p1_3_failed);
        end

        // --------------------------------------------------------------------
        // 1.4 Same-cycle read/write collision hardening
        // --------------------------------------------------------------------
        $display("\n--- 1.4 Same-Cycle Read/Write Collision Hardening ---");
        begin
            logic [DATA_WIDTH-1:0] p1_val, p2_val;
            logic sec1, ded1, sec2, ded2;

            p1_4_tested = 2; // Test same cycle bypass behavior and post-write storage behavior

            // Write x8 with 0xBABEFACE, while reading x8 on Port 1 and Port 2, while fi_reg_en is asserted for x8 bit 5
            write_reg(4'd8, 32'h00000000); // Clear first

            @(negedge clk);
            we    = 1'b1;
            waddr = 4'd8;
            wdata = 32'hBABEFACE;
            raddr1 = 4'd8;
            raddr2 = 4'd8;
            fi_reg_en   = 1'b1;
            fi_reg_addr = 4'd8;
            fi_reg_bit  = 6'd5;

            #1;
            // On combinational same-cycle before posedge:
            // Since we & waddr==raddr1, bypass provides rdata = wdata (uncorrupted)
            p1_val = rdata1; p2_val = rdata2;
            sec1 = single_err_corrected_1; sec2 = single_err_corrected_2;
            $display("  Same-cycle bypass before posedge: rdata1=0x%08h, sec1=%b, rdata2=0x%08h, sec2=%b",
                     p1_val, sec1, p2_val, sec2);

            if (p1_val == 32'hBABEFACE && p2_val == 32'hBABEFACE && sec1 == 0 && sec2 == 0) begin
                p1_4_passed++;
            end else begin
                p1_4_failed++;
                $display("[1.4 FAIL] Same-cycle bypass output incorrect!");
            end

            @(posedge clk); #1;
            @(negedge clk);
            we = 1'b0; fi_reg_en = 1'b0; raddr1 = 4'd0; raddr2 = 4'd0;

            // Now read x8 on subsequent cycle to inspect stored codeword after collision
            read_reg_p1(4'd8, p1_val, sec1, ded1);
            $display("  Subsequent cycle read of x8 after R/W/FI collision: rdata1=0x%08h, sec=%b, ded=%b",
                     p1_val, sec1, ded1);

            if (p1_val == 32'hBABEFACE && sec1 == 1'b1 && ded1 == 1'b0) begin
                p1_4_passed++;
                $display("  -> Behavior verified: Bypass serves clean wdata during write cycle; fault injection modifies stored rf[waddr] codeword bit on posedge, resulting in SEC correction on next read.");
            end else begin
                p1_4_failed++;
                $display("[1.4 FAIL] Post-collision storage check failed: rdata=0x%08h, sec=%b, ded=%b", p1_val, sec1, ded1);
            end
            $display("1.4 Result: Tested=%0d, Passed=%0d, Failed=%0d", p1_4_tested, p1_4_passed, p1_4_failed);
        end

        // --------------------------------------------------------------------
        // 1.5 Rapid-fire faults with no recovery time
        // --------------------------------------------------------------------
        $display("\n--- 1.5 Rapid-Fire Faults Without Intermediate Write ---");
        begin
            logic [DATA_WIDTH-1:0] rd_data;
            logic sec, ded;

            p1_5_tested = 1;

            // Write clean pattern to x4
            write_reg(4'd4, 32'h12345678);

            // First fault injection: bit 3
            inject_single_fault(4'd4, 6'd3);
            read_reg_p1(4'd4, rd_data, sec, ded);
            $display("  After 1st fault (bit 3): data=0x%08h, sec=%b, ded=%b", rd_data, sec, ded);

            // Second fault injection: bit 20 (WITHOUT intermediate write)
            inject_single_fault(4'd4, 6'd20);
            read_reg_p1(4'd4, rd_data, sec, ded);
            $display("  After 2nd fault (bit 20) on same reg: data=0x%08h, sec=%b, ded=%b", rd_data, sec, ded);

            if (ded == 1'b1 && sec == 1'b0) begin
                p1_5_passed++;
                $display("  -> OBSERVED BEHAVIOR: Accumulated faults in unscrubbed codeword correctly trigger DED (double-error detection)!");
            end else begin
                p1_5_failed++;
                $display("[1.5 CRITICAL FINDING] Rapid-fire double fault did NOT result in clean DED: sec=%b, ded=%b, data=0x%08h",
                         sec, ded, rd_data);
            end
            $display("1.5 Result: Tested=%0d, Passed=%0d, Failed=%0d", p1_5_tested, p1_5_passed, p1_5_failed);
        end

        // --------------------------------------------------------------------
        // 1.6 All 15 Registers Sweep (x1 to x15, plus x0 verification)
        // --------------------------------------------------------------------
        $display("\n--- 1.6 All 15 Registers Sweep ---");
        begin
            int reg_idx, bit_idx;
            logic [DATA_WIDTH-1:0] rd_data;
            logic sec, ded;
            int bits_to_test[2];
            bits_to_test[0] = 5;
            bits_to_test[1] = 25;

            for (reg_idx = 1; reg_idx <= 15; reg_idx++) begin
                for (bit_idx = 0; bit_idx < 2; bit_idx++) begin
                    p1_6_tested++;
                    // Write reg
                    write_reg(reg_idx[ADDR_WIDTH-1:0], 32'hC0FFEE00 + reg_idx);
                    // Inject fault
                    inject_single_fault(reg_idx[ADDR_WIDTH-1:0], bits_to_test[bit_idx][5:0]);
                    // Read back
                    read_reg_p1(reg_idx[ADDR_WIDTH-1:0], rd_data, sec, ded);

                    if (rd_data == (32'hC0FFEE00 + reg_idx) && sec == 1'b1 && ded == 1'b0) begin
                        p1_6_passed++;
                    end else begin
                        p1_6_failed++;
                        $display("[1.6 FAIL] Reg x%0d, Bit %0d: data=0x%08h, sec=%b, ded=%b",
                                 reg_idx, bits_to_test[bit_idx], rd_data, sec, ded);
                    end
                end
            end

            // Also verify x0 ignores fault injection and always returns 0
            p1_6_tested++;
            inject_single_fault(4'd0, 6'd10);
            read_reg_p1(4'd0, rd_data, sec, ded);
            if (rd_data == 32'h00000000 && sec == 1'b0 && ded == 1'b0) begin
                p1_6_passed++;
                $display("  x0 Hardwiring check: PASSED (ignores FI, returns 0)");
            end else begin
                p1_6_failed++;
                $display("[1.6 CRITICAL BUG] x0 modified by fault injection! data=0x%08h, sec=%b, ded=%b", rd_data, sec, ded);
            end

            $display("1.6 Result: Reg/Bit Combos Tested=%0d, Passed=%0d, Failed=%0d", p1_6_tested, p1_6_passed, p1_6_failed);
        end

        $display("\n=================================================");
        $display("PART 1 SUMMARY");
        $display("=================================================");
        $display("Total Part 1 Tests: %0d", p1_1_tested + p1_2_tested + p1_3_tested + p1_4_tested + p1_5_tested + p1_6_tested);
        $display("Total Part 1 Passed: %0d", p1_1_passed + p1_2_passed + p1_3_passed + p1_4_passed + p1_5_passed + p1_6_passed);
        $display("Total Part 1 Failed: %0d", p1_1_failed + p1_2_failed + p1_3_failed + p1_4_failed + p1_5_failed + p1_6_failed);
        $display("=================================================");

        $finish;
    end

endmodule
