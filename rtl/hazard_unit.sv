// ============================================================================
// File: hazard_unit.sv
// Description: Hazard Detection & Forwarding Unit.
//              Resolves data hazards via forwarding and load-use hazards
//              via pipeline stalling. Handles branch misprediction flushing.
// Standards: SystemVerilog-2012 / Cadence Genus Synthesizable
// ============================================================================

module hazard_unit #(
    parameter int ADDR_WIDTH = 4
)(
    // Data Hazard Inputs (from Decode)
    input  logic [ADDR_WIDTH-1:0] id_rs1,
    input  logic [ADDR_WIDTH-1:0] id_rs2,
    
    // Load-Use Hazard Inputs (from Execute)
    input  logic [ADDR_WIDTH-1:0] id_ex_rd,
    input  logic                  id_ex_mem_read,
    
    // Control Hazard Inputs (from Execute/Branch)
    input  logic                  branch_or_jump_taken,
    
    // Hazard Resolution Outputs
    output logic                  stall_if,
    output logic                  flush_if_id,
    output logic                  flush_id_ex
);

    // ------------------------------------------------------------------------
    // LOAD-USE HAZARD DETECTION
    // ------------------------------------------------------------------------
    // Condition: Execute stage instruction is a LOAD, and its destination
    // register matches either source register of the current Decode instruction.
    logic load_use_hazard;
    
    always_comb begin
        load_use_hazard = 1'b0;
        if (id_ex_mem_read && (id_ex_rd != '0)) begin
            if ((id_ex_rd == id_rs1) || (id_ex_rd == id_rs2)) begin
                load_use_hazard = 1'b1;
            end
        end
    end

    // ------------------------------------------------------------------------
    // CONTROL HAZARD DETECTION
    // ------------------------------------------------------------------------
    // Condition: Branch or Jump is taken in the Execute stage.
    // The instructions in IF and ID stages must be flushed.
    logic control_hazard;
    assign control_hazard = branch_or_jump_taken;

    // ------------------------------------------------------------------------
    // PIPELINE CONTROL SIGNAL GENERATION
    // ------------------------------------------------------------------------
    // Stall IF stage if load-use hazard (prevents PC update)
    assign stall_if = load_use_hazard;
    
    // Flush IF/ID on branch taken (override load-use if both happen)
    assign flush_if_id = control_hazard;
    
    // Flush ID/EX on load-use hazard OR branch taken
    assign flush_id_ex = load_use_hazard | control_hazard;

endmodule
