`timescale 1ns/1ps
// ============================================================================
// File: tmr_voter.sv
// Description: TMR 3-Input Majority Voter with Mismatch Detection.
//              Outputs majority value and flags if no clear majority exists.
// Standards: SystemVerilog-2012 / Cadence Genus Synthesizable
// ============================================================================

module tmr_voter #(
    parameter int WIDTH = 32
)(
    input  logic [WIDTH-1:0] a,
    input  logic [WIDTH-1:0] b,
    input  logic [WIDTH-1:0] c,
    output logic [WIDTH-1:0] result,
    output logic             mismatch_detected,
    output logic             tmr_fatal_mismatch
);

    // Majority logic: result is majority of three inputs
    // For each bit: result = (a & b) | (a & c) | (b & c)
    assign result = (a & b) | (a & c) | (b & c);

    // Mismatch detected if not all three agree
    assign mismatch_detected = (a != b) | (a != c) | (b != c);

    // Fatal mismatch if all three full-word replicas are different
    // In this case, the bitwise majority output is a fabricated value that matches none of the inputs.
    assign tmr_fatal_mismatch = (a != b) && (a != c) && (b != c);

endmodule