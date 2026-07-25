// ============================================================================
// File: id_ex_stage.sv
// Description: Decode & Execute Stage (Stage 2) for 3-Stage RISC-V Core.
//              Integrates Register File, Control Unit, ALU, Hazard Unit,
//              Immediate Generator, Branch Evaluator, and EX/WB pipeline reg.
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
    output logic                  trap
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
        case (opcode)
            OPCODE_I_TYPE, OPCODE_LOAD, OPCODE_JALR: imm_selected = imm_i;
            OPCODE_STORE:                              imm_selected = imm_s;
            OPCODE_BRANCH:                             imm_selected = imm_b;
            OPCODE_LUI, OPCODE_AUIPC:                  imm_selected = imm_u;
            OPCODE_JAL:                                imm_selected = imm_j;
            default:                                   imm_selected = imm_i;
        endcase
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
        .clk    (clk),
        .rst_n  (rst_n),
        .raddr1 (rs1_addr),
        .rdata1 (reg_rdata1),
        .raddr2 (rs2_addr),
        .rdata2 (reg_rdata2),
        .we     (wb_reg_write),
        .waddr  (wb_rd),
        .wdata  (wb_result)
    );

    // ------------------------------------------------------------------------
    // HAZARD DETECTION & FORWARDING UNIT
    // ------------------------------------------------------------------------
    logic forward_a, forward_b;
    logic flush_id_ex;

    hazard_unit #(
        .ADDR_WIDTH (ADDR_WIDTH)
    ) u_hazard_unit (
        .id_rs1               (rs1_addr),
        .id_rs2               (rs2_addr),
        .id_ex_rd             (rd_wb),          // EX/WB pipeline reg RD
        .id_ex_mem_read       (reg_write_wb && (wb_sel_wb == WB_SEL_MEM)),
        .wb_rd                (wb_rd),
        .wb_reg_write         (wb_reg_write),
        .branch_or_jump_taken (branch_or_jump_taken),
        .forward_a            (forward_a),
        .forward_b            (forward_b),
        .stall_if             (stall_if),
        .flush_if_id          (flush_if_id),
        .flush_id_ex          (flush_id_ex)
    );

    // ------------------------------------------------------------------------
    // FORWARDING & OPERAND MUXES
    // ------------------------------------------------------------------------
    logic [DATA_WIDTH-1:0] op_a_forwarded;
    logic [DATA_WIDTH-1:0] op_b_forwarded;
    logic [DATA_WIDTH-1:0] alu_in_a;
    logic [DATA_WIDTH-1:0] alu_in_b;

    assign op_a_forwarded = (forward_a) ? wb_result : reg_rdata1;
    assign op_b_forwarded = (forward_b) ? wb_result : reg_rdata2;

    assign alu_in_a = (ctrl_alu_src_a) ? pc_id : op_a_forwarded;
    assign alu_in_b = (ctrl_alu_src_b) ? imm_selected : op_b_forwarded;

    // ------------------------------------------------------------------------
    // ALU INSTANTIATION
    // ------------------------------------------------------------------------
    logic [DATA_WIDTH-1:0] alu_result;
    logic                  alu_zero;

    alu #(
        .DATA_WIDTH (DATA_WIDTH)
    ) u_alu (
        .a      (alu_in_a),
        .b      (alu_in_b),
        .alu_op (ctrl_alu_op),
        .result (alu_result),
        .zero   (alu_zero)
    );

    // ------------------------------------------------------------------------
    // BRANCH CONDITION EVALUATION & TARGET CALCULATION
    // ------------------------------------------------------------------------
    logic branch_condition_met;

    always_comb begin
        case (funct3)
            FUNCT3_BEQ:  branch_condition_met = (op_a_forwarded == op_b_forwarded);
            FUNCT3_BNE:  branch_condition_met = (op_a_forwarded != op_b_forwarded);
            FUNCT3_BLT:  branch_condition_met = ($signed(op_a_forwarded) < $signed(op_b_forwarded));
            FUNCT3_BGE:  branch_condition_met = ($signed(op_a_forwarded) >= $signed(op_b_forwarded));
            FUNCT3_BLTU: branch_condition_met = (op_a_forwarded < op_b_forwarded);
            FUNCT3_BGEU: branch_condition_met = (op_a_forwarded >= op_b_forwarded);
            default:     branch_condition_met = 1'b0;
        endcase
    end

    assign branch_or_jump_taken = (ctrl_is_branch & branch_condition_met) | ctrl_is_jal | ctrl_is_jalr;

    always_comb begin
        if (ctrl_is_jalr) begin
            target_pc = (op_a_forwarded + imm_i) & ~32'd1;
        end else if (ctrl_is_jal) begin
            target_pc = pc_id + imm_j;
        end else begin
            target_pc = pc_id + imm_b;
        end
    end

    // ------------------------------------------------------------------------
    // DATA MEMORY INTERFACE GENERATION
    // ------------------------------------------------------------------------
    assign dmem_addr = alu_result;

    always_comb begin
        case (funct3)
            FUNCT3_SB: begin
                dmem_wmask = 4'b0001 << alu_result[1:0];
                dmem_wdata = op_b_forwarded << (8 * alu_result[1:0]);
            end
            FUNCT3_SH: begin
                dmem_wmask = 4'b0011 << alu_result[1:0];
                dmem_wdata = op_b_forwarded << (8 * alu_result[1:0]);
            end
            FUNCT3_SW: begin
                dmem_wmask = 4'b1111;
                dmem_wdata = op_b_forwarded;
            end
            default: begin
                dmem_wmask = 4'b0000;
                dmem_wdata = '0;
            end
        endcase
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
