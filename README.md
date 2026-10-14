# Fault-Tolerant RV32E 3-Stage Pipelined RISC-V Processor Core

**Targets:** TSMC/GPDK 90nm Digital ASIC (Cadence Genus & Innovus) & FPGA / Heterogeneous SoC (Digilent Nexys 4 Artix-7 & Digilent Zybo Zynq-7000)  
**HDL Standard:** Synthesizable SystemVerilog-2012  
**Verification & Compliance:** 195/195 RISC-V ACT Compliance Tests Passed & Silicon Proven on Physical FPGA Hardware (`0x80FF` PASS Pattern)  
**ASIC Signoff:** 100 MHz Operating Frequency, 71,664.81 &mu;m&sup2; Post-Route Area, 1.27 mW Total Power, 0 DRC Violations, 0 LVS Open Nets  
**Interactive Telemetry:** Next.js 15 + Three.js 3D Quadcopter Drone Telemetry Dashboard with Web Serial API Hardware Link  
**Branch:** `main` (Master Integration Branch)  

---

## 1. 📌 Executive Summary & Motivation

In safety-critical avionics, space computing, and electric vehicle (ISO 26262 ASIL-D) control systems, transient hardware faults induced by cosmic radiation, thermal fluctuations, and electromagnetic interference cause **Single Event Upsets (SEUs)** and **Multiple Bit Upsets (MBUs)**. Unprotected microprocessors can suffer silent data corruption (SDC), control-flow hijacking, or catastrophic system failure.

This repository implements a **Synthesizable, 3-Stage Pipelined RV32E RISC-V Processor Core** featuring **Multi-Layer Hardware Fault Tolerance**:
1. **Extended Hamming(38,32) SEC-DED ECC** on the 16-entry register file (`x0`-`x15`).
2. **Selective Triple Modular Redundancy (TMR)** on the ALU with low-power operand isolation and bitwise majority voting.
3. **Dual Modular Redundancy (DMR)** on the Control Unit with real-time lockstep comparison and fail-safe state clamping.
4. **Triplicated Program Counter (PC A/B/C)** with 2-of-3 voting prior to instruction fetch.
5. **Hardware-in-the-Loop (HIL) Telemetry Engine** streaming real-time core health, instruction traces, and error counters over USB-UART to an interactive 3D Web Dashboard.

```
+----------------------------------------------------------------------------------------------------+
|                                    RISCV_CORE_TOP ARCHITECTURE                                     |
+----------------------------------------------------------------------------------------------------+
|                                                                                                    |
|  [ STAGE 1: FETCH (if_stage.sv) ]                                                                  |
|   +---------------+ +---------------+ +---------------+                                            |
|   |   PC Reg A    | |   PC Reg B    | |   PC Reg C    |  (TMR Program Counter Replicas)            |
|   +-------+-------+ +-------+-------+ +-------+-------+                                            |
|           +-----------------+-----------------+                                                    |
|                             v                                                                      |
|                    [ TMR Voter (2-of-3) ] ===> imem_addr (32-bit)                                  |
|                                                                                                    |
|  [ STAGE 2: DECODE & EXECUTE (id_ex_stage.sv) ]                                                    |
|   +------------------------------------+    +------------------------------------+                 |
|   |    Primary Control Unit Decoder    |    |   Duplicate DMR Checker Decoder    |                 |
|   +-----------------+------------------+    +-----------------+------------------+                 |
|                     +-----------------+-----------------------+                                    |
|                                       v                                                            |
|                        [ Real-Time XOR Comparator ]                                                |
|                        - Match: Pass decoded control signals to datapath                           |
|                        - Mismatch: Assert dmr_error & CLAMP mem_write=0, reg_write=0               |
|                                                                                                    |
|   +-------------------+  +-------------------+  +-------------------+                              |
|   |    ALU Unit 0     |  |    ALU Unit 1     |  |    ALU Unit 2     |                              |
|   +---------+---------+  +---------+---------+  +---------+---------+                              |
|             +----------------------+----------------------+                                        |
|                                    v                                                               |
|          [ Adaptive Redundancy Controller / Voter (Simplex vs TMR) ] ===> alu_result               |
|                                                                                                    |
|  [ REGISTER FILE WITH SEC-DED ECC (regfile.sv) ]                                                   |
|   - 16 Architectural Registers x 32-bit data + 7 parity bits = 39 bits storage per register        |
|   - Extended Hamming(38,32) SEC-DED Code                                                           |
|   - Single-Bit Error Correction (SEC): Transparent 1-cycle auto-correction                         |
|   - Double-Bit Error Detection (DED): Hardware trap assert (ecc_double_error)                       |
|                                                                                                    |
|  [ STAGE 3: WRITEBACK (wb_stage.sv) ]                                                              |
|   - Load data sign/zero extension (LB, LH, LW, LBU, LHU)                                           |
|   - Writeback multiplexer (ALU result vs Memory load data vs PC+4)                                 |
+----------------------------------------------------------------------------------------------------+
```

