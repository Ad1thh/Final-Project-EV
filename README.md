# RV32E Fault-Tolerant 3-Stage Pipelined RISC-V Processor Core

**Targets:** ASIC Synthesis (Cadence Genus 180nm) & FPGA Implementation (Digilent / Xilinx Nexys 4 Artix-7 XC7A100T-1CSG324C)  
**HDL Standard:** SystemVerilog-2012  
**Synthesis & Toolchains:** AMD/Xilinx Vivado (Non-Interactive Batch Mode), Cadence Genus, Cadence Xcelium, ModelSim, Verilator, Icarus Verilog  

---

## 1. Overview & System Architecture

This repository contains an open-source, synthesizable, 3-stage pipelined **RV32E RISC-V Processor Core** with built-in hardware fault tolerance. It features:
- **Extended Hamming(38,32) SEC-DED ECC** on the 16-entry register file (`x0`-`x15`).
- **Selective Triple Modular Redundancy (TMR)** on the ALU with low-power operand isolation and 3-way majority voting.
- **Hardware Fault Injection & Diagnostic Telemetry** with software mode control via memory-mapped I/O (`0xFFFF_FFF0`) and external pins.
- **Hardware Hazard Unit** providing zero-cycle internal register forwarding, 1-cycle Load-Use stall insertion, and branch misprediction flushes.
- **FPGA Deployment**: Verified on Xilinx Nexys 4 FPGA with Unified 32 KB Block RAM and MMIO LED diagnostics (`0x8000_0000`).

```
       +-------------------------------------------------------------+
       |                  RISC-V 3-Stage Pipeline                    |
       |                                                             |
       |   +------------+      +---------------+      +----------+   |
       |   | IF Stage   | ---> | ID/EX Stage   | ---> | WB Stage |   |
       |   | (Fetch)    |      | (Decode/Exec) |      | (Write)  |   |
       |   +------------+      +---------------+      +----------+   |
       +---------|--------------------|-------------------|----------+
                 |                    |                   |
                 v                    v                   v
      +------------------------------------------------------------------+
      |               Unified Block RAM (32 KB Memory)                   |
      +------------------------------------------------------------------+
                                      |
                                      v (Address >= 0x80000000)
      +------------------------------------------------------------------+
      |                 MMIO Peripheral: 16 Board LEDs                   |
      +------------------------------------------------------------------+
```

---

## 2. Project Development Phase Matrix

| Phase | Feature / Component | Status | Summary |
| :--- | :--- | :---: | :--- |
| **Phase 1** | Base 3-Stage RV32E Core Pipeline | **100% Complete** | Baseline SystemVerilog RTL (`rtl/*.sv`) fully optimized and verified. |
| **Phase 2** | Custom RTL Simulation & Stress Fuzzing | **100% Complete** | Automated regression suites passing 100%. |
| **Phase 3** | Architectural Compliance (ACT 4.0) | **100% Complete** | **195/195 RV32I architectural compliance tests passed**. |
| **Phase 4** | **Baseline FPGA Synthesis & Silicon Validation** | **100% Complete** | **Baseline Vivado bitstream generated & verified live on Nexys 4 FPGA silicon (`0x80FF` PASS pattern confirmed).** |
| **Phase 5** | **ECC Register File & Adaptive Fault-Tolerance (TMR / SEC-DED)** | **100% Complete** | **Integrated Hamming(38,32) SEC-DED and Triplicated ALU majority voting with operand isolation.** |
| **Phase 6** | **Cadence ASIC Synthesis, Power, Area & Timing Evaluation** | **Ready for ASIC** | **ASIC-synthesizable latch-free RTL ready for Cadence Genus / Innovus flow.** |

---

## 3. Microarchitecture & Fault Tolerance

### Pipeline Stages
1. **Stage 1: Fetch (IF):**
   - Manages Program Counter (`pc_reg`) generation.
   - Reads 32-bit instructions from Block RAM (`imem_addr`).
   - Supports 1-cycle pipeline flushes on taken branches/jumps and freeze on load-use hazards.
2. **Stage 2: Decode & Execute (ID/EX):**
   - Decodes RV32E opcodes and extracts 16-entry register operands (`x0-x15`).
   - Integrates **Hamming(38,32) SEC-DED ECC Register File** (`regfile.sv`) with single-bit correction and double-bit error detection.
   - Contains **Triplicated ALUs** with **3-way Majority Voter** (`tmr_voter.sv`) and operand isolation in Simplex mode.
   - Evaluates branch conditions (`BEQ`, `BNE`, `BLT`, `BGE`, `BLTU`, `BGEU`) and computes jump targets (`JAL`, `JALR`).
   - Formats Data Memory write data (`dmem_wdata`) and write masks (`dmem_wmask`) for byte (`SB`), halfword (`SH`), and word (`SW`) stores.
