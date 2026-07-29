// ============================================================================
// File: hazard_unit.sv
// Description: Hazard Detection & Forwarding Unit.
//              Handles WB-to-ID/EX data forwarding and branch/jump pipeline flushing.
// Standards: SystemVerilog-2012 / Cadence Genus Synthesizable
// ============================================================================

module hazard_unit #(
    parameter int ADDR_WIDTH = 4
)(
    // Register Address Inputs
    input  logic [ADDR_WIDTH-1:0] id_rs1,
    input  logic [ADDR_WIDTH-1:0] id_rs2,
    input  logic [ADDR_WIDTH-1:0] wb_rd,
    input  logic                  wb_reg_write,
    
    // Control Hazard Inputs
    input  logic                  branch_or_jump_taken,
    
    // Hazard Output Signals
    output logic                  forward_a,      // WB -> ID/EX RS1 forwarding
    output logic                  forward_b,      // WB -> ID/EX RS2 forwarding
    output logic                  stall_if,       // Freeze PC & IF/ID stage (reserved)
    output logic                  flush_if_id,    // Flush IF/ID stage (branch/jump)
    output logic                  flush_id_ex     // Insert bubble into ID/EX stage (reserved)
);

    // ------------------------------------------------------------------------
    // DATA FORWARDING LOGIC (WB Stage -> ID/EX Stage)
    // ------------------------------------------------------------------------
    assign forward_a = wb_reg_write && (wb_rd != '0) && (wb_rd == id_rs1);
    assign forward_b = wb_reg_write && (wb_rd != '0) && (wb_rd == id_rs2);

    // ------------------------------------------------------------------------
    // CONTROL HAZARD & FLUSH LOGIC
    // ------------------------------------------------------------------------
    assign flush_if_id = branch_or_jump_taken;
    assign stall_if    = 1'b0;
    assign flush_id_ex = 1'b0;

endmodule
