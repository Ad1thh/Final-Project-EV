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
    input  alu_op_e               alu_op,
    output logic [DATA_WIDTH-1:0] result,
    output logic                  zero
);

    logic [63:0] sra_ext;
    assign sra_ext = {{32{a[31]}}, a} >> b[4:0];

    always_comb begin
        case (alu_op)
            ALU_ADD:    result = a + b;
            ALU_SUB:    result = a - b;
            ALU_AND:    result = a & b;
            ALU_OR:     result = a | b;
            ALU_XOR:    result = a ^ b;
            ALU_SLL:    result = a << b[4:0];
            ALU_SRL:    result = a >> b[4:0];
            ALU_SRA:    result = sra_ext[31:0];
            ALU_SLT:    result = ($signed(a) < $signed(b)) ? 32'd1 : 32'd0;
            ALU_SLTU:   result = (a < b) ? 32'd1 : 32'd0;
            ALU_PASS_B: result = b;
            default:    result = '0;
        endcase
    end

    assign zero = (result == '0);

endmodule
