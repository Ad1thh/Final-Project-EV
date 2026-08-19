`timescale 1ns/1ps

module tb_regfile_unit;

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

    logic [DATA_WIDTH-1:0] rd_val;
    logic                  sec_val;
    logic                  ded_val;

    integer test_count;
    integer pass_count;
    integer fail_count;
    integer k;

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

    initial begin
        $dumpfile("tb_regfile_unit.vcd");
        $dumpvars(0, tb_regfile_unit);
    end

    // Drive controls on negedge; DUT captures them on the next posedge.
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

    task automatic inject_single_bit(
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

    task automatic inject_double_bit(
        input logic [ADDR_WIDTH-1:0] addr,
        input logic [5:0] bit_a,
        input logic [5:0] bit_b
    );
        // First flip
        @(negedge clk);
        fi_reg_en   = 1'b1;
        fi_reg_addr = addr;
        fi_reg_bit  = bit_a;

        @(posedge clk);
        #1;

        // Second flip, without rewriting the register
        @(negedge clk);
        fi_reg_bit = bit_b;

        @(posedge clk);
        #1;

        @(negedge clk);
        fi_reg_en = 1'b0;
    endtask

    task automatic check_read(
        input  logic [ADDR_WIDTH-1:0] addr,
        output logic [DATA_WIDTH-1:0] data_out,
        output logic sec_out,
        output logic ded_out
    );
        // Asynchronous read address is also driven away from posedge.
        @(negedge clk);
        raddr1 = addr;
        #1;

        data_out = rdata1;
        sec_out  = single_err_corrected_1;
        ded_out  = double_err_detected_1;

        raddr1 = '0;
    endtask

    initial begin
        test_count = 0;
        pass_count = 0;
        fail_count = 0;

        rst_n      = 1'b0;
        we         = 1'b0;
        waddr      = '0;
        wdata      = '0;
        raddr1     = '0;
        raddr2     = '0;
        fi_reg_en  = 1'b0;
        fi_reg_addr = '0;
        fi_reg_bit = '0;

        #20;
        rst_n = 1'b1;

        $display("========================================");
        $display("UNIT TEST: regfile.sv SEC-DED");
        $display("========================================");

        // A: baseline
        test_count++;
        write_reg(4'd5, 32'hDEADBEEF);
        check_read(4'd5, rd_val, sec_val, ded_val);

        if (rd_val == 32'hDEADBEEF && !sec_val && !ded_val) begin
            $display("[A1] PASS");
            pass_count++;
        end else begin
            $display("[A1] FAIL: data=%h sec=%b ded=%b",
                     rd_val, sec_val, ded_val);
            fail_count++;
        end

        // B: overall parity bit
        test_count++;
        write_reg(4'd3, 32'hCAFEF00D);
        inject_single_bit(4'd3, 6'd0);
        check_read(4'd3, rd_val, sec_val, ded_val);

        if (rd_val == 32'hCAFEF00D && sec_val && !ded_val) begin
            $display("[B1] PASS");
            pass_count++;
        end else begin
            $display("[B1] FAIL: data=%h sec=%b ded=%b",
                     rd_val, sec_val, ded_val);
            fail_count++;
        end

        // C: Hamming parity positions
        begin
            int parity_bits [0:5];

            parity_bits[0] = 1;
            parity_bits[1] = 2;
            parity_bits[2] = 4;
            parity_bits[3] = 8;
            parity_bits[4] = 16;
            parity_bits[5] = 32;

            for (k = 0; k < 6; k++) begin
                test_count++;
                write_reg(4'd6, 32'h5A5A5A5A);
                inject_single_bit(4'd6, parity_bits[k]);
                check_read(4'd6, rd_val, sec_val, ded_val);

                if (rd_val == 32'h5A5A5A5A && sec_val && !ded_val) begin
                    $display("[C%0d] PASS", k + 1);
                    pass_count++;
                end else begin
                    $display("[C%0d] FAIL: bit=%0d data=%h sec=%b ded=%b",
                             k + 1, parity_bits[k], rd_val, sec_val, ded_val);
                    fail_count++;
                end
            end
        end

        // D: data-bearing codeword positions
        begin
            int d_addr [0:4];
            int d_bit  [0:4];
            logic [31:0] d_pattern [0:4];

            d_addr[0] = 1;  d_bit[0] = 3;  d_pattern[0] = 32'h00000001;
            d_addr[1] = 5;  d_bit[1] = 10; d_pattern[1] = 32'hFFFFFFFF;
            d_addr[2] = 7;  d_bit[2] = 20; d_pattern[2] = 32'h12345678;
            d_addr[3] = 9;  d_bit[3] = 30; d_pattern[3] = 32'hAABBCCDD;
            d_addr[4] = 15; d_bit[4] = 38; d_pattern[4] = 32'h80000001;

            for (k = 0; k < 5; k++) begin
                test_count++;
                write_reg(d_addr[k], d_pattern[k]);
                inject_single_bit(d_addr[k], d_bit[k]);
                check_read(d_addr[k], rd_val, sec_val, ded_val);

                if (rd_val == d_pattern[k] && sec_val && !ded_val) begin
                    $display("[D%0d] PASS", k + 1);
                    pass_count++;
                end else begin
                    $display("[D%0d] FAIL: bit=%0d data=%h sec=%b ded=%b",
                             k + 1, d_bit[k], rd_val, sec_val, ded_val);
                    fail_count++;
                end
            end
        end

        // E: double-bit errors
        begin
            int e_bit_a [0:2];
            int e_bit_b [0:2];

            e_bit_a[0] = 0;  e_bit_b[0] = 1;
            e_bit_a[1] = 3;  e_bit_b[1] = 38;
            e_bit_a[2] = 10; e_bit_b[2] = 20;

            for (k = 0; k < 3; k++) begin
                test_count++;
                write_reg(4'd9, 32'hAABBCCDD);
                inject_double_bit(4'd9, e_bit_a[k], e_bit_b[k]);
                check_read(4'd9, rd_val, sec_val, ded_val);

                if (ded_val && !sec_val) begin
                    $display("[E%0d] PASS", k + 1);
                    pass_count++;
                end else begin
                    $display("[E%0d] FAIL: bits={%0d,%0d} data=%h sec=%b ded=%b",
                             k + 1, e_bit_a[k], e_bit_b[k],
                             rd_val, sec_val, ded_val);
                    fail_count++;
                end
            end
        end

        // F: x0 ignores fault injection
        test_count++;
        inject_single_bit(4'd0, 6'd10);
        check_read(4'd0, rd_val, sec_val, ded_val);

        if (rd_val == 32'h00000000 && !sec_val && !ded_val) begin
            $display("[F1] PASS");
            pass_count++;
        end else begin
            $display("[F1] FAIL: data=%h sec=%b ded=%b",
                     rd_val, sec_val, ded_val);
            fail_count++;
        end

        $display("========================================");
        $display("Total:  %0d", test_count);
        $display("Passed: %0d", pass_count);
        $display("Failed: %0d", fail_count);
        $display("========================================");

        $finish;
    end

endmodule