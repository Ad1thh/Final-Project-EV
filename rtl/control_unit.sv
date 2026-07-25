// ============================================================================
// File: control_unit.sv
// Description: Main Control Unit Decoder for RV32I Base Instruction Set.
//              Generates execution, memory, register writeback, and branch signals.
// Standards: SystemVerilog-2012 / Cadence Genus Synthesizable
// ============================================================================

import riscv_pkg::*;

module control_unit (
    input  logic [6:0] opcode,
    input  logic [2:0] funct3,
    input  logic [6:0] funct7,
    
    output logic       reg_write,
    output logic       mem_read,
    output logic       mem_write,
    output alu_op_e    alu_op,
    output logic       alu_src_a, // 0: RS1, 1: PC (for AUIPC)
    output logic       alu_src_b, // 0: RS2, 1: Imm
    output wb_sel_e    wb_sel,
    output logic       is_branch,
    output logic       is_jal,
    output logic       is_jalr,
    output logic       trap
);

    always_comb begin
        // Default Signal Values (Latching Prevention)
        reg_write = 1'b0;
        mem_read  = 1'b0;
        mem_write = 1'b0;
        alu_op    = ALU_ADD;
        alu_src_a = 1'b0;
        alu_src_b = 1'b0;
        wb_sel    = WB_SEL_ALU;
        is_branch = 1'b0;
        is_jal    = 1'b0;
        is_jalr   = 1'b0;
        trap      = 1'b0;

        case (opcode)
OPCODE_R_TYPE: begin
                reg_write = 1'b1;
                alu_src_b = 1'b0;
                wb_sel    = WB_SEL_ALU;
                case (funct3)
                    FUNCT3_ADD_SUB: alu_op = (funct7[5]) ? ALU_SUB : ALU_ADD;
                    FUNCT3_SLL:     alu_op = ALU_SLL;
                    FUNCT3_SLT:     alu_op = ALU_SLT;
                    FUNCT3_SLTU:    alu_op = ALU_SLTU;
                    FUNCT3_XOR:     alu_op = ALU_XOR;
                    FUNCT3_SRL_SRA: alu_op = (funct7[5]) ? ALU_SRA : ALU_SRL;
                    FUNCT3_OR:      alu_op = ALU_OR;
                    FUNCT3_AND:     alu_op = ALU_AND;
                    default:        trap   = 1'b1;
                endcase
            end

OPCODE_I_TYPE: begin
                reg_write = 1'b1;
                alu_src_b = 1'b1;
                wb_sel    = WB_SEL_ALU;
                case (funct3)
                    FUNCT3_ADD_SUB: alu_op = ALU_ADD;
                    FUNCT3_SLT:     alu_op = ALU_SLT;
                    FUNCT3_SLTU:    alu_op = ALU_SLTU;
                    FUNCT3_XOR:     alu_op = ALU_XOR;
                    FUNCT3_OR:      alu_op = ALU_OR;
                    FUNCT3_AND:     alu_op = ALU_AND;
                    FUNCT3_SLL:     alu_op = ALU_SLL;
                    FUNCT3_SRL_SRA: alu_op = (funct7[5]) ? ALU_SRA : ALU_SRL;
                    default:        trap   = 1'b1;
                endcase
            end

            OPCODE_LOAD: begin
                reg_write = 1'b1;
                mem_read  = 1'b1;
                alu_src_b = 1'b1;
                alu_op    = ALU_ADD;
                wb_sel    = WB_SEL_MEM;
            end

            OPCODE_STORE: begin
                mem_write = 1'b1;
                alu_src_b = 1'b1;
                alu_op    = ALU_ADD;
            end

            OPCODE_BRANCH: begin
                is_branch = 1'b1;
                alu_src_b = 1'b0;
                alu_op    = ALU_SUB;
            end

            OPCODE_JAL: begin
                reg_write = 1'b1;
                is_jal    = 1'b1;
                wb_sel    = WB_SEL_PC4;
            end

            OPCODE_JALR: begin
                reg_write = 1'b1;
                is_jalr   = 1'b1;
                alu_src_b = 1'b1;
                alu_op    = ALU_ADD;
                wb_sel    = WB_SEL_PC4;
            end

            OPCODE_LUI: begin
                reg_write = 1'b1;
                alu_src_b = 1'b1;
                alu_op    = ALU_PASS_B;
                wb_sel    = WB_SEL_ALU;
            end

            OPCODE_AUIPC: begin
                reg_write = 1'b1;
                alu_src_a = 1'b1; // PC
                alu_src_b = 1'b1; // Imm
                alu_op    = ALU_ADD;
                wb_sel    = WB_SEL_ALU;
            end

            OPCODE_SYSTEM: begin
                // ECALL / EBREAK trigger trap signal
                trap = 1'b1;
            end

            default: begin
                trap = 1'b1;
            end
        endcase
    end

endmodule
