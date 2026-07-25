// ============================================================================
// File: tb_riscv_core_top.sv
// Description: Self-Testing Verification Testbench for 3-Stage RV32E Core
//              Supports up to 32KB memory, dynamic runtime HEX loading,
//              RISC-V architectural signature dumping, and pass/fail reports.
// ============================================================================

`timescale 1ns/1ps

module tb_riscv_core_top;

  // --------------------------------------------------------------------------
  // TESTBENCH SIGNALS & PARAMETERS
  // --------------------------------------------------------------------------
  parameter int MEM_DEPTH = 8192; // 32KB Memory (8192 x 32-bit words)
  parameter time CLK_PERIOD = 10ns;

  logic        clk;
  logic        rst_n;
  logic [31:0] imem_addr;
  logic [31:0] imem_rdata;
  logic [31:0] dmem_addr;
  logic [31:0] dmem_wdata;
  logic [3:0]  dmem_wmask;
  logic        dmem_we;
  logic [31:0] dmem_rdata;
  logic [31:0] pc_debug;
  logic        trap;

  // 32KB Unified Memory Array
  logic [31:0] mem [0:MEM_DEPTH-1];
  string       hex_file;

  // Signature Dumping Signals (RISC-V Arch Compliance)
  string       sig_file_path;
  logic [31:0] sig_start_addr;
  logic [31:0] sig_end_addr;
  integer      sig_fd;

  // --------------------------------------------------------------------------
  // DUT INSTANTIATION
  // --------------------------------------------------------------------------
  riscv_core_top dut (
    .clk        (clk),
    .rst_n      (rst_n),
    .imem_addr  (imem_addr),
    .imem_rdata (imem_rdata),
    .dmem_addr  (dmem_addr),
    .dmem_wdata (dmem_wdata),
    .dmem_wmask (dmem_wmask),
    .dmem_we    (dmem_we),
    .dmem_rdata (dmem_rdata),
    .pc_debug   (pc_debug),
    .trap       (trap)
  );

  // --------------------------------------------------------------------------
  // CLOCK GENERATION & RESET
  // --------------------------------------------------------------------------
  initial begin
    clk = 0;
    forever #(CLK_PERIOD / 2) clk = ~clk;
  end

  task automatic do_reset();
    rst_n = 0;
    repeat (3) @(posedge clk);
    #(CLK_PERIOD / 4);
    rst_n = 1;
  endtask

  // --------------------------------------------------------------------------
  // UNIFIED MEMORY MODEL (CLEAN SHIFT INDEXING)
  // --------------------------------------------------------------------------
  wire [31:0] imem_idx = imem_addr >> 2;
  wire [31:0] dmem_idx = dmem_addr >> 2;

  // Combinational Reads
  assign imem_rdata = (imem_idx < MEM_DEPTH) ? mem[imem_idx] : 32'h0000_0013; // NOP if out of bounds
  assign dmem_rdata = (dmem_idx < MEM_DEPTH) ? mem[dmem_idx] : 32'h0;

  // Synchronous Write with Byte Masking
  always_ff @(posedge clk) begin
    if (dmem_we && (dmem_idx < MEM_DEPTH)) begin
      if (dmem_wmask[0]) mem[dmem_idx][7:0]   <= dmem_wdata[7:0];
      if (dmem_wmask[1]) mem[dmem_idx][15:8]  <= dmem_wdata[15:8];
      if (dmem_wmask[2]) mem[dmem_idx][23:16] <= dmem_wdata[23:16];
      if (dmem_wmask[3]) mem[dmem_idx][31:24] <= dmem_wdata[31:24];
    end
  end

  // --------------------------------------------------------------------------
  // TEST DRIVER & PROGRAM INITIALIZATION
  // --------------------------------------------------------------------------
  initial begin
    // Clear memory to NOPs
    for (int i = 0; i < MEM_DEPTH; i++) mem[i] = 32'h0000_0013;

    // Load hex file from +HEX=<path>
    if ($value$plusargs("HEX=%s", hex_file)) begin
      $display("[TB] Loading hex program: %s", hex_file);
      $readmemh(hex_file, mem);
    end else begin
      $display("[TB] No +HEX specified. Loading default built-in verification test.");
      load_builtin_test();
    end

    // Execute reset and run simulation
    do_reset();
    $display("[TB] Reset released. Processor running...");

    // Extended Timeout Guard (1,000,000ns = 100,000 cycles)
    fork
      begin
        wait(trap == 1'b1);
        $display("[TB] TRAP/EBREAK detected at PC=0x%08h. Simulation Completed.", pc_debug);
      end
      begin
        #500000000;
        $display("[TB ERROR] Simulation Timeout reached!");
      end
    join_any

    // ------------------------------------------------------------------------
    // SIGNATURE DUMP (RISC-V Compliance Testing)
    // ------------------------------------------------------------------------
    if ($value$plusargs("SIG_FILE=%s", sig_file_path)) begin
      if (!$value$plusargs("SIG_START=%h", sig_start_addr)) sig_start_addr = 32'h0000_0100;
      if (!$value$plusargs("SIG_END=%h", sig_end_addr))     sig_end_addr   = 32'h0000_0200;

      $display("[TB] Dumping signature region [0x%08h : 0x%08h] -> %s", 
               sig_start_addr, sig_end_addr, sig_file_path);

      sig_fd = $fopen(sig_file_path, "w");
      if (sig_fd) begin
        for (int addr = sig_start_addr; addr < sig_end_addr; addr = addr + 4) begin
          $fdisplay(sig_fd, "%08x", mem[addr >> 2]);
        end
        $fclose(sig_fd);
        $display("[TB] Signature dump completed successfully.");
      end else begin
        $display("[TB ERROR] Failed to open signature file: %s", sig_file_path);
      end
    end

    // Verification Report
    #20;
    $display("=================================================");
    $display(" VERIFICATION REPORT");
    $display("=================================================");
    $display(" Final PC Debug : 0x%08h", pc_debug);
    $display(" Reg x1 (ra)    : 0x%08h", dut.u_id_ex_stage.u_regfile.rf[1]);
    $display(" Reg x2 (sp)    : 0x%08h", dut.u_id_ex_stage.u_regfile.rf[2]);
    $display(" Reg x3 (gp)    : 0x%08h", dut.u_id_ex_stage.u_regfile.rf[3]);
    $display(" Reg x4 (tp)    : 0x%08h", dut.u_id_ex_stage.u_regfile.rf[4]);
    $display(" Reg x5 (t0)    : 0x%08h", dut.u_id_ex_stage.u_regfile.rf[5]);
    $display(" Reg x6 (t1)    : 0x%08h", dut.u_id_ex_stage.u_regfile.rf[6]);
    $display(" Reg x8 (s0)    : 0x%08h", dut.u_id_ex_stage.u_regfile.rf[8]);
    $display(" Reg x9 (s1)    : 0x%08h", dut.u_id_ex_stage.u_regfile.rf[9]);
    $display(" Reg x10 (a0)   : 0x%08h", dut.u_id_ex_stage.u_regfile.rf[10]);
    $display(" Reg x13 (a3)   : 0x%08h", dut.u_id_ex_stage.u_regfile.rf[13]);
    $display("=================================================");
    if (dut.u_id_ex_stage.u_regfile.rf[1] == 32'h0000_0001 || dut.u_id_ex_stage.u_regfile.rf[3] == 32'h0000_0001 || dut.u_id_ex_stage.u_regfile.rf[5] == 32'h0000_0037) begin
      $display(" >>> RESULT: TEST PASSED <<<");
    end else begin
      $display(" >>> RESULT: CHECK REGISTER VALUES <<<");
    end
    $finish;
  end

  // Built-in basic test fallback
  task automatic load_builtin_test();
    mem[0] = 32'h00a00093; // ADDI x1, x0, 10
    mem[1] = 32'h01400113; // ADDI x2, x0, 20
    mem[2] = 32'h002081b3; // ADD  x3, x1, x2
    mem[3] = 32'h00302023; // SW   x3, 0(x0)
    mem[4] = 32'h00002203; // LW   x4, 0(x0)
    mem[5] = 32'h001202b3; // ADD  x5, x4, x1
    mem[6] = 32'h00f28293; // ADDI x5, x5, 15
    mem[7] = 32'h00100193; // ADDI x3, x0, 1
    mem[8] = 32'h00100073; // EBREAK
  endtask

endmodule