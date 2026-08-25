`timescale 1ns/1ps
// ============================================================================
// File: clock_gater.sv
// Description: Synthesizable Glitch-Free Integrated Clock Gating (ICG) Cell.
//              Uses a falling-edge latch to gate the clock signal safely
//              without dynamic glitches or hazard spikes.
// Standards: SystemVerilog-2012 / ASIC & FPGA Synthesizable
// ============================================================================

module clock_gater (
    input  logic clk,
    input  logic enable,
    input  logic test_mode,
    output logic gated_clk
);

    logic enable_latched;

    // Active-low enable latch sampled on the falling edge of input clock
    // to guarantee setup/hold window before clock goes high
    always_latch begin
        if (!clk) begin
            enable_latched <= enable | test_mode;
        end
    end

    // Gated clock output
    assign gated_clk = clk & enable_latched;

endmodule
