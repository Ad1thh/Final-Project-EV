# RV32E 3-Stage Pipelined RISC-V Processor Core
**FPGA Target:** Xilinx Nexys 4 (Artix-7 XC7A100T-1CSG324C)  
**HDL Standard:** SystemVerilog-2012  
**Synthesis & Toolchain:** AMD/Xilinx Vivado (Non-Interactive Batch Mode) / Cadence Genus ASIC  

---

## 1. Overview & System Architecture

This project implements a synthesizable, 3-stage pipelined **RV32E RISC-V Processor Core** deployed on the Xilinx Nexys 4 FPGA board. The core features hardware hazard detection, forwarding, load/store alignment, and memory-mapped I/O (MMIO) to drive the board's 16 LEDs.

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
| **Phase 2** | Custom RTL Simulation & Stress Fuzzing | **100% Complete** | Automated Icarus Verilog & Verilator regression suites passing 100%. |
| **Phase 3** | Architectural Compliance (ACT 4.0) | **100% Complete** | **195/195 RV32I architectural compliance tests passed**. |
| **Phase 4** | **Baseline FPGA Synthesis & Silicon Validation** | **100% Complete** | **Baseline Vivado bitstream generated & verified live on Nexys 4 FPGA silicon (`0x80FF` PASS pattern confirmed).** |
| **Phase 5** | **ECC Register File & Adaptive Fault-Tolerance (TMR / SEC-DED)** | **In Progress** | **Pending SEC-DED Hamming Encoder/Decoder & TMR Adaptive Redundancy integration on top of baseline core.** |
| **Phase 6** | **Cadence ASIC Synthesis, Power, Area & Timing Evaluation** | **Final Phase (Pending)** | **ASIC synthesis scripts, SDC timing constraints, and Cadence Genus power/area evaluation targeted after Phase 5.** |

---

## 3. Microarchitecture & How It Works

### Pipeline Stages
1. **Stage 1: Fetch (IF):**
   - Manages Program Counter (`pc_reg`) generation.
   - Reads 32-bit instructions from Block RAM (`imem_addr`).
   - Supports 1-cycle pipeline flushes on taken branches/jumps.
2. **Stage 2: Decode & Execute (ID/EX):**
   - Decodes RV32E opcodes and extracts 16-entry register operands (`x0-x15`).
   - Evaluates branch conditions (`BEQ`, `BNE`, `BLT`, `BGE`, `BLTU`, `BGEU`) and computes jump targets (`JAL`, `JALR`).
   - Contains 32-bit ALU (`alu.sv`), Immediate Generator, and Hazard Forwarding Unit (`hazard_unit.sv`).
   - Formats Data Memory write data (`dmem_wdata`) and write masks (`dmem_wmask`) for byte (`SB`), halfword (`SH`), and word (`SW`) stores.
3. **Stage 3: Writeback (WB):**
   - Aligns and sign/zero-extends memory load data (`LB`, `LBU`, `LH`, `LHU`, `LW`).
   - Selects Writeback result (`ALU`, `Memory`, or `PC+4`).
   - Forwards writeback data to Decode stage in real time.

---

## 4. FPGA System Interfaces & Memory Map

### Clocking & Reset System
- **Input Clock:** 100 MHz board oscillator (`CLK100MHZ`).
- **Internal Clock:** Divided down to **25 MHz** using a 2-bit counter and driven through a global clock buffer (`BUFG`).
- **Reset:** Active-low pushbutton `CPU_RESETN` (`E16`) fed into a 2-stage asynchronous reset synchronizer with an Automatic Power-On Reset Generator (256 cycles).

### Address Space Memory Map
| Address Range | Size | Component | Access Type |
| :--- | :--- | :--- | :--- |
| `0x0000_0000` - `0x0000_7FFF` | 32 KB | Unified Block RAM (Instructions & Data) | Read / Write |
| `0x8000_0000` - `0x8000_0004` | 4 Bytes | MMIO LED Register (`LED[15:0]`) | Read / Write |

---

## 5. Complete FPGA Pin & Port Mapping Table

All ports map to physical pins on the **Xilinx Nexys 4 (Artix-7 XC7A100T-1CSG324C)** board configured for `LVCMOS33` (3.3V I/O standard) in `constraints/nexys4.xdc`.

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

## 6. Self-Diagnostic Protocol & LED Status Legend

The core executes `fpga/hardware_test.s` upon boot:

1. **Boot Flash:** Alternates `0xAAAA` → `0x5555` on all 16 LEDs.
2. **Stage 1 (ALU Test):** Executes ADD, SUB, AND, OR, XOR, SLT. `LED[3:0] = 0x1`.
3. **Stage 2 (Shift Test):** Executes SLLI, SRLI, SRAI, LUI. `LED[3:0] = 0x2`.
4. **Stage 3 (Memory Test):** Executes word/halfword/byte loads & stores (`SW`, `SH`, `SB`, `LW`, `LH`, `LB`, `LHU`, `LBU`) at RAM address `0x400`. `LED[3:0] = 0x3`.
5. **Stage 4 (Branch/Jump Test):** Executes `BEQ`, `BLT`, `JAL`, `JALR`. `LED[3:0] = 0x4`.
6. **PASS Result:** `LED[15] = 1` ON + lower 8 LEDs run dynamic visual chaser (`0x80FF`).
7. **FAIL Alert:** `LED[15:12] = 0xF` ON + `LED[3:0]` shows exact failing stage ID (`0xF001` - `0xF004`).

---

## 7. How to Build & Load Bitstream

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
