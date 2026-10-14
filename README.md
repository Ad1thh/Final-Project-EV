# Baseline RV32E 3-Stage Pipelined RISC-V Processor Core

**Hardware Target:** Digilent Nexys 4 FPGA (AMD/Xilinx Artix-7 `XC7A100T-1CSG324C`)  
**Hardware Verification Status:** **100% CONFIRMED LIVE ON SILICON (`0x80FF` PASS Pattern)**  
**Toolchain:** AMD/Xilinx Vivado (Non-Interactive Batch Mode) / SystemVerilog-2012  
**Git Branch:** `RISC-V-Core`  

---

## 1. 📌 Executive Summary & Role in Project

This branch contains the **Golden Baseline RV32E 3-Stage Pipelined Processor Core**.

It represents the unhardened, pure-performance reference implementation of the RV32E ISA (16 registers `x0`-`x15`, integer base instructions). It was designed, synthesized, and verified on physical FPGA silicon to establish empirical ground truth for:
1. **Baseline Resource Utilization:** Minimum LUT, Flip-Flop, and BRAM consumption on FPGA.
2. **Baseline Timing & Frequency:** Pure critical path slack without TMR voters or ECC XOR trees.
3. **Reference Verification:** Golden standard against which fault-tolerant variants (`main`, `cadence`, `vitis-deployment`) are compared for area overhead, power penalty, and fault mitigation effectiveness.

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

## 2. ⚖️ Architectural Comparison: Baseline vs. Fault-Tolerant Core

| Subsystem | Baseline RV32E (`RISC-V-Core`) | Fault-Tolerant RV32E (`main` / `cadence`) |
| :--- | :--- | :--- |
| **Instruction Set** | RV32E Base Integer (16 Regs `x0`-`x15`) | RV32E Base Integer (16 Regs `x0`-`x15`) |
| **Pipeline Depth** | 3 Stages (IF → ID/EX → WB) | 3 Stages (IF → ID/EX → WB) |
| **Register File** | 16 entries &times; 32 bits (standard D-FF array) | 16 entries &times; 39 bits (**Extended Hamming SEC-DED ECC**) |
| **ECC Capabilities** | None (Single Event Upsets will corrupt data) | **Single Error Correction, Double Error Detection** |
| **Arithmetic Logic Unit**| Single 32-bit ALU (`rtl/alu.sv`) | **Triplicated ALUs** with 2-of-3 bitwise Majority Voter |
| **Program Counter** | Single 32-bit register (`pc_reg`) | **Triplicated PC Registers** (`pc_reg_a/b/c`) with 2-of-3 Voter |
| **Control Unit Decoder**| Single combinational decoder | **Dual Modular Redundancy (DMR)** with Real-Time Lockstep Checker |
| **Fault Injection Hooks**| None (standard operational mode) | Direct bit-flip injection (`fi_reg_*`, `fi_alu_*`) & Telemetry flags |
| **FPGA Utilization** | **Minimum Area Footprint** | ~35-45% higher logic due to structural redundancy |

---

## 3. 🏗️ Microarchitecture Breakdown (A to Z)

### A. Stage 1: Fetch Stage (`rtl/if_stage.sv`)
- **Program Counter (`pc_reg`):** 32-bit register initialized to `0x0000_0000`. Increments by `4` every clock cycle under normal sequential flow.
- **Instruction Memory Fetch:** Directly drives the dual-port Block RAM address bus (`imem_addr = pc_reg`).
- **Control Hazard Flush:** When a branch or jump condition evaluates true in the EX stage, the pending instruction in IF/ID is synchronously flushed to a hardware `NOP` (`0x0000_0013`) in 1 clock cycle, and the PC jumps to `target_pc`.

