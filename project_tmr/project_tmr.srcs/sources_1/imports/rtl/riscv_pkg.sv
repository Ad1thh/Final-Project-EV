// ============================================================================
// File: riscv_pkg.sv
// Description: Package defining RV32E Opcodes, Control Enums, ALU Control,
//              and Pipeline Structs for 3-Stage Pipelined Processor Core.
// Standards: SystemVerilog-2012 / Cadence Genus & Xcelium Synthesizable
// ============================================================================

package riscv_pkg;

    // ------------------------------------------------------------------------
    // OPCODES (RV32I / RV32E Base Instruction Set)
    // ------------------------------------------------------------------------
    typedef enum logic [6:0] {
        OPCODE_R_TYPE   = 7'b0110011,
        OPCODE_I_TYPE   = 7'b0010011,
        OPCODE_LOAD     = 7'b0000011,
        OPCODE_STORE    = 7'b0100011,
        OPCODE_BRANCH   = 7'b1100011,
        OPCODE_JALR     = 7'b1100111,
        OPCODE_JAL      = 7'b1101111,
        OPCODE_LUI      = 7'b0110111,
        OPCODE_AUIPC    = 7'b0010111,
        OPCODE_SYSTEM   = 7'b1110011
    } opcode_e;

    // ------------------------------------------------------------------------
    // FUNCT3 DEFINITIONS
    // ------------------------------------------------------------------------
    // R-Type / I-Type Arithmetic & Logical
    typedef enum logic [2:0] {
        FUNCT3_ADD_SUB = 3'b000,
        FUNCT3_SLL     = 3'b001,
        FUNCT3_SLT     = 3'b010,
        FUNCT3_SLTU    = 3'b011,
        FUNCT3_XOR     = 3'b100,
        FUNCT3_SRL_SRA = 3'b101,
        FUNCT3_OR      = 3'b110,
        FUNCT3_AND     = 3'b111
    } funct3_alu_e;

    // Branch Operations
    typedef enum logic [2:0] {
        FUNCT3_BEQ  = 3'b000,
        FUNCT3_BNE  = 3'b001,
        FUNCT3_BLT  = 3'b100,
        FUNCT3_BGE  = 3'b101,
        FUNCT3_BLTU = 3'b110,
        FUNCT3_BGEU = 3'b111
    } funct3_branch_e;

    // Load Operations
    typedef enum logic [2:0] {
        FUNCT3_LB  = 3'b000,
        FUNCT3_LH  = 3'b001,
        FUNCT3_LW  = 3'b010,
        FUNCT3_LBU = 3'b100,
        FUNCT3_LHU = 3'b101
    } funct3_load_e;

    // Store Operations
    typedef enum logic [2:0] {
        FUNCT3_SB  = 3'b000,
        FUNCT3_SH  = 3'b001,
        FUNCT3_SW  = 3'b010
    } funct3_store_e;

    // ------------------------------------------------------------------------
    // ALU CONTROL ENUM
    // ------------------------------------------------------------------------
    typedef enum logic [3:0] {
        ALU_ADD  = 4'b0000,
        ALU_SUB  = 4'b0001,
        ALU_AND  = 4'b0010,
        ALU_OR   = 4'b0011,
        ALU_XOR  = 4'b0100,
        ALU_SLL  = 4'b0101,
        ALU_SRL  = 4'b0110,
        ALU_SRA  = 4'b0111,
        ALU_SLT  = 4'b1000,
        ALU_SLTU = 4'b1001,
        ALU_PASS_B = 4'b1010
    } alu_op_e;

    // ------------------------------------------------------------------------
    // WB RESULT MUX ENUM
    // ------------------------------------------------------------------------
    typedef enum logic [1:0] {
        WB_SEL_ALU  = 2'b00,
        WB_SEL_MEM  = 2'b01,
        WB_SEL_PC4  = 2'b10
    } wb_sel_e;

endpackage: riscv_pkg
