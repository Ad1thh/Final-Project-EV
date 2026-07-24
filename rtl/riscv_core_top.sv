// ============================================================================
// File: riscv_core_top.sv
// Description: Top-Level Module for 3-Stage Pipelined RV32E Core.
//              Integrates Stage 1 (Fetch), Stage 2 (Decode/Execute), and
//              Stage 3 (Writeback) into an ASIC-synthesizable pipeline.
// Standards: SystemVerilog-2012 / Cadence Genus & Xcelium Compatible
// ============================================================================

import riscv_pkg::*;

module riscv_core_top #(
    parameter int DATA_WIDTH = 32,
    parameter int REG_COUNT  = 16,
    parameter int ADDR_WIDTH = 4
)(
    input  logic        clk,
    input  logic        rst_n,
    
    // Instruction Memory Interface
    output logic [31:0] imem_addr,
    input  logic [31:0] imem_rdata,
    
    // Data Memory Interface
    output logic [31:0] dmem_addr,
    output logic [31:0] dmem_wdata,
    output logic [3:0]  dmem_wmask,
    output logic        dmem_we,
    input  logic [31:0] dmem_rdata,
    
    // Debug & Exception Signals
    output logic [31:0] pc_debug,
    output logic        trap
);

    // ------------------------------------------------------------------------
    // INTER-STAGE PIPELINE & CONTROL SIGNALS
    // ------------------------------------------------------------------------
    // Stage 1 (IF) -> Stage 2 (ID/EX)
    logic [DATA_WIDTH-1:0] pc_id;
    logic [DATA_WIDTH-1:0] instr_id;

    // Stage 2 (ID/EX) -> Stage 1 (IF) Redirection & Hazard
    logic                  branch_or_jump_taken;
    logic [DATA_WIDTH-1:0] target_pc;
    logic                  stall_if;
    logic                  flush_if_id;

    // Stage 2 (ID/EX) -> Stage 3 (WB) Pipeline Register Outputs
    logic [DATA_WIDTH-1:0] pc_wb;
    logic [DATA_WIDTH-1:0] alu_result_wb;
    logic [DATA_WIDTH-1:0] dmem_rdata_raw_wb;
    logic [ADDR_WIDTH-1:0] rd_wb;
    logic                  reg_write_wb;
    wb_sel_e               wb_sel_wb;
    logic [2:0]            funct3_wb;

    // Stage 3 (WB) -> Stage 2 (ID/EX) Writeback & Forwarding Feedback
    logic [DATA_WIDTH-1:0] wb_result;

    // Debug output assignment
    assign pc_debug = imem_addr;

    // ------------------------------------------------------------------------
    // STAGE 1: FETCH (IF)
    // ------------------------------------------------------------------------
    if_stage #(
        .DATA_WIDTH (DATA_WIDTH)
    ) u_if_stage (
        .clk                  (clk),
        .rst_n                (rst_n),
        .branch_or_jump_taken (branch_or_jump_taken),
        .target_pc            (target_pc),
        .stall_if             (stall_if),
        .flush_if_id          (flush_if_id),
        .imem_addr            (imem_addr),
        .imem_rdata           (imem_rdata),
        .pc_id                (pc_id),
        .instr_id             (instr_id)
    );

    // ------------------------------------------------------------------------
    // STAGE 2: DECODE & EXECUTE (ID/EX)
    // ------------------------------------------------------------------------
    id_ex_stage #(
        .DATA_WIDTH (DATA_WIDTH),
        .REG_COUNT  (REG_COUNT),
        .ADDR_WIDTH (ADDR_WIDTH)
    ) u_id_ex_stage (
        .clk                  (clk),
        .rst_n                (rst_n),
        .pc_id                (pc_id),
        .instr_id             (instr_id),
        .wb_reg_write         (reg_write_wb),
        .wb_rd                (rd_wb),
        .wb_result            (wb_result),
        .dmem_addr            (dmem_addr),
        .dmem_wdata           (dmem_wdata),
        .dmem_wmask           (dmem_wmask),
        .dmem_we              (dmem_we),
        .dmem_rdata           (dmem_rdata),
        .branch_or_jump_taken (branch_or_jump_taken),
        .target_pc            (target_pc),
        .stall_if             (stall_if),
        .flush_if_id          (flush_if_id),
        .pc_wb                (pc_wb),
        .alu_result_wb        (alu_result_wb),
        .dmem_rdata_raw_wb    (dmem_rdata_raw_wb),
        .rd_wb                (rd_wb),
        .reg_write_wb         (reg_write_wb),
        .wb_sel_wb            (wb_sel_wb),
        .funct3_wb            (funct3_wb),
        .trap                 (trap)
    );

    // ------------------------------------------------------------------------
    // STAGE 3: WRITEBACK (WB)
    // ------------------------------------------------------------------------
    wb_stage #(
        .DATA_WIDTH (DATA_WIDTH)
    ) u_wb_stage (
        .pc_wb             (pc_wb),
        .alu_result_wb     (alu_result_wb),
        .dmem_rdata_raw_wb (dmem_rdata_raw_wb),
        .wb_sel_wb         (wb_sel_wb),
        .funct3_wb         (funct3_wb),
        .wb_result         (wb_result)
    );

endmodule
