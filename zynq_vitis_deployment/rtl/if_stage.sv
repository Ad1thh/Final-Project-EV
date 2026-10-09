`timescale 1ns/1ps
// ============================================================================
// File: if_stage.sv
// Description: Fetch Stage (Stage 1) for 3-Stage RISC-V Core.
//              Manages PC register, PC generation, instruction fetch,
//              and IF/ID pipeline register logic with flush & stall support.
//              PC register is Triple-Modular-Redundant (TMR) with majority
//              voting to mask single-event upsets on the program counter.
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
    output logic [DATA_WIDTH-1:0] instr_id,

    // PC TMR Telemetry Outputs
    output logic                  pc_tmr_mismatch,       // One PC replica disagrees (correctable)
    output logic                  pc_tmr_fatal_mismatch  // All three PC replicas disagree (uncorrectable)
);

    // Constant NOP (ADDI x0, x0, 0)
    localparam logic [31:0] NOP_INSTR = 32'h0000_0013;

    // ------------------------------------------------------------------------
    // TMR PC REGISTERS: Three identical replicas of the program counter.
    // All three receive the same next_pc on every clock edge. A majority
    // voter downstream corrects any single-replica SEU transparently.
    // ------------------------------------------------------------------------
    (* dont_touch = "true", preserve = "true" *)
    logic [DATA_WIDTH-1:0] pc_reg_a, pc_reg_b, pc_reg_c;
    logic [DATA_WIDTH-1:0] pc_voted;   // Authoritative, fault-corrected PC
    logic [DATA_WIDTH-1:0] next_pc;

    // ------------------------------------------------------------------------
    // PC NEXT MUX LOGIC (driven from the voted, corrected PC)
    // ------------------------------------------------------------------------
    always_comb begin
        if (branch_or_jump_taken) begin
            next_pc = target_pc;
        end else if (stall_if) begin
            next_pc = pc_voted;
        end else begin
            next_pc = pc_voted + 32'd4;
        end
    end

    // ------------------------------------------------------------------------
    // TMR PC REGISTER BANK: All three replicas updated identically.
    // Synthesis tools (Genus/Vivado) must NOT merge these registers.
    // Cadence Genus: use set_db .preserve true on each replica instance.
    // ------------------------------------------------------------------------
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            pc_reg_a <= '0;
            pc_reg_b <= '0;
            pc_reg_c <= '0;
        end else begin
            pc_reg_a <= next_pc;
            pc_reg_b <= next_pc;
            pc_reg_c <= next_pc;
        end
    end

    // ------------------------------------------------------------------------
    // PC TMR VOTER: Majority vote over three PC replicas.
    // If one replica is upset by radiation, the voter masks it transparently.
    // pc_tmr_mismatch pulses for one cycle when any replica disagrees.
    // ------------------------------------------------------------------------
    tmr_voter #(
        .WIDTH (DATA_WIDTH)
    ) u_pc_voter (
        .a                 (pc_reg_a),
        .b                 (pc_reg_b),
        .c                 (pc_reg_c),
        .result            (pc_voted),
        .mismatch_detected (pc_tmr_mismatch),
        .tmr_fatal_mismatch(pc_tmr_fatal_mismatch)
    );

    assign imem_addr = pc_voted;

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
            pc_id    <= pc_voted;   // Capture majority-voted, fault-corrected PC
            instr_id <= imem_rdata;
        end
        // If stall_if is high, retain current values
    end

endmodule
