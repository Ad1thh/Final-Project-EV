# Selective Fault-Tolerant RISC-V Processor with Error-Correcting Register File & Adaptive Redundancy Control
**Technical Progress & Hardware Validation Report**  
**Date:** 29th July 2026  
**Document Purpose:** Comprehensive technical status report for team members covering overall system architecture, baseline pipeline optimization, bug fixes, automated Vivado FPGA toolchain integration, and live baseline silicon validation results.

---

## 1. 📌 System Architecture & Baseline Specifications

The baseline core implements a synthesizable, high-reliability **RV32E 3-Stage Pipelined RISC-V Processor Core** deployed on the Xilinx Nexys 4 (Artix-7 XC7A100T-1CSG324C) FPGA board and targeted for Cadence Genus ASIC synthesis. This baseline deployment serves as the **perfected foundation** upon which SEC-DED ECC and Adaptive Redundancy (TMR) control will be integrated.

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

### Core Architecture Highlights (Baseline Foundation)
1. **Pipelined Microarchitecture (`rtl/`)**:
   - **Fetch Stage (`if_stage.sv`)**: Program counter generation, instruction fetch, and control hazard flushes.
   - **Decode & Execute Stage (`id_ex_stage.sv`)**: RV32E opcode decoding, 16-register operand read (`x0-x15`), 32-bit ALU, immediate generation, and branch evaluation.
   - **Writeback Stage (`wb_stage.sv`)**: Load alignment (`LB`, `LBU`, `LH`, `LHU`, `LW`), writeback selection MUX, and forwarding to ID/EX stage.
   - **Hazard & Forwarding Unit (`hazard_unit.sv`)**: Real-time RAW data forwarding and branch/jump pipeline flushes.
2. **Unified Block RAM & MMIO Architecture**:
   - 32 KB Unified Block RAM (`0x0000_0000` to `0x0000_7FFF`) initialized via `$readmemh`.
   - Memory-Mapped I/O (`0x8000_0000`) driving 16 physical board LEDs for real-time diagnostic reporting.

---

## 2. 🚦 Comprehensive Project Status & Phase Matrix

| Phase | Feature / Component | Status | Verification Summary |
| :--- | :--- | :---: | :--- |
| **Phase 1** | Base 3-Stage RV32E Core Pipeline | **100% Complete** | Baseline SystemVerilog RTL (`rtl/*.sv`) fully optimized and verified. |
| **Phase 2** | Custom RTL Simulation & Stress Fuzzing | **100% Complete** | 100% pass rate on automated Icarus Verilog & Verilator simulation suites. |
| **Phase 3** | Architectural Compliance (ACT 4.0) | **100% Complete** | **195/195 RV32I architectural compliance tests passed**. |
| **Phase 4** | **Baseline FPGA Synthesis & Hardware Silicon Validation** | **100% Complete** | **Baseline Vivado bitstream generated & verified live on Nexys 4 FPGA silicon (`0x80FF` PASS pattern confirmed)**. |
| **Phase 5** | **ECC Register File & Adaptive Fault-Tolerance (TMR / SEC-DED)** | **In Progress** | **Pending SEC-DED Hamming Encoder/Decoder & TMR Adaptive Redundancy integration on top of baseline core.** |
| **Phase 6** | **Cadence ASIC Synthesis, Power, Area & Timing Evaluation** | **Final Phase (Pending)** | **ASIC synthesis scripts, SDC timing constraints, and Cadence Genus power/area evaluation targeted after Phase 5.** |

> **Current Project Milestone**: **Phase 4 Baseline FPGA Foundation 100% Complete & Live on Silicon; Phase 5 Fault-Tolerance & Phase 6 Cadence ASIC Evaluation Next**

---

## 3. 🛠️ Major Bug Fixes & Technical Resolutions

### 1. Store Instruction RV32E Out-of-Bounds Trap Bug (`id_ex_stage.sv`)
- **Issue:** Store instructions (`SB`, `SH`, `SW`) set `ctrl_alu_src_b = 1` for immediate calculation, causing the trap unit to ignore bit 24 (`rs2` index). As a result, illegal accesses to invalid registers (`x16-x31`) during stores bypassed trap detection.
- **Fix:** Added `uses_rs2` signal (`(opcode == R_TYPE) || (opcode == BRANCH) || (opcode == STORE)`), ensuring trap enforcement on illegal `rs2 >= 16` store instructions.

### 2. Store Halfword (`SH`) Bitmask Overflow (`id_ex_stage.sv`)
- **Issue:** Halfword store mask shifted `4'b0011 << alu_result[1:0]`, which overflowed to `4'b1000` at byte offset 3.
- **Fix:** Updated `FUNCT3_SH` mask generation to `(alu_result[1]) ? 4'b1100 : 4'b0011` and shifted `dmem_wdata` by 16 bits when `alu_result[1] == 1`.

