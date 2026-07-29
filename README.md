# RV32E 3-Stage Pipelined RISC-V Processor Core
**Hardware Target:** Xilinx Nexys 4 FPGA (Artix-7 `XC7A100T-1CSG324C`)  
**Hardware Verification Status:** **100% CONFIRMED LIVE ON SILICON (`0x80FF` PASS Pattern)**  
**Toolchain:** AMD/Xilinx Vivado (Non-Interactive Batch Mode) / SystemVerilog-2012  
**Git Branch:** `baseline-rv32e-verified`  

---

## 1. 📌 Executive Summary & Architecture Overview

This repository branch contains the **100% tested, verified, and silicon-proven baseline implementation** of an **RV32E 3-Stage Pipelined RISC-V Processor Core**.

The core is engineered from scratch in SystemVerilog-2012, featuring real-time data hazard forwarding, load/store alignment units, branch/jump control hazard flushing, unified Block RAM, and Memory-Mapped I/O (MMIO) driving 16 physical user LEDs on the Digilent Nexys 4 FPGA board.

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

## 2. 🏗️ Microarchitecture Breakdown (A to Z)

### A. Stage 1: Fetch Stage (`rtl/if_stage.sv`)
- **Program Counter (`pc_reg`):** 32-bit register reset to `0x0000_0000`. Increments by `4` every clock cycle.
- **Instruction Fetch:** Address sent to Block RAM (`imem_addr = pc_reg`).
- **Control Hazard Flush:** When a branch or jump is taken in EX stage, flushes instruction in IF/ID to `NOP` (`0x0000_0013`) in 1 clock cycle and updates PC to `target_pc`.

### B. Stage 2: Decode & Execute Stage (`rtl/id_ex_stage.sv`)
- **RV32E Register File (`rtl/regfile.sv`):** 16 x 32-bit registers (`x0` hardwired to `0`, `x1` to `x15`).
- **Arithmetic Logic Unit (`rtl/alu.sv`):** Executes ADD, SUB, AND, OR, XOR, SLT, SLTU, SLLI, SRLI, SRAI.
- **Branch Evaluator:** Evaluates conditions for `BEQ`, `BNE`, `BLT`, `BGE`, `BLTU`, `BGEU` using forwarded operands.
- **Store Alignment Unit:** Formats byte (`SB`), halfword (`SH`), and word (`SW`) store data and computes byte-enable write masks (`dmem_wmask`).
- **Control Unit (`rtl/control_unit.sv`):** Generates execution signals based on RV32E opcodes.
- **Trap Unit (`rtl/trap_unit.sv`):** Enforces RV32E bounds checking (`x0-x15`) and traps illegal register indices (`x16-x31`).

### C. Stage 3: Writeback Stage (`rtl/wb_stage.sv`)
- **Load Alignment Unit:** Formats byte (`LB`, `LBU`), halfword (`LH`, `LHU`), and word (`LW`) load data with sign or zero extension based on address offsets.
- **Writeback MUX:** Selects between ALU output, Memory load output, or PC+4 (Link address).
- **Forwarding Unit (`rtl/hazard_unit.sv`):** Forwards writeback results directly to EX stage inputs in real time, eliminating RAW stall penalties.

---

## 3. 🗺️ Memory Map & Bus Specifications

| Address Range | Memory Region | Size | Access Type | Hardware Device |
| :--- | :--- | :--- | :--- | :--- |
| `0x0000_0000` - `0x0000_7FFF` | Unified BRAM Memory | 32 KB | Read / Write | Artix-7 Dual-Port Block RAM |
| `0x8000_0000` - `0x8000_0004` | MMIO LED Register | 4 Bytes | Read / Write | 16 Physical User LEDs (`LED[15:0]`) |

---

## 4. 📌 Complete Pin & Constraints Table (`constraints/nexys4.xdc`)

All ports are mapped for the **Digilent Nexys 4 (Artix-7 XC7A100T-1CSG324C)** board under standard `LVCMOS33` I/O parameters.

