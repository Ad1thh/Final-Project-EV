// ============================================================================
// File: if_stage.sv
// Description: Fetch Stage (Stage 1) for 3-Stage RISC-V Core.
//              Manages PC register, PC generation, instruction fetch,
//              and IF/ID pipeline register logic with flush & stall support.
// Standards: SystemVerilog-2012 / Cadence Genus Synthesizable
// ============================================================================

module if_stage #(
    parameter int DATA_WIDTH = 32
)(
    input  logic                  clk,
    input  logic                  rst_n,
    
    // Control / Redirect Signals from EX Stage
    input  logic                  branch_or_jump_taken,
    input  logic [DATA_WIDTH-1:0] target_pc,
    
    // Hazard Signals
    input  logic                  stall_if,
    input  logic                  flush_if_id,
    
    // Memory Interface (Instruction Memory)
    output logic [DATA_WIDTH-1:0] imem_addr,
    input  logic [DATA_WIDTH-1:0] imem_rdata,
    
    // Outputs to Stage 2 (ID/EX)
    output logic [DATA_WIDTH-1:0] pc_id,
    output logic [DATA_WIDTH-1:0] instr_id
);

    // Constant NOP (ADDI x0, x0, 0)
    localparam logic [31:0] NOP_INSTR = 32'h0000_0013;

    logic [DATA_WIDTH-1:0] pc_reg;
    logic [DATA_WIDTH-1:0] next_pc;

    // ------------------------------------------------------------------------
    // PC NEXT MUX LOGIC
    // ------------------------------------------------------------------------
    always_comb begin
        if (branch_or_jump_taken) begin
            next_pc = target_pc;
        end else if (stall_if) begin
            next_pc = pc_reg;
        end else begin
            next_pc = pc_reg + 32'd4;
        end
    end

    // ------------------------------------------------------------------------
    // PC REGISTER
    // ------------------------------------------------------------------------
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            pc_reg <= '0;
        end else begin
            pc_reg <= next_pc;
        end
    end

    assign imem_addr = pc_reg;

    // ------------------------------------------------------------------------
    // IF/ID PIPELINE REGISTER
    // ------------------------------------------------------------------------
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            pc_id    <= '0;
            instr_id <= NOP_INSTR;
        end else if (flush_if_id) begin
            pc_id    <= '0;
            instr_id <= NOP_INSTR;
        end else if (!stall_if) begin
            pc_id    <= pc_reg;
            instr_id <= imem_rdata;
        end
        // If stall_if is high, retain current values
    end

endmodule