### B. Stage 2: Decode & Execute Stage (`rtl/id_ex_stage.sv`)
- **RV32E Register File (`rtl/regfile.sv`):** 16 &times; 32-bit dual-read single-write register array (`x0` hardwired to zero).
- **Arithmetic Logic Unit (`rtl/alu.sv`):** Executes ADD, SUB, AND, OR, XOR, SLT, SLTU, SLLI, SRLI, SRAI.
- **Branch Evaluator:** Evaluates conditions for `BEQ`, `BNE`, `BLT`, `BGE`, `BLTU`, `BGEU` using forwarded operands.
- **Store Alignment Unit:** Formats byte (`SB`), halfword (`SH`), and word (`SW`) store data and computes byte-enable write masks (`dmem_wmask`).
- **Control Unit (`rtl/control_unit.sv`):** Decodes RV32E opcodes and asserts control signals for ALU, memory, and register writeback.
- **Trap Unit (`rtl/trap_unit.sv`):** Enforces RV32E architecture bounds (`x0-x15`) and traps illegal register accesses (`x16-x31`).

### C. Stage 3: Writeback Stage (`rtl/wb_stage.sv`)
- **Load Alignment Unit:** Formats byte (`LB`, `LBU`), halfword (`LH`, `LHU`), and word (`LW`) load data with sign or zero extension based on memory address offset bits `[1:0]`.
- **Writeback MUX:** Selects between ALU output, Memory load output, or PC+4 (Link address for `JAL`/`JALR`).
- **Forwarding Unit (`rtl/hazard_unit.sv`):** Forwards writeback results directly to EX stage operand multiplexers in real time, eliminating Read-After-Write (RAW) stall cycles.

---

## 4. 🗺️ Memory Map & Peripheral Interface

| Address Range | Memory Region | Size | Access Type | Physical Hardware Device |
| :--- | :--- | :--- | :--- | :--- |
| `0x0000_0000` - `0x0000_7FFF` | Unified BRAM Memory | 32 KB | Read / Write | Artix-7 Dual-Port Block RAM (Code & Data) |
| `0x8000_0000` - `0x8000_0004` | MMIO LED Register | 4 Bytes | Read / Write | 16 Physical User LEDs (`LED[15:0]`) |

---

## 5. 📌 Digilent Nexys 4 FPGA Pin & Port Table (`constraints/nexys4.xdc`)

All pins configured for the **AMD/Xilinx Artix-7 XC7A100T-1CSG324C** FPGA under `LVCMOS33`.

### System Clocks & Controls
| Port Name | Direction | Nexys 4 Pin | I/O Standard | Description |
| :--- | :--- | :--- | :--- | :--- |
| `CLK100MHZ` | Input | **E3** | `LVCMOS33` | 100 MHz On-Board Master Crystal Oscillator |
| `CPU_RESETN` | Input | **E16** | `LVCMOS33` | Center Pushbutton `BTNC` (Active-High Reset) |

### User Diagnostic LEDs (`LED[15:0]`)
| Port Name | Direction | Nexys 4 Pin | Diagnostic Assignment |
| :--- | :--- | :--- | :--- |
| `LED[0]` | Output | **T8** | Test Stage Bit 0 (Stage 1 Active) |
| `LED[1]` | Output | **V9** | Test Stage Bit 1 (Stage 2 Active) |
| `LED[2]` | Output | **R8** | Test Stage Bit 2 (Stage 4 Active) |
| `LED[3]` | Output | **T6** | Test Stage Bit 3 (Failure Code Bit 0) |
| `LED[4]` - `LED[11]` | Output | **T5, T4, U7, U6, V4, U3, V1, R1** | Chaser Visual Heartbeat / Pass Status Indicator |
| `LED[12]` - `LED[14]` | Output | **P5, U1, R2** | Hardware Error Code Indicator Bits |
| `LED[15]` | Output | **P2** | **100% Silicon PASS / System Health Indicator** |

---

## 6. 🔬 Diagnostic Firmware Protocol (`fpga/hardware_test.s`)

The baseline core executes a comprehensive self-checking assembly suite upon boot:

```
[BOOT FLASH] 0xAAAA -> 0x5555  -->  [STAGE 1] ALU  -->  [STAGE 2] SHIFT  -->  [STAGE 3] BRAM  -->  [STAGE 4] BRANCH  -->  [STAGE 5] 100% PASS (0x80FF + Chaser)
```

