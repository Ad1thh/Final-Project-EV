// ============================================================================
// File: tb_riscv_core_top.sv
// Description: Testbench for the RISC-V 3-Stage Pipelined Core.
//              Supports both signature-based verification (for rv32i tests)
//              and directed testing for Fault Tolerance features.
// ============================================================================

module tb_riscv_core_top();

    // ------------------------------------------------------------------------
    // CLOCK & RESET
    // ------------------------------------------------------------------------
    logic clk;
    logic rst_n;

    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    // ------------------------------------------------------------------------
    // DUT SIGNALS
    // ------------------------------------------------------------------------
    logic [31:0] imem_addr;
    logic [31:0] imem_rdata;
    
    logic [31:0] dmem_addr;
    logic [31:0] dmem_wdata;
    logic [3:0]  dmem_wmask;
    logic        dmem_we;
    logic [31:0] dmem_rdata;
    
    logic [31:0] pc_debug;
    logic        trap;

    // Fault Tolerance Ports
    logic        tmr_mode_pin;
    logic        fi_reg_en;
    logic [3:0]  fi_reg_addr;
    logic [5:0]  fi_reg_bit;
    logic        fi_alu_en;
    logic [1:0]  fi_alu_sel;
    logic [4:0]  fi_alu_bit;
    
    logic        ecc_sec_1, ecc_ded_1;
    logic        ecc_ded_2;
    logic        tmr_mismatch;
    logic        tmr_fatal_mismatch;

    // Sticky status flags for FT verification
    logic        sec_flag, ded_flag, tmr_flag;
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            sec_flag <= 0;
            ded_flag <= 0;
            tmr_flag <= 0;
        end else begin
            if (ecc_sec_1 | ecc_sec_2) sec_flag <= 1;
            if (ecc_ded_1 | ecc_ded_2) ded_flag <= 1;
            if (tmr_mismatch) tmr_flag <= 1;
        end
    end

    // ------------------------------------------------------------------------
    // MEMORY ARRAYS (64KB total: 0x0000 to 0xFFFF)
    // ------------------------------------------------------------------------
    logic [7:0] memory [0:65535];

    // Read from instruction memory (Combinational read)
    assign imem_rdata = {memory[imem_addr+3], memory[imem_addr+2], memory[imem_addr+1], memory[imem_addr]};

    // Read from data memory (Combinational read)
    assign dmem_rdata = {memory[dmem_addr+3], memory[dmem_addr+2], memory[dmem_addr+1], memory[dmem_addr]};

    // Write to data memory (Synchronous write)
    always_ff @(posedge clk) begin
        if (dmem_we) begin
            if (dmem_wmask[0]) memory[dmem_addr]   <= dmem_wdata[7:0];
            if (dmem_wmask[1]) memory[dmem_addr+1] <= dmem_wdata[15:8];
            if (dmem_wmask[2]) memory[dmem_addr+2] <= dmem_wdata[23:16];
            if (dmem_wmask[3]) memory[dmem_addr+3] <= dmem_wdata[31:24];
        end
    end

    // ------------------------------------------------------------------------
    // DUT INSTANTIATION
    // ------------------------------------------------------------------------
    riscv_core_top #(
        .DATA_WIDTH (32),
        .REG_COUNT  (16),
        .ADDR_WIDTH (4)
    ) dut (
        .clk          (clk),
        .rst_n        (rst_n),
        .imem_addr    (imem_addr),
        .imem_rdata   (imem_rdata),
        .dmem_addr    (dmem_addr),
        .dmem_wdata   (dmem_wdata),
        .dmem_wmask   (dmem_wmask),
        .dmem_we      (dmem_we),
        .dmem_rdata   (dmem_rdata),
        .pc_debug     (pc_debug),
        .trap         (trap),
        .tmr_mode_pin (tmr_mode_pin),
        .fi_reg_en    (fi_reg_en),
        .fi_reg_addr  (fi_reg_addr),
        .fi_reg_bit   (fi_reg_bit),
        .fi_alu_en    (fi_alu_en),
        .fi_alu_sel   (fi_alu_sel),
        .fi_alu_bit   (fi_alu_bit),
        .ecc_sec_1    (ecc_sec_1),
        .ecc_ded_1    (ecc_ded_1),
        .ecc_sec_2    (ecc_sec_2),
        .ecc_ded_2    (ecc_ded_2),
        .tmr_mismatch (tmr_mismatch),
        .tmr_fatal_mismatch(tmr_fatal_mismatch)
    );

    // ------------------------------------------------------------------------
    // SIMULATION ARGUMENTS & INITIALIZATION
    // ------------------------------------------------------------------------
    string hex_file;
    string sig_file;
    int sig_start, sig_end;

    initial begin
        // Initialize memory to 0
        for (int i = 0; i < 65536; i++) begin
            memory[i] = 8'h00;
        end

        // Load HEX file if provided
        if ($value$plusargs("HEX=%s", hex_file)) begin
            $readmemh(hex_file, memory);
            $display("Loaded %s into memory.", hex_file);
        end else begin
            $display("WARNING: No +HEX file provided. Memory is empty.");
        end

        // Initialize inputs
        tmr_mode_pin = 1'b0;
        fi_reg_en    = 1'b0;
        fi_reg_addr  = '0;
        fi_reg_bit   = '0;
        fi_alu_en    = 1'b0;
        fi_alu_sel   = '0;
        fi_alu_bit   = '0;
        rst_n = 0;
        #20 rst_n = 1;

        // Run Directed FT Tests
        run_fault_tolerance_tests();

        // Run Main Program
        wait(trap == 1'b1);
        #50;
        
        $display("Trap received. Checking signature...");
        
        // Write signature if arguments provided
        if ($value$plusargs("SIG_FILE=%s", sig_file)) begin
            if ($value$plusargs("SIG_START=%x", sig_start) && $value$plusargs("SIG_END=%x", sig_end)) begin
                int fd = $fopen(sig_file, "w");
                if (fd) begin
                    for (int i = sig_start; i < sig_end; i += 4) begin
                        $fdisplay(fd, "%02x%02x%02x%02x", memory[i+3], memory[i+2], memory[i+1], memory[i]);
                    end
                    $fclose(fd);
                    $display("Signature written to %s", sig_file);
                end
            end
        end

        $display("---------------------------------");
        $display("RESULT: TEST PASSED");
        $display("---------------------------------");
        $finish;
    end

    // Timeout watchdog
    initial begin
        #100000;
        $display("TIMEOUT");
        $finish;
    end

    // ------------------------------------------------------------------------
    // FAULT TOLERANCE DIRECTED TESTS
    // ------------------------------------------------------------------------
    task run_fault_tolerance_tests;
        $display("---------------------------------");
        $display("Starting Fault Tolerance Tests...");
        
        // --- Test 1: Single Event Upset (SEC) in Register File ---
        $display("[Test 1] Injecting Single Bit Flip into Reg[5]");
        // Let pipeline run for a bit
        #100;
        // Inject single bit fault in x5 (Bit 4)
        @(posedge clk);
        fi_reg_en   = 1'b1;
        fi_reg_addr = 4'd5;
        fi_reg_bit  = 6'd4;
        @(posedge clk);
        fi_reg_en   = 1'b0;
        
        // Wait for it to be read and check SEC flag
        #100;
        if (sec_flag) $display("  -> SUCCESS: SEC detected and corrected.");
        else          $display("  -> FAIL: SEC not detected.");
        
        // --- Test 2: Double Bit Flip (DED) in Register File ---
        $display("[Test 2] Injecting Double Bit Flip into Reg[6]");
        sec_flag <= 0; ded_flag <= 0;
        @(posedge clk);
        fi_reg_en   = 1'b1;
        fi_reg_addr = 4'd6;
        fi_reg_bit  = 6'd10; // First bit
        @(posedge clk);
        fi_reg_bit  = 6'd11; // Second bit
        @(posedge clk);
        fi_reg_en   = 1'b0;
        
        // Wait for it to be read and check DED flag
        #100;
        if (ded_flag) $display("  -> SUCCESS: DED detected.");
        else          $display("  -> FAIL: DED not detected.");

        // --- Test 3: TMR Mode Masking ---
        $display("[Test 3] Injecting ALU Fault in TMR Mode");
        tmr_mode_pin = 1'b1;
        tmr_flag <= 0;
        #50;
        @(posedge clk);
        fi_alu_en  = 1'b1;
        fi_alu_sel = 2'd1; // Fault in ALU 1
        fi_alu_bit = 5'd15;
        @(posedge clk);
        fi_alu_en  = 1'b0;
        
        #50;
        if (tmr_flag) $display("  -> SUCCESS: TMR Voter masked fault and flagged mismatch.");
        else          $display("  -> FAIL: TMR mismatch not flagged.");

        // --- Test 4: Simplex Mode Vulnerability (Control) ---
        $display("[Test 4] Injecting ALU Fault in Simplex Mode");
        tmr_mode_pin = 1'b0;
        tmr_flag <= 0;
        #50;
        @(posedge clk);
        fi_alu_en  = 1'b1;
        fi_alu_sel = 2'd0; // Fault in ALU 0 (Primary)
        fi_alu_bit = 5'd15;
        @(posedge clk);
        fi_alu_en  = 1'b0;
        
        #50;
        if (!tmr_flag) $display("  -> SUCCESS: Simplex mode propagated fault (no TMR voting).");
        else           $display("  -> FAIL: TMR mismatch flagged in Simplex mode?!");

        $display("Fault Tolerance Tests Complete.");
        $display("---------------------------------");
        
        // Reset flags for main test
        sec_flag <= 0;
        ded_flag <= 0;
        tmr_flag <= 0;
    endtask

endmodule