3. **Stage 3: Writeback (WB):**
   - Aligns and sign/zero-extends memory load data (`LB`, `LBU`, `LH`, `LHU`, `LW`).
   - Selects Writeback result (`ALU`, `Memory`, or `PC+4`).
   - Forwards writeback data to Decode stage in real time via register file bypass.

### Fault Tolerance & Mode Control
- **Selective TMR Mode**: Controlled dynamically by external pin `tmr_mode_pin` or a software register mapped to address `0xFFFF_FFF0`.
- **Fault Injection Interface**:
  - `fi_reg_en`, `fi_reg_addr`, `fi_reg_bit`: Injects bit flips into the 39-bit register codeword.
  - `fi_alu_en`, `fi_alu_sel`, `fi_alu_bit`: Injects bit flips directly into ALU instance results.
- **Diagnostic Telemetry Flags**:
  - `ecc_sec_1`, `ecc_sec_2`: Single Error Corrected flags for read ports 1 and 2.
  - `ecc_ded_1`, `ecc_ded_2`: Double Error Detected flags for read ports 1 and 2.
  - `tmr_mismatch`: Flags when ALU instances disagree.
  - `tmr_fatal_mismatch`: Flags when all three ALU instances disagree simultaneously.

---

## 4. Repository Structure

```
├── rtl/                          # Synthesizable SystemVerilog RTL
│   ├── alu.sv                    # 32-bit Arithmetic Logic Unit
│   ├── control_unit.sv           # Opcode & Control Signal Decoder
│   ├── hazard_unit.sv            # Load-Use Stall & Flush Detection
│   ├── id_ex_stage.sv            # Decode/Execute with Triplicated ALU & Voter
│   ├── if_stage.sv               # Instruction Fetch & PC Generation
│   ├── regfile.sv                # 16-Entry Regfile with SEC-DED ECC (39 bits)
│   ├── riscv_core_top.sv         # Top-level processor wrapper & mode register
│   ├── riscv_pkg.sv              # Opcodes, Enums, and Package Constants
│   ├── tmr_voter.sv              # 3-Way Majority Voter with Fatal Mismatch
│   └── wb_stage.sv               # Writeback Multiplexer & Load Alignment
├── tb/                           # Comprehensive Testbench Suite
│   ├── tb_compliance_run.sv      # Architectural Compliance Runner
│   ├── tb_core_stress_adversarial.sv # Pipeline & Fault Stress Fuzzing
│   ├── tb_fault_tolerance.sv     # Dynamic TMR & Memory Mode Testbench
│   ├── tb_regfile_unit.sv        # SEC-DED ECC Unit Testbench
│   ├── tb_reset_probe.sv         # Reset & Power-On Sequence Verification
│   ├── tb_riscv_core_top.sv      # Full-System Core Integration Testbench
│   ├── tb_sec_ded_adversarial.sv # Exhaustive 39-bit SEC-DED Injection Test
│   ├── tb_tmr_adversarial.sv     # Exhaustive ALU Opcode Fault Sweep
│   └── tb_tmr_unit.sv            # Voter Unit Testbench
├── fpga/                         # FPGA Top & Assembly Firmware
│   ├── fpga_top.sv               # Nexys 4 Top-level Wrapper & Clock Synchronizer
│   └── hardware_test.s           # Diagnostic Self-Testing Firmware
├── constraints/                  # Xilinx Design Constraints
│   └── nexys4.xdc                # Pinout for Artix-7 XC7A100T-1CSG324C
└── fpga-demo-dashboard/          # Interactive Next.js 3D Web Dashboard
```

---

## 5. FPGA System Interfaces & Memory Map

### Clocking & Reset System
- **Input Clock:** 100 MHz board oscillator (`CLK100MHZ`).
- **Internal Clock:** Divided down to **25 MHz** using a 2-bit counter and driven through a global clock buffer (`BUFG`).
- **Reset:** Active-low pushbutton `CPU_RESETN` (`E16`) fed into a 2-stage asynchronous reset synchronizer with an Automatic Power-On Reset Generator (256 cycles).

### Address Space Memory Map
| Address Range | Size | Component | Access Type |
| :--- | :--- | :--- | :--- |
| `0x0000_0000` - `0x0000_7FFF` | 32 KB | Unified Block RAM (Instructions & Data) | Read / Write |
| `0x8000_0000` - `0x8000_0004` | 4 Bytes | MMIO LED Register (`LED[15:0]`) | Read / Write |
| `0xFFFF_FFF0` | 4 Bytes | Fault-Tolerance Mode Control (`bit 0: TMR enable`) | Read / Write |

---

## 6. Complete FPGA Pin & Port Mapping Table

All ports map to physical pins on the **Xilinx Nexys 4 (Artix-7 XC7A100T-1CSG324C)** board configured for `LVCMOS33` in `constraints/nexys4.xdc`.

