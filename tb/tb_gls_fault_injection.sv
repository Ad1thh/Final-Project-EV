`timescale 1ns/1ps
// ==============================================================================
// File: tb_gls_fault_injection.sv
// Description: Gate-Level Post-Route Fault Injection Verification
//              Validates TMR ALU redundancy and DMR Control Unit checking
//              using force/release on the back-annotated gate-level netlist.
// ==============================================================================

module tb_gls_fault_injection;

    logic clk;
    logic rst_n;

    logic [31:0] imem_addr, imem_rdata;
    logic [31:0] dmem_addr, dmem_wdata, dmem_rdata, pc_debug;
    logic [3:0]  dmem_wmask;
    logic        dmem_we, trap;

    logic tmr_mode_pin;
    logic ecc_sec_1, ecc_ded_1, ecc_sec_2, ecc_ded_2;
    logic tmr_mismatch, tmr_fatal_mismatch;
    logic pc_tmr_mismatch, pc_tmr_fatal_mismatch;
    logic cu_mismatch;

    // 64KB memory
    logic [7:0] memory [0:65535];

    assign imem_rdata = (imem_addr < 65532) ? {memory[imem_addr+3], memory[imem_addr+2],
                                               memory[imem_addr+1], memory[imem_addr]} : 32'h00000013;
    assign dmem_rdata = (dmem_addr < 65532) ? {memory[dmem_addr+3], memory[dmem_addr+2],
                                               memory[dmem_addr+1], memory[dmem_addr]} : 32'h00000000;

    always_ff @(posedge clk) begin
        if (dmem_we) begin
            if (dmem_wmask[0]) memory[dmem_addr]   <= dmem_wdata[7:0];
            if (dmem_wmask[1]) memory[dmem_addr+1] <= dmem_wdata[15:8];
            if (dmem_wmask[2]) memory[dmem_addr+2] <= dmem_wdata[23:16];
            if (dmem_wmask[3]) memory[dmem_addr+3] <= dmem_wdata[31:24];
        end
    end

    // DUT (Post-Route Netlist)
    riscv_core_top dut (
        .clk(clk),
        .rst_n(rst_n),
        .imem_addr(imem_addr),
        .imem_rdata(imem_rdata),
        .dmem_addr(dmem_addr),
        .dmem_wdata(dmem_wdata),
        .dmem_wmask(dmem_wmask),
        .dmem_we(dmem_we),
        .dmem_rdata(dmem_rdata),
        .pc_debug(pc_debug),
        .trap(trap),
        .tmr_mode_pin(tmr_mode_pin),
        .ecc_sec_1(ecc_sec_1),
        .ecc_ded_1(ecc_ded_1),
        .ecc_sec_2(ecc_sec_2),
        .ecc_ded_2(ecc_ded_2),
        .tmr_mismatch(tmr_mismatch),
        .tmr_fatal_mismatch(tmr_fatal_mismatch),
        .pc_tmr_mismatch(pc_tmr_mismatch),
        .pc_tmr_fatal_mismatch(pc_tmr_fatal_mismatch),
        .cu_mismatch(cu_mismatch)
    );

    // Clock generation (100 MHz, 10ns period)
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    // SDF Back-annotation
    initial begin
        `ifdef SDF_ANNOTATE
        $display("[GLS] Back-annotating SDF: cadence/netlist/riscv_core_top_setup.sdf");
        $sdf_annotate("cadence/netlist/riscv_core_top_setup.sdf", dut, , "cadence/reports/gls_sdf.log", "MAXIMUM");
        `endif
    end

    // Helper task to write instruction word
    task automatic write_inst(input int byte_addr, input logic [31:0] instr);
        memory[byte_addr]   = instr[7:0];
        memory[byte_addr+1] = instr[15:8];
        memory[byte_addr+2] = instr[23:16];
        memory[byte_addr+3] = instr[31:24];
    endtask

    int pass_count = 0;
    int fail_count = 0;

    initial begin
        // Initialize memory with NOPs
        for (int i = 0; i < 65536; i += 4) write_inst(i, 32'h00000013);

        // Assembly test program:
        // 0x00: ADDI x1, x0, 15        (x1 = 15)
        write_inst('h00, 32'h00f00093);
        // 0x04: ADDI x2, x0, 25        (x2 = 25)
        write_inst('h04, 32'h01900113);
        // 0x08: ADD  x3, x1, x2        (x3 = 40 = 0x28)
        write_inst('h08, 32'h002081b3);
        // 0x0C: ADD  x4, x1, x2        (x4 = 40)
        write_inst('h0c, 32'h00208233);
        // 0x10: ADD  x5, x1, x2        (x5 = 40)
        write_inst('h10, 32'h002082b3);
        // 0x14: ADD  x6, x1, x2        (x6 = 40)
        write_inst('h14, 32'h00208333);
        // 0x18: ADD  x7, x1, x2        (x7 = 40)
        write_inst('h18, 32'h002083b3);
        // 0x1C: SW   x3, 100(x0)       (mem[100] = 40)
        write_inst('h1c, 32'h06302223);
        // 0x20: EBREAK
        write_inst('h20, 32'h00100073);

        tmr_mode_pin = 1'b1; // Active TMR mode
        rst_n = 1'b0;
        #50;
        rst_n = 1'b1;

        $display("==================================================================");
        $display(" CADENCE GATE-LEVEL POST-ROUTE FAULT INJECTION TESTBENCH (GLS)");
        $display(" Netlist: cadence/netlist/riscv_core_top_pr.v");
        $display(" Corner : GPDK 90nm Slow (0.9V, 125C) with Post-Route SDF Timing");
        $display("==================================================================");

        // ----------------------------------------------------------------------
        // Test 1: Fault Injection on ALU 0 (Force bit flip in u_alu_0.result)
        // ----------------------------------------------------------------------
        $display("\n[TEST 1] Force Fault on ALU Replica 0 (u_alu_0)...");
        // Wait until instruction at 0x08 (ADD x3, x1, x2) reaches ID/EX
        wait(imem_addr >= 32'h00000008);
        @(posedge clk); // 0x08 moves from IF to ID/EX
        @(negedge clk);
        force dut.u_id_ex_stage.u_alu_0.result[3] = 1'b0; // Correct bit 3 is 1 (40 = 0x28 = 8'b00101000)
        #2; // allow gate settling

        if (dut.u_id_ex_stage.u_adaptive_redundancy_controller.u_tmr_voter.result == 32'd40 &&
            dut.u_id_ex_stage.u_adaptive_redundancy_controller.u_tmr_voter.mismatch_detected == 1'b1 &&
            dut.u_id_ex_stage.u_adaptive_redundancy_controller.u_tmr_voter.tmr_fatal_mismatch == 1'b0) begin
            $display("  -> [PASS] ALU0 Fault cleanly masked by TMR voter! Result=40, mismatch=1, fatal=0");
            pass_count++;
        end else begin
            $display("  -> [FAIL] ALU0 Voter output corrupted or mismatch missed! result=%0d, mismatch=%b",
                     dut.u_id_ex_stage.u_adaptive_redundancy_controller.u_tmr_voter.result,
                     dut.u_id_ex_stage.u_adaptive_redundancy_controller.u_tmr_voter.mismatch_detected);
            fail_count++;
        end
        release dut.u_id_ex_stage.u_alu_0.result[3];

        // ----------------------------------------------------------------------
        // Test 2: Fault Injection on ALU 1 (Force bit flip in u_alu_1.result)
        // ----------------------------------------------------------------------
        $display("\n[TEST 2] Force Fault on ALU Replica 1 (u_alu_1)...");
        @(posedge clk);
        @(negedge clk);
        force dut.u_id_ex_stage.u_alu_1.result[5] = 1'b0; // Correct bit 5 is 1 (40 = 0x28 = 0b00101000)
        #2;

        if (dut.u_id_ex_stage.u_adaptive_redundancy_controller.u_tmr_voter.result == 32'd40 &&
            dut.u_id_ex_stage.u_adaptive_redundancy_controller.u_tmr_voter.mismatch_detected == 1'b1 &&
            dut.u_id_ex_stage.u_adaptive_redundancy_controller.u_tmr_voter.tmr_fatal_mismatch == 1'b0) begin
            $display("  -> [PASS] ALU1 Fault cleanly masked by TMR voter! Result=40, mismatch=1, fatal=0");
            pass_count++;
        end else begin
            $display("  -> [FAIL] ALU1 Voter output corrupted or mismatch missed! result=%0d, mismatch=%b",
                     dut.u_id_ex_stage.u_adaptive_redundancy_controller.u_tmr_voter.result,
                     dut.u_id_ex_stage.u_adaptive_redundancy_controller.u_tmr_voter.mismatch_detected);
            fail_count++;
        end
        release dut.u_id_ex_stage.u_alu_1.result[5];

        // ----------------------------------------------------------------------
        // Test 3: Fault Injection on ALU 2 (Force bit flip in u_alu_2.result)
        // ----------------------------------------------------------------------
        $display("\n[TEST 3] Force Fault on ALU Replica 2 (u_alu_2)...");
        @(posedge clk);
        @(negedge clk);
        force dut.u_id_ex_stage.u_alu_2.result[3] = 1'b0;
        #2;

        if (dut.u_id_ex_stage.u_adaptive_redundancy_controller.u_tmr_voter.result == 32'd40 &&
            dut.u_id_ex_stage.u_adaptive_redundancy_controller.u_tmr_voter.mismatch_detected == 1'b1 &&
            dut.u_id_ex_stage.u_adaptive_redundancy_controller.u_tmr_voter.tmr_fatal_mismatch == 1'b0) begin
            $display("  -> [PASS] ALU2 Fault cleanly masked by TMR voter! Result=40, mismatch=1, fatal=0");
            pass_count++;
        end else begin
            $display("  -> [FAIL] ALU2 Voter output corrupted or mismatch missed! result=%0d, mismatch=%b",
                     dut.u_id_ex_stage.u_adaptive_redundancy_controller.u_tmr_voter.result,
                     dut.u_id_ex_stage.u_adaptive_redundancy_controller.u_tmr_voter.mismatch_detected);
            fail_count++;
        end
        release dut.u_id_ex_stage.u_alu_2.result[3];

        // ----------------------------------------------------------------------
        // Test 4: Control Unit DMR Mismatch on reg_write
        // ----------------------------------------------------------------------
        $display("\n[TEST 4] Force Control Unit DMR Mismatch (chk_reg_write)...");
        @(posedge clk);
        @(negedge clk);
        force dut.u_id_ex_stage.chk_reg_write = ~dut.u_id_ex_stage.ctrl_reg_write;
        #2;

        if (dut.u_id_ex_stage.cu_mismatch == 1'b1 && dut.trap == 1'b1) begin
            $display("  -> [PASS] CU mismatch asserted (%b) and trap asserted (%b) on decoder discrepancy!",
                     dut.u_id_ex_stage.cu_mismatch, dut.trap);
            pass_count++;
        end else begin
            $display("  -> [FAIL] CU mismatch not asserted! cu_mismatch=%b, trap=%b",
                     dut.u_id_ex_stage.cu_mismatch, dut.trap);
            fail_count++;
        end
        release dut.u_id_ex_stage.chk_reg_write;

        // ----------------------------------------------------------------------
        // Test 5: Control Unit DMR Mismatch on mem_write & Fail-Safe Clamping
        // ----------------------------------------------------------------------
        $display("\n[TEST 5] Force Primary mem_write during non-store & Verify Clamping...");
        @(posedge clk);
        @(negedge clk);
        force dut.u_id_ex_stage.ctrl_mem_write = 1'b1; // Illegal store during ADD
        #2;

        if (dut.u_id_ex_stage.cu_mismatch == 1'b1 && dut.dmem_we == 1'b0 && dut.trap == 1'b1) begin
            $display("  -> [PASS] Illegal mem_write clamped to 0! dmem_we=%b, cu_mismatch=%b, trap=%b",
                     dut.dmem_we, dut.u_id_ex_stage.cu_mismatch, dut.trap);
            pass_count++;
        end else begin
            $display("  -> [FAIL] Clamping failed! dmem_we=%b, cu_mismatch=%b, trap=%b",
                     dut.dmem_we, dut.u_id_ex_stage.cu_mismatch, dut.trap);
            fail_count++;
        end
        release dut.u_id_ex_stage.ctrl_mem_write;

        #50;
        $display("\n==================================================================");
        $display(" GLS FAULT INJECTION SUMMARY: Tested=%0d, Passed=%0d, Failed=%0d",
                 (pass_count + fail_count), pass_count, fail_count);
        $display("==================================================================");

        if (fail_count == 0) begin
            $display(">>> ALL GATE-LEVEL FAULT INJECTION TESTS PASSED! <<<");
        end else begin
            $display(">>> GLS FAULT INJECTION SUITE FAILED! <<<");
        end

        $finish;
    end

    // Watchdog
    initial begin
        #5000;
        $display("[TIMEOUT] GLS testbench timed out!");
        $finish;
    end

endmodule
