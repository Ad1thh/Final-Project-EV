`timescale 1ns/1ps
// ============================================================================
// File: adaptive_redundancy_controller.sv
// Description: Adaptive Redundancy Controller for Processor Execute Stage.
//              Manages transition between Simplex Mode (lowest power, EX0 active,
//              EX1/EX2 clock-gated & operand-isolated) and TMR Mode (maximum
//              reliability, EX0/EX1/EX2 active with 3-input majority voting).
// Standards: SystemVerilog-2012 / ASIC & FPGA Synthesizable
// ============================================================================

import riscv_pkg::*;

module adaptive_redundancy_controller #(
    parameter int DATA_WIDTH = 32
)(
    input  logic                  clk,
    input  logic                  rst_n,
    
    // Control Mode Selection Inputs
    input  logic                  tmr_mode_pin,      // External control pin
    input  logic                  sw_tmr_mode_reg,   // Software register bit
    
    // Primary Execute Unit (EX0) Operands
    input  logic [DATA_WIDTH-1:0] alu_in_a,
    input  logic [DATA_WIDTH-1:0] alu_in_b,
    input  logic [3:0]            ctrl_alu_op,
    
    // Isolated Operands for Redundant Execute Units (EX1 & EX2)
    output logic [DATA_WIDTH-1:0] alu_in_a_ex1,
    output logic [DATA_WIDTH-1:0] alu_in_b_ex1,
    output logic [3:0]            ctrl_alu_op_ex1,
    
    output logic [DATA_WIDTH-1:0] alu_in_a_ex2,
    output logic [DATA_WIDTH-1:0] alu_in_b_ex2,
    output logic [3:0]            ctrl_alu_op_ex2,
    
    // Clock Gating Outputs for Redundant Execute Units
    output logic                  gated_clk_ex1,
    output logic                  gated_clk_ex2,
    
    // Raw/Fault-Injected Execution Results from EX0, EX1, EX2
    input  logic [DATA_WIDTH-1:0] alu_result_0_fi,
    input  logic [DATA_WIDTH-1:0] alu_result_1_fi,
    input  logic [DATA_WIDTH-1:0] alu_result_2_fi,
    
    // Resolved Output & Fault Status Flags
    output logic [DATA_WIDTH-1:0] alu_result,
    output logic                  tmr_mismatch,
    output logic                  tmr_fatal_mismatch,
    
    // Mode Status Output
    output logic                  tmr_mode_active
);

    // Dynamic Mode Resolution: Active TMR mode if hardware pin OR software register is set
    assign tmr_mode_active = tmr_mode_pin | sw_tmr_mode_reg;

    // ------------------------------------------------------------------------
    // CLOCK GATING INSTANTIATIONS FOR EX1 AND EX2
    // ------------------------------------------------------------------------
    clock_gater u_cg_ex1 (
        .clk       (clk),
        .enable    (tmr_mode_active),
        .test_mode (1'b0),
        .gated_clk (gated_clk_ex1)
    );

    clock_gater u_cg_ex2 (
        .clk       (clk),
        .enable    (tmr_mode_active),
        .test_mode (1'b0),
        .gated_clk (gated_clk_ex2)
    );

    // ------------------------------------------------------------------------
    // OPERAND ISOLATION FOR SIMPLEX MODE
    // ------------------------------------------------------------------------
    // When tmr_mode_active == 0 (Simplex Mode):
    // Data inputs to EX1 and EX2 are clamped to zero, and opcodes are clamped to
    // neutral ALU_ADD (4'd0) to freeze dynamic logic toggling and eliminate switching power.
    always_comb begin
        if (tmr_mode_active) begin
            alu_in_a_ex1    = alu_in_a;
            alu_in_b_ex1    = alu_in_b;
            ctrl_alu_op_ex1 = ctrl_alu_op;
            
            alu_in_a_ex2    = alu_in_a;
            alu_in_b_ex2    = alu_in_b;
            ctrl_alu_op_ex2 = ctrl_alu_op;
        end else begin
            alu_in_a_ex1    = '0;
            alu_in_b_ex1    = '0;
            ctrl_alu_op_ex1 = 4'd0; // Neutral opcode (ALU_ADD)
            
            alu_in_a_ex2    = '0;
            alu_in_b_ex2    = '0;
            ctrl_alu_op_ex2 = 4'd0; // Neutral opcode (ALU_ADD)
        end
    end

    // ------------------------------------------------------------------------
    // MAJORITY VOTER INSTANTIATION
    // ------------------------------------------------------------------------
    logic [DATA_WIDTH-1:0] voter_result;
    logic                  voter_mismatch;
    logic                  voter_fatal_mismatch;

    tmr_voter #(.WIDTH(DATA_WIDTH)) u_tmr_voter (
        .a                  (alu_result_0_fi),
        .b                  (alu_result_1_fi),
        .c                  (alu_result_2_fi),
        .result             (voter_result),
        .mismatch_detected  (voter_mismatch),
        .tmr_fatal_mismatch (voter_fatal_mismatch)
    );

    // ------------------------------------------------------------------------
    // OUTPUT AND MISMATCH STATUS SELECTION
    // ------------------------------------------------------------------------
    // Simplex Mode: Direct bypass from EX0 result, mismatch status masked to 0.
    // TMR Mode: Majority voted result output, mismatch status flags active.
    always_comb begin
        if (tmr_mode_active) begin
            alu_result         = voter_result;
            tmr_mismatch       = voter_mismatch;
            tmr_fatal_mismatch = voter_fatal_mismatch;
        end else begin
            alu_result         = alu_result_0_fi;
            tmr_mismatch       = 1'b0;
            tmr_fatal_mismatch = 1'b0;
        end
    end

endmodule
