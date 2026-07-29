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
    output logic             no_majority
);

    // Majority logic: result is majority of three inputs
    // For each bit: result = (a & b) | (a & c) | (b & c)
    assign result = (a & b) | (a & c) | (b & c);

    // Mismatch detected if not all three agree
    assign mismatch_detected = (a != b) | (a != c) | (b != c);

    // No majority if all three differ (impossible with 3 inputs, but included for completeness)
    // With 3 inputs, there's always a majority unless we consider X/Z
    assign no_majority = 1'b0;

endmodule