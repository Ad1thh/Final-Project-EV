# RISC-V RV32E Core - Student B Testbench & Verification Handoff Document

**Target Design**: 3-Stage Pipelined RV32E Core (`riscv_core_top`)  
**EDA Compatibility**: Cadence Xcelium, Siemens ModelSim / Questasim, Verilator, Synopsys VCS  
**Standards Compliance**: SystemVerilog-2012 IEEE 1800-2012  

---

## 1. 📦 Package Directory Structure (`rtl/`)

The RTL source code directory contains all 9 synthesizable SystemVerilog modules and package definitions required for elaboration:

```
rtl/
├── riscv_pkg.sv       # Global Package (Opcode enums, Funct3, ALU operations, WB mux selection)
├── riscv_core_top.sv  # Top-level DUT module integrating all 3 pipeline stages
├── if_stage.sv        # Stage 1: Instruction Fetch & Program Counter logic
├── id_ex_stage.sv     # Stage 2: Instruction Decode, Regfile, Control Unit, ALU & Forwarding
├── wb_stage.sv        # Stage 3: Writeback Muxing & Sign/Zero Extension for Memory Loads
├── regfile.sv         # 16-register x0-x15 Dual-Read Single-Write Register File (RV32E)
├── alu.sv             # Arithmetic Logic Unit (ADD, SUB, Shifts, Logical, Comparisons)
├── control_unit.sv    # Main Decoder & ALU Control Generator
└── hazard_unit.sv     # Data Hazard Detection, RAW Forwarding Mux Control, Load-Use Stall & Flush
```

---

## 2. 📜 Module Interface & Memory Contract Spec

The testbench interacts directly with `riscv_core_top.sv`. The signal declarations, direction, width, and functional contracts are defined below:

### DUT Port Summary

| Signal Name | Direction | Width | Description |
| :--- | :--- | :--- | :--- |
| `clk` | Input | 1-bit | Global System Clock (rising-edge triggered) |
| `rst_n` | Input | 1-bit | Asynchronous Active-Low Reset (resets PC to `0x0000_0000`) |
| `imem_addr` | Output | 32-bit | Instruction Memory Address (driven by current fetch PC) |
| `imem_rdata` | Input | 32-bit | Instruction Data (combinational read return from TB memory) |
| `dmem_addr` | Output | 32-bit | Data Memory Address (calculated by ALU during load/store) |
| `dmem_wdata` | Output | 32-bit | Write Data (byte/halfword/word aligned according to store type) |
| `dmem_wmask` | Output | 4-bit | Byte Write Enable Mask (`4'b0001` for SB, `4'b0011` for SH, `4'b1111` for SW) |
| `dmem_we` | Output | 1-bit | Global Data Write Enable (High during store instructions) |
| `dmem_rdata` | Input | 32-bit | Data Memory Read Data (returned to core during load instructions) |
| `pc_debug` | Output | 32-bit | Current PC trace for testbench monitoring and assertion checking |
| `trap` | Output | 1-bit | Exception/Halt Flag (Asserts on illegal instruction, `ECALL`, or `EBREAK`) |

### Memory Access & Alignment Rules

1. **Instruction Memory (IMEM)**:
   - Synchronous/combinational byte-addressable read interface.
   - Address `imem_addr` is byte-aligned (word-aligned accesses increment by 4: `0x0`, `0x4`, `0x8`, ...).
   - Testbench IMEM must respond to `imem_addr` without insertion of unexpected latency cycles.

2. **Data Memory (DMEM)**:
   - Byte-aligned reads and writes.
   - Write Mask (`dmem_wmask`):
     - `SB` (Store Byte): `4'b0001` (positioned at byte offset)
     - `SH` (Store Halfword): `4'b0011` (positioned at halfword offset)
     - `SW` (Store Word): `4'b1111`
   - Store Data (`dmem_wdata`) is pre-aligned by the core's ID/EX stage before output.

---

## 3. 🎯 Verification Test Plan & Benchmark Checklist

To verify full functionality and pipeline correctness, Student B should implement and execute the following test plan:

### Verification Plan Matrix

| Test Suite | Test Objective | Key Pipeline Verification Target | Success Criteria |
| :--- | :--- | :--- | :--- |
| **1. Memory Initialization** | Unified/Dual Memory Model | RAM initialized with `$readmemh("program.hex", mem)` | Correct opcode fetch from PC `0x0` |
| **2. Basic ALU Suite** | Single-cycle instruction verification | R-Type & I-Type arithmetic (`ADD`, `SUB`, `AND`, `OR`, `XOR`, `SLL`, `SRL`, `SRA`, `SLT`, `SLTU`) | Correct register state after execution |
| **3. Data Hazard Test** | RAW Hazard Forwarding | Fibonacci calculation (`RAW` hazard from EX/WB to ID/EX stage) | Correct Fibonacci result computed in regfile |
| **4. Load-Use Stall Test** | 1-Cycle Bubble Insertion | Back-to-back Load-Use (`LW x1, 0(x2); ADD x3, x1, x4`) | `stall_if` active for 1 cycle, correct `x3` result |
| **5. Control Hazard Test** | Branch/Jump Pipeline Flush | Loop counters (`count to 10`), `BEQ`, `BNE`, `JAL`, `JALR` | `flush_if_id` clears invalid instructions in branch shadow |
| **6. RISC-V Formal Suite** | Specification Compliance | `rv32ui-p-*` compliance tests | `gp`/`x3` register equals `1` or `trap` flag asserts with clean code |

---

## 4. 🛠️ CAD / EDA Tool Execution Commands

### Cadence Xcelium Compilation & Simulation
```bash
# Compile and elaborate design with SystemVerilog 2012 flag
xrun -sv -64bit -access +rwc \
  rtl/riscv_pkg.sv \
  rtl/if_stage.sv \
  rtl/id_ex_stage.sv \
  rtl/wb_stage.sv \
  rtl/regfile.sv \
  rtl/alu.sv \
  rtl/control_unit.sv \
  rtl/hazard_unit.sv \
  rtl/riscv_core_top.sv \
  tb/tb_riscv_core_top.sv
```

### Siemens ModelSim / QuestaSim
```tcl
vlib work
vlog -sv rtl/riscv_pkg.sv rtl/*.sv tb/tb_riscv_core_top.sv
vsim -c tb_riscv_core_top -do "run -all; quit"
```

### Verilator (C++ Testbench Driver)
```bash
verilator -Wall --trace --cc rtl/riscv_pkg.sv rtl/*.sv --top-module riscv_core_top --exe tb/tb_riscv_core_top.cpp
make -C obj_dir -f Vriscv_core_top.mk Vriscv_core_top
./obj_dir/Vriscv_core_top
```