### System Clock & Hardware Reset Pins
| Port Name | Direction | Nexys 4 Pin | I/O Standard | Functional Specification |
| :--- | :--- | :--- | :--- | :--- |
| `CLK100MHZ` | Input | **E3** | `LVCMOS33` | 100 MHz Master System Clock |
| `CPU_RESETN` | Input | **E16** | `LVCMOS33` | Center Pushbutton `BTNC` (Active-High Reset) |

### 16 User LED Output Pins (`LED[15:0]`)
| Port Name | Direction | Nexys 4 Pin | I/O Standard | Diagnostic Signal Assignment |
| :--- | :--- | :--- | :--- | :--- |
| `LED[0]` | Output | **T8** | `LVCMOS33` | Test Stage Bit 0 (Stage 1 Active) |
| `LED[1]` | Output | **V9** | `LVCMOS33` | Test Stage Bit 1 (Stage 2 Active) |
| `LED[2]` | Output | **R8** | `LVCMOS33` | Test Stage Bit 2 (Stage 4 Active) |
| `LED[3]` | Output | **T6** | `LVCMOS33` | Test Stage Bit 3 (Failure Code Bit 0) |
| `LED[4]` | Output | **T5** | `LVCMOS33` | Chaser Bit 0 / Status Indicator |
| `LED[5]` | Output | **T4** | `LVCMOS33` | Chaser Bit 1 / Status Indicator |
| `LED[6]` | Output | **U7** | `LVCMOS33` | Chaser Bit 2 / Status Indicator |
| `LED[7]` | Output | **U6** | `LVCMOS33` | Chaser Bit 3 / Status Indicator |
| `LED[8]` | Output | **V4** | `LVCMOS33` | Chaser Bit 4 / Status Indicator |
| `LED[9]` | Output | **U3** | `LVCMOS33` | Chaser Bit 5 / Status Indicator |
| `LED[10]` | Output | **V1** | `LVCMOS33` | Chaser Bit 6 / Status Indicator |
| `LED[11]` | Output | **R1** | `LVCMOS33` | Chaser Bit 7 / Status Indicator |
| `LED[12]` | Output | **P5** | `LVCMOS33` | Error Alert Bit 0 |
| `LED[13]` | Output | **U1** | `LVCMOS33` | Error Alert Bit 1 |
| `LED[14]` | Output | **R2** | `LVCMOS33` | Error Alert Bit 2 |
| `LED[15]` | Output | **P2** | `LVCMOS33` | **100% Hardware PASS / System Power Indicator** |

---

## 5. 🔬 Diagnostic Firmware Protocol (`fpga/hardware_test.s`)

The baseline branch executes a self-checking assembly suite upon power-up:

```
[BOOT FLASH] 0xAAAA -> 0x5555  -->  [STAGE 1] ALU  -->  [STAGE 2] SHIFT  -->  [STAGE 3] BRAM  -->  [STAGE 4] BRANCH  -->  [STAGE 5] 100% PASS (0x80FF + Chaser)
```

### Self-Diagnostic Stages Matrix
| Diagnostic Stage | Assembly Verification Scope | Board LED Output (`LED[15:0]`) | Hardware Verification Result |
| :--- | :--- | :--- | :---: |
| **Boot Display** | Power-on visual flash | `0xAAAA` → `0x5555` alternating flash | **CONFIRMED PASS** |
| **Stage 1** | ALU Ops (ADD, SUB, AND, OR, XOR, SLT) | `LED[0]` ON (`0x0001`) | **CONFIRMED PASS** |
| **Stage 2** | Shifts & Immediates (SLLI, SRLI, SRAI, LUI) | `LED[1]` ON (`0x0002`) | **CONFIRMED PASS** |
| **Stage 3** | Memory Alignment & Access (SW, LW, SB, LBU, SH, LHU) | `LED[0]` & `LED[1]` ON (`0x0003`) | **CONFIRMED PASS** |
| **Stage 4** | Control Flow Hazards (BEQ, BLT, JAL, JALR) | `LED[2]` ON (`0x0004`) | **CONFIRMED PASS** |
| **Stage 5** | **100% Hardware Validation** | **`LED[15]` ON + Lower 8 LEDs Active Chaser (`0x80FF`)** | **PASSED & VERIFIED LIVE ON SILICON** |