---

## 2. 🗺️ Master Repository Branch Navigation Index

This project is organized across specialized branches. Claude and developers should consult the table below to access specific environments and toolflows:

| Branch Name | Primary Scope & Focus | Key Deliverables & Included Artifacts | Checkout Command |
| :--- | :--- | :--- | :--- |
| **`main`** *(This Branch)* | **Master Integration Branch** | Full unified repository integrating RTL, Cadence ASIC, Nexys 4 FPGA, Zybo Zynq SoC, 3D Web Dashboard, and testbenches. | `git checkout main` |
| **[`RISC-V-Core`](https://github.com/Ad1thh/Final-Project-EV/tree/RISC-V-Core)** | **Golden Baseline RV32E Core** | Pure unhardened 3-stage RV32E reference core (no TMR/ECC overhead); verified on Nexys 4 FPGA at 25 MHz; ACT 4.0 suite. | `git checkout RISC-V-Core` |
| **[`cadence`](https://github.com/Ad1thh/Final-Project-EV/tree/cadence)** | **Dedicated Clean Linux ASIC Flow** | Pure ASIC package stripped of FPGA files; TSMC/GPDK 90nm Genus synthesis + Innovus P&R; routed DEF; 0 DRC, 0 LVS; SimVision scripts. | `git checkout cadence --` |
| **[`vitis-deployment`](https://github.com/Ad1thh/Final-Project-EV/tree/vitis-deployment)** | **Digilent Zybo Zynq-7000 SoC** | Heterogeneous SoC co-design (ARM Cortex-A9 PS + RV32E PL); AXI GPIO bridge; bare-metal C firmware; HIL telemetry engine; 1-click build. | `git checkout vitis-deployment` |
| **[`arpith/corrections`](https://github.com/Ad1thh/Final-Project-EV/tree/arpith/corrections)** | **3D Web Dashboard & Test Tuning** | Next.js 15 + Three.js 3D Drone Telemetry Web Dashboard; Web Serial bridge; testbench stabilization; standalone Vivado test projects. | `git checkout arpith/corrections` |
| **[`navaneeth/corrections`](https://github.com/Ad1thh/Final-Project-EV/tree/navaneeth/corrections)** | **DevOps Auto-Sync & PDF Reports** | Continuous background auto-sync scripts (`auto_sync.ps1`); Windows Task Scheduler installer; HTML-to-PDF utilization report generator. | `git checkout navaneeth/corrections` |
| **[`cadence-asic-flow`](https://github.com/Ad1thh/Final-Project-EV/tree/cadence-asic-flow)** | **Cadence Staging & Integration** | Bridge branch that configured 90nm `slow.lib` and anti-pruning redundancy preservation rules before merging into main. | `git checkout cadence-asic-flow` |
| **[`docs`](https://github.com/Ad1thh/Final-Project-EV/tree/docs)** | **Research Papers & Theory** | IEEE/ACM literature on radiation hardening, reconfigurable RISC-V soft cores, project review slide decks, and final handoff manuals. | `git checkout docs` |

---

## 3. 🛡️ Comprehensive Fault-Tolerant Microarchitecture

### Layer 1: Extended Hamming(38,32) SEC-DED ECC Register File (`rtl/regfile.sv`)
- **Storage Architecture:** 16 registers (`x0-x15`), each expanded to **39 bits** (32 data bits + 6 Hamming parity bits + 1 overall parity bit).
- **Single Error Correction (SEC):** When reading, syndrome calculation detects any single-bit flip across data or parity bits and corrects it in combinational logic with zero pipeline stall cycles.
- **Double Error Detection (DED):** When two bit-flips occur simultaneously, the overall parity bit reveals an uncorrectable MBU; the core asserts `ecc_double_error` / `ecc_ded` to halt critical writebacks and alert the supervisory controller.

### Layer 2: Selective Triple Modular Redundancy (TMR) on ALU (`rtl/id_ex_stage.sv`, `tmr_voter.sv`)
- **Triplicated Execution:** Three identical ALU instances (`u_alu_0`, `u_alu_1`, `u_alu_2`) execute arithmetic/logic operations in parallel.
- **2-of-3 Bitwise Majority Voter:** Bit-by-bit voting guarantees that if any single ALU suffers a transient error, the correct result is passed through transparently.
- **Diagnostic Mismatch Flags:** Disagreements assert `tmr_mismatch`; a fatal failure across all 3 ALUs asserts `tmr_fatal_mismatch`.
- **Low-Power Simplex Mode:** To conserve power during non-critical flight phases, operands to redundant ALUs can be isolated via clock gating / operand clamping.

### Layer 3: Dual Modular Redundancy (DMR) Control Unit (`rtl/control_unit.sv`)
- **Lockstep Decoders:** The primary instruction decoder and a duplicate checker decoder independently decode every incoming 32-bit instruction word.
- **Real-Time XOR Comparator:** If any decoded control wire (e.g., `reg_write`, `mem_write`, `alu_op`, `wb_sel`) disagrees, `dmr_error` asserts immediately.
- **Fail-Safe Clamping:** Upon error, `mem_write` and `reg_write` are clamped to zero in hardware, preventing memory corruption or architectural state poisoning.

### Layer 4: Triplicated Program Counter (`rtl/if_stage.sv`)
- **TMR PC Registers:** PC is maintained across three independent registers (`pc_reg_a`, `pc_reg_b`, `pc_reg_c`).
- **Pre-Fetch Voting:** Instruction memory address is driven by a 2-of-3 majority voter output, protecting control flow from single-event upsets.

---

## 4. 📊 Multi-Target Implementation & Silicon Signoff

### Target A: TSMC/GPDK 90nm Digital ASIC (Cadence Genus & Innovus)
- **Target Frequency:** 100 MHz (10.0 ns Clock Period).
- **Setup Timing Slack (WNS):** **`+0.138 ns`** post-route (Zero timing violations).
- **Total Standard Cell Count:** **11,463 instances** (10,611 combinational, 852 sequential).
- **Core Area:** **71,664.81 &mu;m&sup2;** (Register file: 58.9%, Triplicated ALU+Voter: 20.4%, TMR PC+Voter: 8.0%).
- **Total Power Dissipation:** **1.27 mW** at 100 MHz (leakage + internal + dynamic).
- **Physical Verification:** **0 DRC violations** (`innovus_drc.rpt`), **0 Open Nets / Shorts** (`innovus_connectivity.rpt`).

### Target B: Digilent Nexys 4 Artix-7 FPGA (`XC7A100T-1CSG324C`)
- **System Operating Clock:** 25.00 MHz (Derived from 100 MHz oscillator via clock divider).
- **Setup Timing Slack (WNS):** **`+8.042 ns`** (Zero timing violations).
- **Routing Status:** 100% Routed (**0 Unrouted Nets**).
- **Silicon Proof:** Executed `fpga/hardware_test.s` live on physical silicon; **confirmed `0x80FF` PASS pattern with active LED chaser**.

### Target C: Digilent Zybo Zynq-7000 SoC (`XC7Z010-1CLG400C`)
- **Heterogeneous Architecture:** Dual-Core ARM Cortex-A9 (PS) + Fault-Tolerant RV32E Soft-Core (PL).
- **Communications:** AXI GPIO bridge + USB-UART running at 115200 baud.
- **Hardware-in-the-Loop Protocol:** 6-byte command packet parser, 14-byte real-time binary telemetry stream.

---

## 5. 🎮 Interactive Next.js 15 3D Web Telemetry Dashboard

The repository includes a web dashboard in [`fpga-demo-dashboard/`](fpga-demo-dashboard/) and [`drone-dashboard/`](drone-dashboard/):
- **3D Quadcopter Drone Scene:** Photorealistic 3D drone with interactive camera controls, animated rotors, and exploded subsystem inspection (Flight Avionics, Propulsion, Sensors, Power Distribution).
- **Real-Time Web Serial Link:** Connects directly from Google Chrome or Microsoft Edge to the FPGA USB-UART COM port.
- **Live Fault Injection Panel:** Inject single-bit SEC errors, double-bit DED errors, or ALU TMR faults and watch the core correct or trap them in real time.
- **Hardware Status Mirror:** Reflects the 16 physical board LEDs, Program Counter, and cumulative error counters.

To run the dashboard:
```bash
cd fpga-demo-dashboard
npm install
npm run dev
```
Open **[http://localhost:3000](http://localhost:3000)** in Chrome/Edge.

---

## 6. 📁 Complete Repository Directory Tree

```text
Final_Project/
├── rtl/                                  # Synthesizable SystemVerilog RTL
│   ├── riscv_core_top.sv                 # Top-level processor wrapper & telemetry
│   ├── riscv_pkg.sv                      # Opcodes, types, and constants
│   ├── alu.sv                            # 32-bit Arithmetic Logic Unit
│   ├── regfile.sv                        # 16x39-bit SEC-DED ECC Register File
│   ├── if_stage.sv                       # Fetch Stage with Triplicated PC & Voter
│   ├── id_ex_stage.sv                    # Decode/Execute with Triplicated ALU & DMR CU
│   ├── wb_stage.sv                       # Writeback Stage with Load Alignment
│   ├── control_unit.sv                   # Instruction Decoder & DMR Lockstep Checker
│   ├── hazard_unit.sv                    # RAW Forwarding & Load-Use Stall Logic
│   ├── tmr_voter.sv                      # 3-Way Majority Voter
│   └── adaptive_redundancy_controller.sv # Dynamic Simplex/TMR Redundancy Switcher
│
├── cadence/                              # Complete Cadence ASIC Flow Package
│   ├── constraints/                      # SDC timing constraints (100 MHz)
│   ├── scripts/                          # Automated Genus synthesis & Innovus P&R scripts
│   ├── reports/                          # Area, timing, power, DRC, and LVS reports
│   └── netlist/                          # Post-synth and post-route Verilog netlists & DEF
│
├── fpga/                                 # Artix-7 Nexys-4 FPGA Implementation
│   ├── build_and_program.bat             # 1-Click build & program master script
│   ├── build_bitstream.tcl               # Vivado synthesis & implementation script
│   ├── program_fpga.tcl                  # Vivado JTAG programming script
│   ├── fpga_top.sv                       # Nexys 4 top-level wrapper & clock divider
│   └── hardware_test.s                   # Diagnostic assembly test firmware
│
├── zynq_vitis_deployment/                # Digilent Zybo Zynq-7000 SoC Deployment Package
│   ├── 1_build_bitstream.bat             # Vivado block design & XSA export
│   ├── 2_build_vitis_app.bat             # Vitis baremetal C app build
│   ├── 3_program_and_run.bat             # XSDB JTAG programming & execution
│   ├── vitis_app/                        # ARM Cortex-A9 C UART bridge
│   └── run_all.bat                       # 1-Click SoC master runner
│
├── fpga-demo-dashboard/                  # Next.js 15 + Three.js 3D Web Telemetry Dashboard
├── constraints/                          # FPGA Constraint Files (nexys4.xdc, zybo_z7.xdc)
├── tb/                                   # Standalone SystemVerilog Testbench Suite
├── sim/                                  # Simulation scripts and Python assembler (asm.py)
├── scripts/                              # DevOps auto-sync and PDF report generation scripts
├── utilization_comparison_report.html    # Interactive HTML utilization comparison
├── utilization_comparison_report.pdf     # Publication-grade PDF utilization report
├── METHOD.md                             # Architectural methodology document
├── cu_protection_method.md               # Formal DMR control unit derivation
└── memory_protection_method.md           # Extended Hamming(38,32) parity matrix & syndrome math
```

---

## 7. 🚀 Quick-Start Execution Guide

### A. Cadence 90nm ASIC Flow (Linux EDA Server)
```bash
cd cadence
./scripts/run_flow.sh       # Bash
# or
./scripts/run_flow.csh      # CSH / TCSH
```
To view the routed die layout in Innovus GUI:
```csh
cd cadence
./scripts/view_layout.csh
```

### B. Digilent Nexys 4 FPGA 1-Click Build (Windows)
Connect Nexys 4 via USB and run:
```cmd
.\fpga\build_and_program.bat
```

### C. Digilent Zybo Zynq-7000 SoC 1-Click Build (Windows)
Connect Zybo via USB and run:
```cmd
cd zynq_vitis_deployment
run_all.bat
```

### D. HDL Simulation & Testbenches
- **Cadence Xcelium:**
  ```bash
  xrun -sv -64bit -access +rwc rtl/riscv_pkg.sv rtl/*.sv tb/tb_riscv_core_top.sv
  ```
- **Siemens ModelSim / QuestaSim:**
  ```tcl
  vlib work
  vlog -sv rtl/riscv_pkg.sv rtl/*.sv tb/tb_riscv_core_top.sv
  vsim -c tb_riscv_core_top -do "run -all; quit"
  ```
- **Verilator:**
  ```bash
  verilator -Wall --trace --cc rtl/riscv_pkg.sv rtl/*.sv --top-module riscv_core_top --exe tb/tb_riscv_core_top.cpp
  make -C obj_dir -f Vriscv_core_top.mk Vriscv_core_top
  ./obj_dir/Vriscv_core_top
  ```
