// ============================================================================
// File: hazard_unit.sv
// Description: Hazard Detection & Forwarding Unit.
//              Handles WB-to-ID/EX data forwarding, load-use stall insertion,
//              and branch/jump mispredict pipeline flushing.
// Standards: SystemVerilog-2012 / Cadence Genus Synthesizable
// ============================================================================

module hazard_unit #(
    parameter int ADDR_WIDTH = 4
)(
    // Register Address Inputs
    input  logic [ADDR_WIDTH-1:0] id_rs1,
    input  logic [ADDR_WIDTH-1:0] id_rs2,
    input  logic [ADDR_WIDTH-1:0] id_ex_rd,
    input  logic                  id_ex_mem_read,
    
    input  logic [ADDR_WIDTH-1:0] wb_rd,
    input  logic                  wb_reg_write,
    
    // Control Hazard Inputs
    input  logic                  branch_or_jump_taken,
    
    // Hazard Output Signals
    output logic                  forward_a,      // WB -> ID/EX RS1 forwarding
    output logic                  forward_b,      // WB -> ID/EX RS2 forwarding
    output logic                  stall_if,       // Freeze PC & IF/ID stage
    output logic                  flush_if_id,    // Flush IF/ID stage (branch/jump)
    output logic                  flush_id_ex     // Insert bubble into ID/EX stage (load-use stall)
);

    // ------------------------------------------------------------------------
    // DATA FORWARDING LOGIC (WB Stage -> ID/EX Stage)
    // ------------------------------------------------------------------------
    always_comb begin
        forward_a = 1'b0;
        forward_b = 1'b0;

        if (wb_reg_write && (wb_rd != '0)) begin
            if (wb_rd == id_rs1) forward_a = 1'b1;
            if (wb_rd == id_rs2) forward_b = 1'b1;
        end
    end

    // ------------------------------------------------------------------------
    // LOAD-USE STALL & CONTROL FLUSH LOGIC
    // ------------------------------------------------------------------------
    always_comb begin
        stall_if    = 1'b0;
        flush_if_id = 1'b0;
        flush_id_ex = 1'b0;

        // 1. Load-Use Hazard Detection (Stall 1 cycle)
        if (id_ex_mem_read && (id_ex_rd != '0) && ((id_ex_rd == id_rs1) || (id_ex_rd == id_rs2))) begin
            stall_if    = 1'b1;
            flush_id_ex = 1'b1; // Convert EX stage instruction to bubble NOP
        end

        // 2. Control Hazard (Branch / Jump taken in EX stage)
        if (branch_or_jump_taken) begin
            flush_if_id = 1'b1; // Flush fetched instruction in IF/ID register
        end
    end

endmodule