---

## 6. 📊 Vivado Synthesis & Hardware Signoff Metrics

- **Target FPGA Board:** Digilent Nexys 4 (Artix-7 `xc7a100tcsg324-1`)
- **System Clock Target:** 25.00 MHz (Derived from 100 MHz oscillator)
- **Timing Signoff:** **PASSED** (Worst Negative Slack **`WNS = +8.042 ns`**, **0 timing violations**)
- **Routing Status:** 100% Routed (**0 Unrouted Nets**, **0 Failed Nets**)
- **Bitstream Artifact:** `fpga/fpga_top.bit` (3.82 MB)
- **JTAG Startup Status:** `INFO: [Labtools 27-3164] End of startup status: HIGH`

---

## 7. 📁 Complete Repository Directory Tree (A to Z)

```text
Final_Project/
├── .gitignore                      # Git exclusion rules for temporary Vivado files
├── README.md                       # Master branch documentation (A to Z guide)
├── filelist.f                      # Verilog compilation manifest file
├── firmware.hex                    # Root assembled binary firmware hex
├── constraints/
│   └── nexys4.xdc                  # Pin constraint mappings for Xilinx Nexys 4 board
├── fpga/
│   ├── build_and_program.bat       # 1-Click master batch script with Vivado auto-detection
│   ├── build_bitstream.tcl         # Non-interactive Vivado TCL bitstream build script
│   ├── firmware.hex                # FPGA directory binary firmware hex
│   ├── fpga_top.bit                # Synthesized 3.82 MB FPGA bitstream
│   ├── fpga_top.sv                 # Top-level FPGA wrapper & power-on reset generator
│   ├── hardware_test.s             # Self-checking assembly diagnostic suite
│   ├── program_fpga.tcl            # Non-interactive Vivado JTAG programming script
│   ├── timing_report.txt           # Post-implementation timing summary report
│   └── utilization_report.txt      # Post-implementation hardware resource utilization report
├── rtl/
│   ├── alu.sv                      # 32-bit Arithmetic Logic Unit
│   ├── control_unit.sv             # RV32E Instruction Decoder & Control Signal Unit
│   ├── hazard_unit.sv              # Real-time RAW Forwarding & Control Hazard Flush Unit
│   ├── id_ex_stage.sv              # Stage 2 Decode, Execute, Branch & Store Alignment
│   ├── if_stage.sv                 # Stage 1 Program Counter & Instruction Fetch Unit
│   ├── regfile.sv                  # 16 x 32-bit RV32E Register File
│   ├── riscv_core_top.sv           # Top-level RISC-V CPU Core Interconnect Wrapper
│   ├── trap_unit.sv                # RV32E Bounds & Exception Enforcement Unit
│   └── wb_stage.sv                 # Stage 3 Memory Load Alignment & Writeback Unit
├── sim/
│   └── asm.py                      # Custom Python RISC-V Assembler & Hex Compiler
└── updates/
    └── PROJECT_PROGRESS_REPORT.md  # Detailed technical project status report for teammates
```

---

## 8. 🚀 Replication & Execution Guide

### Step 1: Clone and Checkout Branch
```cmd
git clone https://github.com/Ad1thh/Final-Project-EV.git
cd Final-Project-EV
git checkout baseline-rv32e-verified
```

### Step 2: 1-Click Automated Build & Flashing (Windows CMD / PowerShell)
Connect your Nexys 4 board via USB, turn on power, and run:

```cmd
.\fpga\build_and_program.bat
```

### Step 3: Manual Execution (Command Line)
```cmd
# 1. Assemble assembly firmware to machine code hex
python sim/asm.py fpga/hardware_test.s fpga/firmware.hex

# 2. Run non-interactive Vivado bitstream synthesis
vivado -mode batch -source fpga/build_bitstream.tcl

# 3. Flash bitstream onto connected Nexys 4 FPGA board
vivado -mode batch -source fpga/program_fpga.tcl
```
