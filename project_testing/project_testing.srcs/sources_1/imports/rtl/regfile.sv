// ============================================================================
// File: regfile.sv
// Description: 16 x 32-bit Register File for RV32E Architecture.
//              Features 2 asynchronous read ports and 1 synchronous write port.
//              Register x0 is hardwired to 32'h0000_0000.
//              Includes Hamming(38,32) SEC-DED ECC.
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
    output logic                  single_err_corrected_1,
    output logic                  double_err_detected_1,
    
    // Read Port 2
    input  logic [ADDR_WIDTH-1:0] raddr2,
    output logic [DATA_WIDTH-1:0] rdata2,
    output logic                  single_err_corrected_2,
    output logic                  double_err_detected_2,
    
    // Write Port
    input  logic                  we,
    input  logic [ADDR_WIDTH-1:0] waddr,
    input  logic [DATA_WIDTH-1:0] wdata,
    
    // Fault Injection Interface
    input  logic                  fi_reg_en,
    input  logic [ADDR_WIDTH-1:0] fi_reg_addr,
    input  logic [5:0]            fi_reg_bit
);

    // Register Array Storage (39 bits for SEC-DED: 32 data + 6 parity + 1 overall parity)
    logic [38:0] rf [1:REG_COUNT-1];

    // SEC-DED Encoder
    function automatic logic [38:0] encode_secded(input logic [31:0] data);
        logic [38:1] h; // Hamming codeword bits (1 to 38)
        logic p0;       // Overall parity bit (0)
        
        // Data bits assigned to non-power-of-2 positions
        h[3] = data[0];
        h[5] = data[1];  h[6] = data[2];  h[7] = data[3];
        h[9] = data[4];  h[10]= data[5];  h[11]= data[6]; h[12]= data[7];
        h[13]= data[8];  h[14]= data[9];  h[15]= data[10];
        h[17]= data[11]; h[18]= data[12]; h[19]= data[13]; h[20]= data[14];
        h[21]= data[15]; h[22]= data[16]; h[23]= data[17]; h[24]= data[18];
        h[25]= data[19]; h[26]= data[20]; h[27]= data[21]; h[28]= data[22];
        h[29]= data[23]; h[30]= data[24]; h[31]= data[25];
        h[33]= data[26]; h[34]= data[27]; h[35]= data[28]; h[36]= data[29];
        h[37]= data[30]; h[38]= data[31];
        
        // Calculate parity bits
        h[1] = h[3]^h[5]^h[7]^h[9]^h[11]^h[13]^h[15]^h[17]^h[19]^h[21]^h[23]^h[25]^h[27]^h[29]^h[31]^h[33]^h[35]^h[37];
        h[2] = h[3]^h[6]^h[7]^h[10]^h[11]^h[14]^h[15]^h[18]^h[19]^h[22]^h[23]^h[26]^h[27]^h[30]^h[31]^h[34]^h[35]^h[38];
        h[4] = h[5]^h[6]^h[7]^h[12]^h[13]^h[14]^h[15]^h[20]^h[21]^h[22]^h[23]^h[28]^h[29]^h[30]^h[31]^h[36]^h[37]^h[38];
        h[8] = h[9]^h[10]^h[11]^h[12]^h[13]^h[14]^h[15]^h[24]^h[25]^h[26]^h[27]^h[28]^h[29]^h[30]^h[31];
        h[16]= h[17]^h[18]^h[19]^h[20]^h[21]^h[22]^h[23]^h[24]^h[25]^h[26]^h[27]^h[28]^h[29]^h[30]^h[31];
        h[32]= h[33]^h[34]^h[35]^h[36]^h[37]^h[38];
        
        p0 = ^h;
        
        return {h, p0};
    endfunction

    // SEC-DED Decoder
    function automatic logic [33:0] decode_secded(input logic [38:0] code);
        logic [38:1] h;
        logic p0;
        logic [5:0] syn;
        logic overall_parity;
        logic sec, ded;
        logic [31:0] data;
        
        h = code[38:1];
        p0 = code[0];
        
        // Calculate syndrome
        syn[0] = h[1]^h[3]^h[5]^h[7]^h[9]^h[11]^h[13]^h[15]^h[17]^h[19]^h[21]^h[23]^h[25]^h[27]^h[29]^h[31]^h[33]^h[35]^h[37];
        syn[1] = h[2]^h[3]^h[6]^h[7]^h[10]^h[11]^h[14]^h[15]^h[18]^h[19]^h[22]^h[23]^h[26]^h[27]^h[30]^h[31]^h[34]^h[35]^h[38];
        syn[2] = h[4]^h[5]^h[6]^h[7]^h[12]^h[13]^h[14]^h[15]^h[20]^h[21]^h[22]^h[23]^h[28]^h[29]^h[30]^h[31]^h[36]^h[37]^h[38];
        syn[3] = h[8]^h[9]^h[10]^h[11]^h[12]^h[13]^h[14]^h[15]^h[24]^h[25]^h[26]^h[27]^h[28]^h[29]^h[30]^h[31];
        syn[4] = h[16]^h[17]^h[18]^h[19]^h[20]^h[21]^h[22]^h[23]^h[24]^h[25]^h[26]^h[27]^h[28]^h[29]^h[30]^h[31];
        syn[5] = h[32]^h[33]^h[34]^h[35]^h[36]^h[37]^h[38];
        
        overall_parity = ^code; // Should be 0 if no errors
        
        sec = 1'b0;
        ded = 1'b0;
        
        if (syn != 0) begin
            if (overall_parity == 1'b1) begin
                // Single error, correct it
                sec = 1'b1;
                if (syn <= 38) begin
                    logic [38:0] mask;
                    mask = 39'd1 << syn;
                    h = h ^ mask[38:1];
                end
            end else begin
                // Double error detected
                ded = 1'b1;
            end
        end else if (overall_parity == 1'b1) begin
            // Parity bit itself is flipped, technically SEC but doesn't affect data
            sec = 1'b1;
        end
        
        // Extract data
        data[0] = h[3];
        data[1] = h[5];  data[2] = h[6];  data[3] = h[7];
        data[4] = h[9];  data[5] = h[10]; data[6] = h[11]; data[7] = h[12];
        data[8] = h[13]; data[9] = h[14]; data[10]= h[15];
        data[11]= h[17]; data[12]= h[18]; data[13]= h[19]; data[14]= h[20];
        data[15]= h[21]; data[16]= h[22]; data[17]= h[23]; data[18]= h[24];
        data[19]= h[25]; data[20]= h[26]; data[21]= h[27]; data[22]= h[28];
        data[23]= h[29]; data[24]= h[30]; data[25]= h[31];
        data[26]= h[33]; data[27]= h[34]; data[28]= h[35]; data[29]= h[36];
        data[30]= h[37]; data[31]= h[38];
        
        return {ded, sec, data};
    endfunction

    logic [38:0] encoded_wdata;
    assign encoded_wdata = encode_secded(wdata);

    // Synchronous Write Logic (Active-low async reset)
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (int i = 1; i < REG_COUNT; i++) begin
                rf[i] <= '0;
            end
        end else begin
            // Normal write and fault injection
            if (we && (waddr != '0)) begin
                rf[waddr] <= encoded_wdata;
            end
            
            // Fault injection overrides write for the specific bit
            if (fi_reg_en && (fi_reg_addr != '0)) begin
                if (we && (waddr == fi_reg_addr)) begin
                    // Flip bit of the newly written value
                    rf[fi_reg_addr][fi_reg_bit] <= ~encoded_wdata[fi_reg_bit];
                end else begin
                    // Flip bit of the stored value
                    rf[fi_reg_addr][fi_reg_bit] <= ~rf[fi_reg_addr][fi_reg_bit];
                end
            end
        end
    end

    // Asynchronous Read Port 1 (Internal Forwarding for Same-Cycle Read-Write)
    always_comb begin
        single_err_corrected_1 = 1'b0;
        double_err_detected_1  = 1'b0;
        if (raddr1 == '0) begin
            rdata1 = '0;
        end else if (we && (waddr == raddr1)) begin
            rdata1 = wdata; // Internal bypass/forwarding uses uncorrected data
        end else begin
            {double_err_detected_1, single_err_corrected_1, rdata1} = decode_secded(rf[raddr1]);
        end
    end

    // Asynchronous Read Port 2 (Internal Forwarding for Same-Cycle Read-Write)
    always_comb begin
        single_err_corrected_2 = 1'b0;
        double_err_detected_2  = 1'b0;
        if (raddr2 == '0) begin
            rdata2 = '0;
        end else if (we && (waddr == raddr2)) begin
            rdata2 = wdata; // Internal bypass/forwarding uses uncorrected data
        end else begin
            {double_err_detected_2, single_err_corrected_2, rdata2} = decode_secded(rf[raddr2]);
        end
    end

endmodule
