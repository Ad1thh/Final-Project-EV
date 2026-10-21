`timescale 1ns/1ps
// ============================================================================
// File: alu.sv
// Description: 32-bit Arithmetic Logic Unit supporting RV32I base ops.
// Standards: SystemVerilog-2012 / Cadence Genus Synthesizable
// ============================================================================

import riscv_pkg::*;

module alu #(
    parameter int DATA_WIDTH = 32
)(
    input  logic [DATA_WIDTH-1:0] a,
    input  logic [DATA_WIDTH-1:0] b,
    input  logic [3:0]            alu_op,
    output logic [DATA_WIDTH-1:0] result,
    output logic                  zero
);

    logic [4:0]  shamt;
    logic [63:0] sra_ext;

    assign shamt   = b[4:0];
    assign sra_ext = {{32{a[31]}}, a} >> shamt;

    always_comb begin
        result = '0;
        if (alu_op == ALU_ADD)         result = a + b;
        else if (alu_op == ALU_SUB)    result = a - b;
        else if (alu_op == ALU_AND)    result = a & b;
        else if (alu_op == ALU_OR)     result = a | b;
        else if (alu_op == ALU_XOR)    result = a ^ b;
        else if (alu_op == ALU_SLL)    result = a << shamt;
        else if (alu_op == ALU_SRL)    result = a >> shamt;
        else if (alu_op == ALU_SRA)    result = sra_ext[31:0];
        else if (alu_op == ALU_SLT)    result = ($signed(a) < $signed(b)) ? 32'd1 : 32'd0;
        else if (alu_op == ALU_SLTU)   result = (a < b) ? 32'd1 : 32'd0;
        else if (alu_op == ALU_PASS_B) result = b;
    end

    assign zero = (result == '0);

endmodule

// ============================================================================
// Discrete Module Wrappers for Triple Modular Redundancy (TMR) Preservation
// Prevents Cadence Genus from merging identical execution instances.
// ============================================================================
(* dont_touch = "true" *)
module alu_0 #(
    parameter int DATA_WIDTH = 32
)(
    input  logic [DATA_WIDTH-1:0] a,
    input  logic [DATA_WIDTH-1:0] b,
    input  logic [3:0]            alu_op,
    output logic [DATA_WIDTH-1:0] result,
    output logic                  zero
);
    alu #(.DATA_WIDTH(DATA_WIDTH)) u_core (
        .a(a), .b(b), .alu_op(alu_op), .result(result), .zero(zero)
    );
endmodule

(* dont_touch = "true" *)
module alu_1 #(
    parameter int DATA_WIDTH = 32
)(
    input  logic [DATA_WIDTH-1:0] a,
    input  logic [DATA_WIDTH-1:0] b,
    input  logic [3:0]            alu_op,
    output logic [DATA_WIDTH-1:0] result,
    output logic                  zero
);
    alu #(.DATA_WIDTH(DATA_WIDTH)) u_core (
        .a(a), .b(b), .alu_op(alu_op), .result(result), .zero(zero)
    );
endmodule

(* dont_touch = "true" *)
module alu_2 #(
    parameter int DATA_WIDTH = 32
)(
    input  logic [DATA_WIDTH-1:0] a,
    input  logic [DATA_WIDTH-1:0] b,
    input  logic [3:0]            alu_op,
    output logic [DATA_WIDTH-1:0] result,
    output logic                  zero
);
    alu #(.DATA_WIDTH(DATA_WIDTH)) u_core (
        .a(a), .b(b), .alu_op(alu_op), .result(result), .zero(zero)
    );
endmodule
