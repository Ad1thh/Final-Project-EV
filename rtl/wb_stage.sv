// ============================================================================
// File: wb_stage.sv
// Description: Writeback Stage (Stage 3) for 3-Stage RISC-V Core.
//              Handles memory load alignment/extension, writeback result
//              selection (ALU, Memory, PC+4), and feeds back to Register File.
// Standards: SystemVerilog-2012 / Cadence Genus Synthesizable
// ============================================================================

import riscv_pkg::*;

module wb_stage #(
    parameter int DATA_WIDTH = 32
)(
    input  logic [DATA_WIDTH-1:0] pc_wb,
    input  logic [DATA_WIDTH-1:0] alu_result_wb,
    input  logic [DATA_WIDTH-1:0] dmem_rdata_raw_wb,
    input  logic [1:0]            wb_sel_wb,
    input  logic [2:0]            funct3_wb,
    
    output logic [DATA_WIDTH-1:0] wb_result
);

    // ------------------------------------------------------------------------
    // LOAD ALIGNMENT & SIGN/ZERO EXTENSION LOGIC
    // ------------------------------------------------------------------------
    logic [7:0]  byte_selected;
    logic [15:0] halfword_selected;
    logic [31:0] formatted_load_data;

    always_comb begin
        if (alu_result_wb[1:0] == 2'b00)       byte_selected = dmem_rdata_raw_wb[7:0];
        else if (alu_result_wb[1:0] == 2'b01)  byte_selected = dmem_rdata_raw_wb[15:8];
        else if (alu_result_wb[1:0] == 2'b10)  byte_selected = dmem_rdata_raw_wb[23:16];
        else                                   byte_selected = dmem_rdata_raw_wb[31:24];

        if (alu_result_wb[1] == 1'b0)          halfword_selected = dmem_rdata_raw_wb[15:0];
        else                                   halfword_selected = dmem_rdata_raw_wb[31:16];

        if (funct3_wb == FUNCT3_LB)    formatted_load_data = {{24{byte_selected[7]}}, byte_selected};
        else if (funct3_wb == FUNCT3_LBU) formatted_load_data = {24'b0, byte_selected};
        else if (funct3_wb == FUNCT3_LH)  formatted_load_data = {{16{halfword_selected[15]}}, halfword_selected};
        else if (funct3_wb == FUNCT3_LHU) formatted_load_data = {16'b0, halfword_selected};
        else if (funct3_wb == FUNCT3_LW)  formatted_load_data = dmem_rdata_raw_wb;
        else                              formatted_load_data = dmem_rdata_raw_wb;
    end

    // ------------------------------------------------------------------------
    // WRITEBACK RESULT SELECTION MUX
    // ------------------------------------------------------------------------
    always_comb begin
        if (wb_sel_wb == WB_SEL_ALU)   wb_result = alu_result_wb;
        else if (wb_sel_wb == WB_SEL_MEM) wb_result = formatted_load_data;
        else if (wb_sel_wb == WB_SEL_PC4) wb_result = pc_wb + 32'd4;
        else                               wb_result = alu_result_wb;
    end

endmodule
