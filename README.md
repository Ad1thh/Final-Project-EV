# RISC-V RV32E 3-Stage Pipelined Processor Core

This repository contains a **3-Stage Pipelined RV32E Synthesizable Processor Core**, developed in SystemVerilog. The core is designed to be fault-tolerant (featuring Selective Triple Modular Redundancy - TMR), synthesizable for ASICs (e.g., Cadence Genus 180nm), and verified against the RISC-V Formal suite.

## 🚀 Key Features

- **Architecture**: 3-Stage Pipeline (Fetch, Decode/Execute, Writeback) implementing the RV32E base integer instruction set (16 registers: `x0`-`x15`).
- **Hazard Handling**: 
  - Zero-cycle delay forwarding for Read-After-Write (RAW) dependencies (WB-to-ID/EX).
  - 1-cycle Load-Use stall detection (inserts a NOP bubble into ID/EX and freezes PC).
  - Predict-not-taken branch/jump redirection (flushes IF/ID pipeline on taken branches).
- **Fault Tolerance**: Selective Triple Modular Redundancy (TMR) on the ALU, with hardware fault injection hooks for testing Single Error Correction / Double Error Detection (SEC-DED).
- **ASIC Synthesizability**: 100% latch-free design, strict types (`logic` and `enum`), and clean clocking.
- **EDA Compatibility**: Cadence Xcelium, Siemens ModelSim/Questasim, Verilator, Synopsys VCS.

---

## 📁 Repository Structure (`rtl/`)

The RTL source code directory contains all 9 synthesizable SystemVerilog modules and package definitions required for elaboration:

| File | Description |
| :--- | :--- |
| `riscv_pkg.sv` | Global Package (Opcode enums, Funct3, ALU operations, WB mux selection) |
| `riscv_core_top.sv`| Top-level DUT module integrating all 3 pipeline stages |
| `if_stage.sv` | **Stage 1**: Instruction Fetch, Program Counter logic, IF/ID register |
| `id_ex_stage.sv` | **Stage 2**: Instruction Decode, Regfile, Control Unit, ALU, Forwarding |
| `wb_stage.sv` | **Stage 3**: Writeback Muxing & Sign/Zero Extension for Memory Loads |
| `regfile.sv` | 16-register (`x0`-`x15`) Dual-Read Single-Write Register File |
| `alu.sv` | 32-bit ALU supporting ADD, SUB, AND, OR, XOR, shifts, and comparisons |
| `control_unit.sv` | Main Decoder & ALU Control Generator |
| `hazard_unit.sv` | Data Hazard Detection, Forwarding Mux Control, Stall & Flush logic |
| `tmr_voter.sv` | Triple Modular Redundancy Voter for ALU output |

---

## 🔌 Interface & Memory Contract

The testbench interacts directly with `riscv_core_top.sv`.

### Memory Access Rules
1. **Instruction Memory (IMEM)**:
   - Synchronous/combinational byte-addressable read interface.
   - Address (`imem_addr`) is byte-aligned.
2. **Data Memory (DMEM)**:
   - Byte-aligned reads and writes.
   - Write Mask (`dmem_wmask`): `SB` (`4'b0001`), `SH` (`4'b0011`), `SW` (`4'b1111`).
   - Store Data (`dmem_wdata`) is pre-aligned by the core before output.

### Fault Tolerance & Mode Control
- **Selective TMR Mode**: Controlled by external pin `tmr_mode_pin` or a memory-mapped register at `0xFFFF_FFF0`.
- **Fault Injection Hooks**: Include `fi_reg_en` (Regfile fault injection) and `fi_alu_en` (ALU fault injection) to simulate transient hardware errors and verify SEC-DED logic.

---

## 🎯 Verification Test Plan

The core should be verified against the following key objectives:
1. **Memory Initialization**: Verify opcode fetch from PC `0x0`.
2. **Basic ALU Suite**: R-Type & I-Type arithmetic functionality.
3. **Data Hazard Test**: Verify RAW hazard forwarding (e.g., Fibonacci calculation).
4. **Load-Use Stall Test**: Verify 1-cycle bubble insertion.
5. **Control Hazard Test**: Verify Branch/Jump pipeline flushes.
6. **RISC-V Formal Suite**: Passing `rv32ui-p-*` compliance tests.

---

## 🛠️ EDA Tool Execution Commands

### Cadence Xcelium
```bash
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