### 3. Assembler Directive Handling (`sim/asm.py`)
- **Issue:** Assembly directive lines (e.g. `.text`, `.globl`) caused `ValueError: Unsupported instruction .text`.
- **Fix:** Updated directive parser in `sim/asm.py` to skip lines starting with `.`.

### 4. Automatic Reset Generator & Active-High Pin Binding (`fpga_top.sv`)
- **Issue:** Nexys 4 Center Push Button `BTNC` (Pin `E16`) is **active-high** (`0` unpressed, `1` pressed). The previous code checked `if (!CPU_RESETN)`, trapping the processor in permanent reset (`rst_n = 0`) at boot.
- **Fix:** Implemented an **Automatic Power-On Reset Generator (256-cycle delay)** in `fpga_top.sv`. The CPU automatically releases reset 10 microseconds after flashing, while pressing `BTNC` (`E16`) triggers a manual hardware reset.

### 5. MMIO Base Pointer Overwrite in Firmware (`fpga/hardware_test.s`)
- **Issue:** Register `x5` stores the MMIO LED pointer (`0x8000_0000`). In Stage 3, byte/halfword loads targeted `x5` (`lbu x5`, `lhu x5`), overwriting `x5` with memory data. Subsequent status writes in Stage 4 and Stage 5 targeted RAM address `0x0468` instead of MMIO address `0x8000_0000`, causing board LEDs to freeze at `0x0003`.
- **Fix:** Replaced `x5` load targets in Stage 3 of `hardware_test.s` with scratch register `x7` (`lbu x7`, `lhu x7`), preserving `x5 = 0x8000_0000` across all test stages.

---

## 4. 📊 Baseline FPGA Synthesis & Bitstream Metrics

Non-interactive synthesis, placement, routing, and bitstream generation executed via AMD/Xilinx Vivado 2025.2.1 for the baseline core:

- **Target Device:** Xilinx Artix-7 `xc7a100tcsg324-1` (Digilent Nexys 4)
- **Target Frequency:** 25.00 MHz (`CLK100MHZ` divided by 4)
- **Timing Closure:** **PASSED** (Worst Negative Slack **`WNS = +8.042 ns`**, **0 timing violations**)
- **Routing Status:** 100% Routed (**0 Unrouted Nets**, **0 Failed Nets**)
- **Bitstream File:** `fpga/fpga_top.bit` (3.82 MB)
- **JTAG Startup Status:** `INFO: [Labtools 27-3164] End of startup status: HIGH`

---

## 5. 💡 Hardware Test Protocol & Live LED Diagnostic Legend

The board executes `fpga/hardware_test.s` upon configuration:

```
[BOOT] 0xAAAA -> 0x5555  -->  [STAGE 1] ALU  -->  [STAGE 2] SHIFT  -->  [STAGE 3] BRAM  -->  [STAGE 4] BRANCH  -->  [STAGE 5] 100% PASS (0x80FF + Chaser)
```

| Test Stage | Diagnostic Scope | Hardware LED Pattern (`LED[15:0]`) | Live Verification Status |
| :--- | :--- | :--- | :---: |
| **Boot Display** | Visual power-on test | `0xAAAA` → `0x5555` alternating flash | **CONFIRMED** |
| **Stage 1** | ALU Ops (ADD, SUB, AND, OR, XOR, SLT) | `LED[0]` ON (`0x0001`) | **CONFIRMED** |
| **Stage 2** | Shifts & Immediates (SLLI, SRLI, SRAI, LUI) | `LED[1]` ON (`0x0002`) | **CONFIRMED** |
| **Stage 3** | BRAM Load/Store Alignment (SW, LW, SB, LBU, SH, LHU) | `LED[0]` & `LED[1]` ON (`0x0003`) | **CONFIRMED** |
| **Stage 4** | Control Flow Hazards (BEQ, BLT, JAL, JALR) | `LED[2]` ON (`0x0004`) | **CONFIRMED** |
| **Stage 5** | **100% Hardware Validation** | **`LED[15]` ON + `LED[7:0]` Dynamic Chaser (`0x80FF`)** | **CONFIRMED LIVE ON SILICON** |

---

## 6. 🎯 Upcoming Action Items (Phases 5 & 6)

### Phase 5: ECC Register File & Adaptive Fault Tolerance (TMR / SEC-DED)
1. **ECC Register File SEC-DED Integration (`rtl/regfile.sv`)**:
   - Implement Single Error Correction, Double Error Detection (Hamming SEC-DED parity matrix) on `x1-x15` register writes/reads.
2. **Selective Adaptive Redundancy (TMR) Logic**:
   - Integrate configurable Triple Modular Redundancy (TMR) voter blocks on critical control paths.

### Phase 6: Final Cadence ASIC Evaluation
1. **Cadence Genus ASIC Synthesis & Constraints**:
   - Configure SDC constraints and execute Cadence Genus synthesis on standard cell libraries.
2. **Power, Area & Timing Benchmarking**:
   - Benchmark power, gate count, and silicon area overhead of the selective fault-tolerant core vs baseline non-redundant execution using Cadence Genus and Cadence Xcelium.