### System Control Signals
| Top-Level Port Name | Direction | Nexys 4 Pin | I/O Standard | Description |
| :--- | :--- | :--- | :--- | :--- |
| `CLK100MHZ` | Input | **E3** | `LVCMOS33` | 100 MHz Board System Clock |
| `CPU_RESETN` | Input | **E16** | `LVCMOS33` | Center Pushbutton `BTNC` (Active-High Reset) |

### User LED Outputs (`LED[15:0]`)
| Top-Level Port Name | Direction | Nexys 4 Pin | I/O Standard | Hardware Assignment |
| :--- | :--- | :--- | :--- | :--- |
| `LED[0]` | Output | **T8** | `LVCMOS33` | LED 0 (Diagnostic Stage Bit 0) |
| `LED[1]` | Output | **V9** | `LVCMOS33` | LED 1 (Diagnostic Stage Bit 1) |
| `LED[2]` | Output | **R8** | `LVCMOS33` | LED 2 (Diagnostic Stage Bit 2) |
| `LED[3]` | Output | **T6** | `LVCMOS33` | LED 3 (Diagnostic Stage Bit 3) |
| `LED[4]` | Output | **T5** | `LVCMOS33` | LED 4 (Pass Chaser Bit 0) |
| `LED[5]` | Output | **T4** | `LVCMOS33` | LED 5 (Pass Chaser Bit 1) |
| `LED[6]` | Output | **U7** | `LVCMOS33` | LED 6 (Pass Chaser Bit 2) |
| `LED[7]` | Output | **U6** | `LVCMOS33` | LED 7 (Pass Chaser Bit 3) |
| `LED[8]` | Output | **V4** | `LVCMOS33` | LED 8 (Pass Chaser Bit 4) |
| `LED[9]` | Output | **U3** | `LVCMOS33` | LED 9 (Pass Chaser Bit 5) |
| `LED[10]` | Output | **V1** | `LVCMOS33` | LED 10 (Pass Chaser Bit 6) |
| `LED[11]` | Output | **R1** | `LVCMOS33` | LED 11 (Pass Chaser Bit 7) |
| `LED[12]` | Output | **P5** | `LVCMOS33` | LED 12 (Error Alert Bit 0) |
| `LED[13]` | Output | **U1** | `LVCMOS33` | LED 13 (Error Alert Bit 1) |
| `LED[14]` | Output | **R2** | `LVCMOS33` | LED 14 (Error Alert Bit 2) |
| `LED[15]` | Output | **P2** | `LVCMOS33` | LED 15 (System Pass / Power Status Indicator) |

---

## 7. Self-Diagnostic Protocol & LED Status Legend

The core executes `fpga/hardware_test.s` upon boot:

1. **Boot Flash:** Alternates `0xAAAA` → `0x5555` on all 16 LEDs.
2. **Stage 1 (ALU Test):** Executes ADD, SUB, AND, OR, XOR, SLT. `LED[3:0] = 0x1`.
3. **Stage 2 (Shift Test):** Executes SLLI, SRLI, SRAI, LUI. `LED[3:0] = 0x2`.
4. **Stage 3 (Memory Test):** Executes word/halfword/byte loads & stores (`SW`, `SH`, `SB`, `LW`, `LH`, `LB`, `LHU`, `LBU`) at RAM address `0x400`. `LED[3:0] = 0x3`.
5. **Stage 4 (Branch/Jump Test):** Executes `BEQ`, `BLT`, `JAL`, `JALR`. `LED[3:0] = 0x4`.
6. **PASS Result:** `LED[15] = 1` ON + lower 8 LEDs run dynamic visual chaser (`0x80FF`).
7. **FAIL Alert:** `LED[15:12] = 0xF` ON + `LED[3:0]` shows exact failing stage ID (`0xF001` - `0xF004`).

---

## 8. Simulation & Verification Commands

### Cadence Xcelium
```bash
xrun -sv -64bit -access +rwc \
  rtl/riscv_pkg.sv \
  rtl/if_stage.sv \
  rtl/id_ex_stage.sv \
  rtl/wb_stage.sv \
  rtl/regfile.sv \
  rtl/alu.sv \
  rtl/tmr_voter.sv \
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

---

## 9. How to Build & Load FPGA Bitstream

### 1-Click Master Script (Windows CMD or PowerShell)
Connect your Nexys 4 board via USB, power it on, and execute:

```cmd
.\fpga\build_and_program.bat
```

### Manual TCL Execution (Vivado Non-Interactive Mode)
```cmd
# 1. Assemble Assembly Firmware to Hex
python sim/asm.py fpga/hardware_test.s fpga/firmware.hex

# 2. Run Non-Interactive Synthesis & Bitstream Build
vivado -mode batch -source fpga/build_bitstream.tcl

# 3. Flash Bitstream onto Connected Nexys 4 FPGA Board
vivado -mode batch -source fpga/program_fpga.tcl
```
