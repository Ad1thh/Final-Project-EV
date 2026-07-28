// ============================================================================
// File: regfile.sv
// Description: 16 x 32-bit Register File for RV32E Architecture.
//              Features 2 asynchronous read ports and 1 synchronous write port.
//              Register x0 is hardwired to 32'h0000_0000.
// Standards: SystemVerilog-2012 / Cadence Genus Synthesizable
// ============================================================================

module regfile #(
    parameter int DATA_WIDTH = 32,
    parameter int REG_COUNT  = 16,
    parameter int ADDR_WIDTH = $clog2(REG_COUNT) // 4 bits for RV32E
)(
    input  logic                  clk,
    input  logic                  rst_n,
    
    // Read Port 1
    input  logic [ADDR_WIDTH-1:0] raddr1,
    output logic [DATA_WIDTH-1:0] rdata1,
    
    // Read Port 2
    input  logic [ADDR_WIDTH-1:0] raddr2,
    output logic [DATA_WIDTH-1:0] rdata2,
    
    // Write Port
    input  logic                  we,
    input  logic [ADDR_WIDTH-1:0] waddr,
    input  logic [DATA_WIDTH-1:0] wdata
);

    // Register Array Storage (Registers x1 to x15; x0 is implicit zero)
    logic [DATA_WIDTH-1:0] rf [1:REG_COUNT-1];

    // Synchronous Write Logic (Active-low async reset)
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (int i = 1; i < REG_COUNT; i++) begin
                rf[i] <= '0;
            end
        end else if (we && (waddr != '0)) begin
            rf[waddr] <= wdata;
        end
    end

    // Asynchronous Read Port 1 (Internal Forwarding for Same-Cycle Read-Write)
    always_comb begin
        if (raddr1 == '0) begin
            rdata1 = '0;
        end else if (we && (waddr == raddr1)) begin
            rdata1 = wdata; // Internal bypass/forwarding
        end else begin
            rdata1 = rf[raddr1];
        end
    end

    // Asynchronous Read Port 2 (Internal Forwarding for Same-Cycle Read-Write)
    always_comb begin
        if (raddr2 == '0) begin
            rdata2 = '0;
        end else if (we && (waddr == raddr2)) begin
            rdata2 = wdata; // Internal bypass/forwarding
        end else begin
            rdata2 = rf[raddr2];
        end
    end

endmodule