### Self-Diagnostic Stages Matrix
| Diagnostic Stage | Assembly Verification Scope | Board LED Output (`LED[15:0]`) | Hardware Result |
| :--- | :--- | :--- | :---: |
| **Boot Display** | Power-on visual flash | `0xAAAA` &rarr; `0x5555` alternating flash | **CONFIRMED PASS** |
| **Stage 1** | ALU Ops (ADD, SUB, AND, OR, XOR, SLT) | `LED[0]` ON (`0x0001`) | **CONFIRMED PASS** |
| **Stage 2** | Shifts & Immediates (SLLI, SRLI, SRAI, LUI) | `LED[1]` ON (`0x0002`) | **CONFIRMED PASS** |
| **Stage 3** | Memory Alignment & Access (SW, LW, SB, LBU, SH, LHU) | `LED[0]` & `LED[1]` ON (`0x0003`) | **CONFIRMED PASS** |
| **Stage 4** | Control Flow Hazards (BEQ, BLT, JAL, JALR) | `LED[2]` ON (`0x0004`) | **CONFIRMED PASS** |
| **Stage 5** | **100% Hardware Validation** | **`LED[15]` ON + Lower 8 LEDs Active Chaser (`0x80FF`)** | **PASSED & VERIFIED ON SILICON** |

---

## 7. 📊 Vivado Synthesis & Implementation Signoff Metrics

- **Target FPGA Board:** Digilent Nexys 4 (Artix-7 `xc7a100tcsg324-1`)
- **System Operating Clock:** 25.00 MHz (Derived from 100 MHz oscillator via clock divider)
- **Timing Signoff:** **PASSED** (Worst Negative Slack **`WNS = +8.042 ns`**, **0 Timing Violations**)
- **Routing Status:** 100% Routed (**0 Unrouted Nets**, **0 Failed Nets**)
- **Bitstream Artifact:** `fpga/fpga_top.bit` (3.82 MB)
- **JTAG Startup Status:** `INFO: [Labtools 27-3164] End of startup status: HIGH`

---

## 8. 📁 Directory Structure

```text
Final_Project/
├── README.md                       # This baseline documentation guide
├── filelist.f                      # Verilog compilation manifest file
├── firmware.hex                    # Root assembled binary firmware hex
├── constraints/
│   └── nexys4.xdc                  # Nexys 4 Artix-7 pin & timing constraints
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
├── riscv-arch-test/                # Official RISC-V Architectural Compliance Test Suite
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
    └── PROJECT_PROGRESS_REPORT.md  # Detailed technical project status report
```

---

## 9. 🚀 Build & Verification Instructions

### Step 1: Switch to this Branch
```cmd
git checkout RISC-V-Core
```

### Step 2: 1-Click Automated Build & FPGA Flashing
Connect your Nexys 4 board via USB, power it on, and run:
```cmd
.\fpga\build_and_program.bat
```

### Step 3: Manual Step-by-Step Execution
```cmd
# 1. Assemble assembly firmware to machine code hex
python sim/asm.py fpga/hardware_test.s fpga/firmware.hex

# 2. Run non-interactive Vivado bitstream synthesis
vivado -mode batch -source fpga/build_bitstream.tcl

# 3. Flash bitstream onto connected Nexys 4 FPGA board
vivado -mode batch -source fpga/program_fpga.tcl
```

### Step 4: Cross-Branch Navigation
- **Cadence 90nm ASIC Implementation:** Switch to [`cadence`](https://github.com/Ad1thh/Final-Project-EV/tree/cadence)
- **Zynq SoC & Vitis Deployment:** Switch to [`vitis-deployment`](https://github.com/Ad1thh/Final-Project-EV/tree/vitis-deployment)
- **Interactive 3D Web Dashboard:** Switch to [`arpith/corrections`](https://github.com/Ad1thh/Final-Project-EV/tree/arpith/corrections)
- **Research Papers & Theory:** Switch to [`docs`](https://github.com/Ad1thh/Final-Project-EV/tree/docs)
- **Unified Master Integration:** Switch to [`main`](https://github.com/Ad1thh/Final-Project-EV/tree/main)
