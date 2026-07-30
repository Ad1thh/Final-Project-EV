`timescale 1ns/1ps
// ============================================================================
// File: id_ex_stage.sv
// Description: Decode & Execute Stage (Stage 2) for 3-Stage RISC-V Core.
//              Integrates Register File, Control Unit, ALU, Hazard Unit,
//              Immediate Generator, Branch Evaluator, and EX/WB pipeline reg.
//              Includes Selective TMR Execution and Fault Injection Hooks.
// Standards: SystemVerilog-2012 / Cadence Genus Synthesizable
// ============================================================================

import riscv_pkg::*;

module id_ex_stage #(
    parameter int DATA_WIDTH = 32,
    parameter int REG_COUNT  = 16,
    parameter int ADDR_WIDTH = 4
)(
    input  logic                  clk,
    input  logic                  rst_n,
    
    // Stage 1 Inputs
    input  logic [DATA_WIDTH-1:0] pc_id,
    input  logic [DATA_WIDTH-1:0] instr_id,
    
    // Stage 3 Writeback Feedback (For Forwarding & Write Port)
    input  logic                  wb_reg_write,
    input  logic [ADDR_WIDTH-1:0] wb_rd,
    input  logic [DATA_WIDTH-1:0] wb_result,
    
    // External Data Memory Interface Signals
    output logic [DATA_WIDTH-1:0] dmem_addr,
    output logic [DATA_WIDTH-1:0] dmem_wdata,
    output logic [3:0]            dmem_wmask,
    output logic                  dmem_we,
    input  logic [DATA_WIDTH-1:0] dmem_rdata,
    
    // Control & Hazard Outputs to Stage 1 (IF Stage)
    output logic                  branch_or_jump_taken,
    output logic [DATA_WIDTH-1:0] target_pc,
    output logic                  stall_if,
    output logic                  flush_if_id,
    
    // Pipeline Outputs to Stage 3 (WB Stage)
    output logic [DATA_WIDTH-1:0] pc_wb,
    output logic [DATA_WIDTH-1:0] alu_result_wb,
    output logic [DATA_WIDTH-1:0] dmem_rdata_raw_wb,
    output logic [ADDR_WIDTH-1:0] rd_wb,
    output logic                  reg_write_wb,
    output wb_sel_e               wb_sel_wb,
    output logic [2:0]            funct3_wb,
    output logic                  trap,

    // Fault Tolerance Mode & Injection Interfaces
    input  logic                  tmr_mode,
    input  logic                  fi_reg_en,
    input  logic [ADDR_WIDTH-1:0] fi_reg_addr,
    input  logic [5:0]            fi_reg_bit,
    input  logic                  fi_alu_en,
    input  logic [1:0]            fi_alu_sel,
    input  logic [4:0]            fi_alu_bit,
    
    // Fault Tolerance Status Outputs
    output logic                  ecc_sec_1,
    output logic                  ecc_ded_1,
    output logic                  ecc_sec_2,
    output logic                  ecc_ded_2,
    output logic                  tmr_mismatch,
    output logic                  tmr_fatal_mismatch
);

    // ------------------------------------------------------------------------
    // FIELD EXTRACTIONS
    // ------------------------------------------------------------------------
    logic [6:0]            opcode;
    logic [2:0]            funct3;
    logic [6:0]            funct7;
    logic [ADDR_WIDTH-1:0] rs1_addr;
    logic [ADDR_WIDTH-1:0] rs2_addr;
    logic [ADDR_WIDTH-1:0] rd_addr;

    assign opcode   = instr_id[6:0];
    assign funct3   = instr_id[14:12];
    assign funct7   = instr_id[31:25];
    assign rd_addr  = instr_id[10:7];  // Bits [11:7] sliced to 4 bits for RV32E (x0-x15)
    assign rs1_addr = instr_id[18:15]; // Bits [19:15] sliced to 4 bits for RV32E (x0-x15)
    assign rs2_addr = instr_id[23:20]; // Bits [24:20] sliced to 4 bits for RV32E (x0-x15)

    // ------------------------------------------------------------------------
    // IMMEDIATE GENERATOR
    // ------------------------------------------------------------------------
    logic [DATA_WIDTH-1:0] imm_i, imm_s, imm_b, imm_u, imm_j;
    logic [DATA_WIDTH-1:0] imm_selected;

    assign imm_i = {{20{instr_id[31]}}, instr_id[31:20]};
    assign imm_s = {{20{instr_id[31]}}, instr_id[31:25], instr_id[11:7]};
    assign imm_b = {{19{instr_id[31]}}, instr_id[31], instr_id[7], instr_id[30:25], instr_id[11:8], 1'b0};
    assign imm_u = {instr_id[31:12], 12'b0};
    assign imm_j = {{11{instr_id[31]}}, instr_id[31], instr_id[19:12], instr_id[20], instr_id[30:21], 1'b0};

    always_comb begin
        if (opcode == OPCODE_I_TYPE || opcode == OPCODE_LOAD || opcode == OPCODE_JALR)
            imm_selected = imm_i;
        else if (opcode == OPCODE_STORE)
            imm_selected = imm_s;
        else if (opcode == OPCODE_BRANCH)
            imm_selected = imm_b;
        else if (opcode == OPCODE_LUI || opcode == OPCODE_AUIPC)
            imm_selected = imm_u;
        else if (opcode == OPCODE_JAL)
            imm_selected = imm_j;
        else
            imm_selected = imm_i;
    end

    // ------------------------------------------------------------------------
    // CONTROL UNIT INSTANTIATION
    // ------------------------------------------------------------------------
    logic       ctrl_reg_write;
    logic       ctrl_mem_read;
    logic       ctrl_mem_write;
    alu_op_e    ctrl_alu_op;
    logic       ctrl_alu_src_a;
    logic       ctrl_alu_src_b;
    wb_sel_e    ctrl_wb_sel;
    logic       ctrl_is_branch;
    logic       ctrl_is_jal;
    logic       ctrl_is_jalr;

    control_unit u_control_unit (
        .opcode    (opcode),
        .funct3    (funct3),
        .funct7    (funct7),
        .reg_write (ctrl_reg_write),
        .mem_read  (ctrl_mem_read),
        .mem_write (ctrl_mem_write),
        .alu_op    (ctrl_alu_op),
        .alu_src_a (ctrl_alu_src_a),
        .alu_src_b (ctrl_alu_src_b),
        .wb_sel    (ctrl_wb_sel),
        .is_branch (ctrl_is_branch),
        .is_jal    (ctrl_is_jal),
        .is_jalr   (ctrl_is_jalr),
        .trap      (trap)
    );

    // ------------------------------------------------------------------------
    // REGISTER FILE INSTANTIATION
    // ------------------------------------------------------------------------
    logic [DATA_WIDTH-1:0] reg_rdata1, reg_rdata2;

    regfile #(
        .DATA_WIDTH (DATA_WIDTH),
        .REG_COUNT  (REG_COUNT),
        .ADDR_WIDTH (ADDR_WIDTH)
    ) u_regfile (
        .clk                    (clk),
        .rst_n                  (rst_n),
        .raddr1                 (rs1_addr),
        .rdata1                 (reg_rdata1),
        .single_err_corrected_1 (ecc_sec_1),
        .double_err_detected_1  (ecc_ded_1),
        .raddr2                 (rs2_addr),
        .rdata2                 (reg_rdata2),
        .single_err_corrected_2 (ecc_sec_2),
        .double_err_detected_2  (ecc_ded_2),
        .we                     (wb_reg_write),
        .waddr                  (wb_rd),
        .wdata                  (wb_result),
        .fi_reg_en              (fi_reg_en),
        .fi_reg_addr            (fi_reg_addr),
        .fi_reg_bit             (fi_reg_bit)
    );

    // ------------------------------------------------------------------------
    // HAZARD DETECTION UNIT
    // ------------------------------------------------------------------------
    logic flush_id_ex;

    hazard_unit #(
        .ADDR_WIDTH (ADDR_WIDTH)
    ) u_hazard_unit (
        .id_rs1               (rs1_addr),
        .id_rs2               (rs2_addr),
        .id_ex_rd             (rd_wb),          // EX/WB pipeline reg RD
        .id_ex_mem_read       (reg_write_wb && (wb_sel_wb == WB_SEL_MEM)),
        .branch_or_jump_taken (branch_or_jump_taken),
        .stall_if             (stall_if),
        .flush_if_id          (flush_if_id),
        .flush_id_ex          (flush_id_ex)
    );

    // ------------------------------------------------------------------------
    // OPERAND MUXES (Forwarding removed due to regfile bypass)
    // ------------------------------------------------------------------------
    logic [DATA_WIDTH-1:0] alu_in_a;
    logic [DATA_WIDTH-1:0] alu_in_b;
    logic [DATA_WIDTH-1:0] alu_in_a_tmr;
    logic [DATA_WIDTH-1:0] alu_in_b_tmr;

    assign alu_in_a = (ctrl_alu_src_a) ? pc_id : reg_rdata1;
    assign alu_in_b = (ctrl_alu_src_b) ? imm_selected : reg_rdata2;

    // Operand Isolation for Simplex Mode
    assign alu_in_a_tmr = (tmr_mode) ? alu_in_a : '0;
    assign alu_in_b_tmr = (tmr_mode) ? alu_in_b : '0;

    // ------------------------------------------------------------------------
    // SELECTIVE TMR ALU INSTANTIATIONS & FAULT INJECTION
    // ------------------------------------------------------------------------
    logic [DATA_WIDTH-1:0] alu_result_0, alu_result_1, alu_result_2;
    logic                  alu_zero_0, alu_zero_1, alu_zero_2;
    logic [DATA_WIDTH-1:0] alu_result_0_fi, alu_result_1_fi, alu_result_2_fi;

    alu #(.DATA_WIDTH(DATA_WIDTH)) u_alu_0 (
        .a(alu_in_a), .b(alu_in_b), .alu_op(ctrl_alu_op), .result(alu_result_0), .zero(alu_zero_0)
    );

    alu #(.DATA_WIDTH(DATA_WIDTH)) u_alu_1 (
        .a(alu_in_a_tmr), .b(alu_in_b_tmr), .alu_op(ctrl_alu_op), .result(alu_result_1), .zero(alu_zero_1)
    );

    alu #(.DATA_WIDTH(DATA_WIDTH)) u_alu_2 (
        .a(alu_in_a_tmr), .b(alu_in_b_tmr), .alu_op(ctrl_alu_op), .result(alu_result_2), .zero(alu_zero_2)
    );

    // Fault Injection Masks
    logic [DATA_WIDTH-1:0] fi_mask;
    assign fi_mask = (fi_alu_en) ? (32'd1 << fi_alu_bit) : '0;

    assign alu_result_0_fi = alu_result_0 ^ ((fi_alu_sel == 2'd0) ? fi_mask : '0);
    assign alu_result_1_fi = alu_result_1 ^ ((fi_alu_sel == 2'd1) ? fi_mask : '0);
    assign alu_result_2_fi = alu_result_2 ^ ((fi_alu_sel == 2'd2) ? fi_mask : '0);

    // TMR Voter
    logic [DATA_WIDTH-1:0] voter_result;
    logic                  voter_mismatch;
    logic                  voter_fatal_mismatch;

    tmr_voter #(.WIDTH(DATA_WIDTH)) u_tmr_voter (
        .a(alu_result_0_fi),
        .b(alu_result_1_fi),
        .c(alu_result_2_fi),
        .result(voter_result),
        .mismatch_detected(voter_mismatch),
        .tmr_fatal_mismatch(voter_fatal_mismatch)
    );

    logic [DATA_WIDTH-1:0] alu_result;
    
    // Select final output based on mode
    assign alu_result   = (tmr_mode) ? voter_result : alu_result_0_fi;
    assign tmr_mismatch = (tmr_mode) ? voter_mismatch : 1'b0;
    assign tmr_fatal_mismatch = (tmr_mode) ? voter_fatal_mismatch : 1'b0;

    // ------------------------------------------------------------------------
    // BRANCH CONDITION EVALUATION & TARGET CALCULATION
    // ------------------------------------------------------------------------
    logic branch_condition_met;

    always_comb begin
        if (funct3 == FUNCT3_BEQ)  branch_condition_met = (reg_rdata1 == reg_rdata2);
        else if (funct3 == FUNCT3_BNE)  branch_condition_met = (reg_rdata1 != reg_rdata2);
        else if (funct3 == FUNCT3_BLT)  branch_condition_met = ($signed(reg_rdata1) < $signed(reg_rdata2));
        else if (funct3 == FUNCT3_BGE)  branch_condition_met = ($signed(reg_rdata1) >= $signed(reg_rdata2));
        else if (funct3 == FUNCT3_BLTU) branch_condition_met = (reg_rdata1 < reg_rdata2);
        else if (funct3 == FUNCT3_BGEU) branch_condition_met = (reg_rdata1 >= reg_rdata2);
        else                            branch_condition_met = 1'b0;
    end

    assign branch_or_jump_taken = (ctrl_is_branch & branch_condition_met) | ctrl_is_jal | ctrl_is_jalr;

    always_comb begin
        if (ctrl_is_jalr)
            target_pc = (reg_rdata1 + imm_i) & ~32'd1;
        else if (ctrl_is_jal)
            target_pc = pc_id + imm_j;
        else
            target_pc = pc_id + imm_b;
    end

    // ------------------------------------------------------------------------
    // DATA MEMORY INTERFACE GENERATION
    // ------------------------------------------------------------------------
    assign dmem_addr = alu_result;

    always_comb begin
        if (funct3 == FUNCT3_SB) begin
            dmem_wmask = 4'b0001 << alu_result[1:0];
            dmem_wdata = reg_rdata2 << (8 * alu_result[1:0]);
        end else if (funct3 == FUNCT3_SH) begin
            dmem_wmask = 4'b0011 << alu_result[1:0];
            dmem_wdata = reg_rdata2 << (8 * alu_result[1:0]);
        end else if (funct3 == FUNCT3_SW) begin
            dmem_wmask = 4'b1111;
            dmem_wdata = reg_rdata2;
        end else begin
            dmem_wmask = 4'b0000;
            dmem_wdata = '0;
        end
    end

    assign dmem_we = ctrl_mem_write & ~flush_id_ex;

    // ------------------------------------------------------------------------
    // EX/WB PIPELINE REGISTER
    // ------------------------------------------------------------------------
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n || flush_id_ex) begin
            pc_wb            <= '0;
            alu_result_wb    <= '0;
            dmem_rdata_raw_wb<= '0;
            rd_wb            <= '0;
            reg_write_wb     <= 1'b0;
            wb_sel_wb        <= WB_SEL_ALU;
            funct3_wb        <= '0;
        end else begin
            pc_wb            <= pc_id;
            alu_result_wb    <= alu_result;
            dmem_rdata_raw_wb<= dmem_rdata;
            rd_wb            <= rd_addr;
            reg_write_wb     <= ctrl_reg_write;
            wb_sel_wb        <= ctrl_wb_sel;
            funct3_wb        <= funct3;
        end
    end

endmodule
