`timescale 1ns/1ps
// Minimal probe: watch pc_debug exactly at the posedge when rst_n rises
// after it was asserted with active fi_reg_en and fi_alu_en simultaneously.
module tb_reset_probe;

    logic clk, rst_n;
    logic [31:0] imem_rdata;
    logic [31:0] imem_addr, dmem_addr, dmem_wdata, dmem_rdata, pc_debug;
    logic [3:0]  dmem_wmask;
    logic        dmem_we, trap;
    logic        tmr_mode_pin, fi_reg_en, fi_alu_en;
    logic [3:0]  fi_reg_addr;
    logic [5:0]  fi_reg_bit;
    logic [1:0]  fi_alu_sel;
    logic [4:0]  fi_alu_bit;
    logic        ecc_sec_1, ecc_ded_1, ecc_sec_2, ecc_ded_2, tmr_mismatch, tmr_fatal_mismatch;

    assign imem_rdata = 32'h00000013; // NOP
    assign dmem_rdata = 32'h0;

    riscv_core_top #(.DATA_WIDTH(32),.REG_COUNT(16),.ADDR_WIDTH(4)) dut (
        .clk(clk), .rst_n(rst_n), .imem_addr(imem_addr), .imem_rdata(imem_rdata),
        .dmem_addr(dmem_addr), .dmem_wdata(dmem_wdata), .dmem_wmask(dmem_wmask),
        .dmem_we(dmem_we), .dmem_rdata(dmem_rdata), .pc_debug(pc_debug), .trap(trap),
        .tmr_mode_pin(tmr_mode_pin), .fi_reg_en(fi_reg_en), .fi_reg_addr(fi_reg_addr),
        .fi_reg_bit(fi_reg_bit), .fi_alu_en(fi_alu_en), .fi_alu_sel(fi_alu_sel),
        .fi_alu_bit(fi_alu_bit), .ecc_sec_1(ecc_sec_1), .ecc_ded_1(ecc_ded_1),
        .ecc_sec_2(ecc_sec_2), .ecc_ded_2(ecc_ded_2), .tmr_mismatch(tmr_mismatch),
        .tmr_fatal_mismatch(tmr_fatal_mismatch)
    );

    initial begin clk=0; forever #5 clk=~clk; end

    initial begin
        rst_n=1'b1; tmr_mode_pin=1'b0;
        fi_reg_en=0; fi_reg_addr=0; fi_reg_bit=0;
        fi_alu_en=0; fi_alu_sel=0; fi_alu_bit=0;

        // 1. Normal reset
        @(negedge clk); rst_n=1'b0;
        @(posedge clk); #1;
        $display("During rst_n=0: pc_debug=0x%08h (expect 0x00000000)", pc_debug);

        @(negedge clk); rst_n=1'b1;
        @(posedge clk); #1;
        $display("First clk after rst_n=1 (no FI): pc_debug=0x%08h", pc_debug);

        // 2. Reassert reset while FI active
        // Let core run 3 cycles first
        repeat(3) @(posedge clk);

        @(negedge clk);
        rst_n       = 1'b0;
        fi_reg_en   = 1'b1; fi_reg_addr = 4'd5; fi_reg_bit  = 6'd10;
        fi_alu_en   = 1'b1; fi_alu_sel  = 2'd0; fi_alu_bit  = 5'd15;

        // Check during rst_n=0 with FI asserted
        @(posedge clk); #1;
        $display("During rst_n=0 WITH FI: pc_debug=0x%08h, ecc_ded_1=%b", pc_debug, ecc_ded_1);

        // Now release everything simultaneously
        @(negedge clk);
        fi_reg_en=0; fi_alu_en=0;
        rst_n=1'b1;

        @(posedge clk); #1;
        $display("1st clk after rst_n=1 WITH prior FI: pc_debug=0x%08h, ecc_ded_1=%b", pc_debug, ecc_ded_1);

        // Check a few more cycles
        repeat(2) @(posedge clk);
        #1;
        $display("3rd clk after reset release: pc_debug=0x%08h, ecc_sec_1=%b, ecc_ded_1=%b",
                 pc_debug, ecc_sec_1, ecc_ded_1);

        $display("DONE");
        $finish;
    end
endmodule
