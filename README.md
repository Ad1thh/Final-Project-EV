# Fault-Tolerant RV32E Core — Testbench Verification & Interactive 3D Web Dashboard

**Branch:** `arpith/corrections`  
**Focus Areas:** Next.js 15 3D Drone Telemetry Dashboard, RTL/Testbench Stabilization, and Hardware Verification Projects  
**Target Architecture:** Synthesizable RV32E Core with Selective TMR & Hamming SEC-DED ECC  

---

## 1. 📌 Executive Summary & Branch Focus

The **`arpith/corrections`** branch focuses on two critical contributions to the project:

1. **Interactive 3D Web Telemetry & Fault Injection Dashboard (`fpga-demo-dashboard/`):**
   - Built with **Next.js 15 (App Router)**, **TypeScript**, **Tailwind CSS**, and **Three.js / React Three Fiber**.
   - Renders a fully interactive, photorealistic **3D Quadcopter Drone Model** with real-time subsystem explosion view (Avionics Flight Computer, Brushless Propulsion, Sensor Array / IMU, Power Distribution).
   - Real-time telemetry streaming from the RV32E core via **Web Serial API** or automated software simulation data sources.
   - Live hardware status display: Program Counter tracker, 16 physical board LEDs, pipeline register inspect, and fault injection triggers (SEC, DED, ALU TMR, Mode Switch).

2. **RTL & Testbench Corrections:**
   - Cleans up repository bloat by pruning oversized waveform artifacts and test traces from Git tracking.
   - Tunes the comprehensive pipeline stress test (`tests/stress_test.s`) with correct post-branch PC expectations.
   - Hosts standalone Vivado hardware evaluation projects (`project_testing/`, `project_tmr/`).

```
+----------------------------------------------------------------------------------------------------+
|                                    PROJECT SYSTEM TOPOLOGY                                         |
+----------------------------------------------------------------------------------------------------+
|                                                                                                    |
|  +--------------------------------+                  +------------------------------------------+  |
|  |     HARDWARE / SIMULATION      |                  |        NEXT.JS 15 3D WEB DASHBOARD       |  |
|  |                                |                  |                                          |  |
|  |  [3-Stage RV32E Processor Core]|   UART / Serial  |  [Three.js 3D Drone Subsystems]          |  |
|  |  - TMR ALU + Majority Voter    |================> |  - Exploded Subsystem Inspection         |  |
|  |  - Hamming(38,32) SEC-DED ECC  |   115200 Baud    |  - Real-Time Flight Telemetry            |  |
|  |  - DMR Control Unit Lockstep   |                  |                                          |  |
|  |  - MMIO Diagnostic Registers   |                  |  [Live Diagnostics & Fault Injection]   |  |
|  +--------------------------------+                  |  - SEC Single-Bit Correction Counter     |  |
|                                                      |  - DED Double-Bit Trap Flag              |  |
|  +--------------------------------+                  |  - TMR ALU Mismatch Monitor              |  |
|  |       VIVADO TEST PROJECTS     |                  |  - 16 Board LED Mirror Matrix            |  |
|  |  - project_testing.xpr         |                  +------------------------------------------+  |
|  |  - project_tmr.xpr             |                                                                |
|  +--------------------------------+                                                                |
+----------------------------------------------------------------------------------------------------+
```

---

## 2. 🎮 Interactive 3D Web Dashboard (`fpga-demo-dashboard/`)

### Key Features
- **3D Interactive Drone Scene (`src/components/DroneModel.tsx`, `SharedScene.tsx`):**
  - Rotatable, zoomable 3D quadcopter model with animated brushless motors.
  - Subsystem inspection mode: dynamically disassembles drone components with smooth camera transitions to inspect the core flight avionics running the RV32E processor.
- **Hardware Telemetry Streaming (`src/lib/DataProvider.ts`, `UARTDataSource.ts`):**
  - Connects directly to FPGA boards (Nexys 4 / Zybo Z7) over USB-UART using the browser-native **Web Serial API**.
  - Fallback **SimulatedDataSource** generating realistic flight and fault injection telemetry for demonstration without hardware attached.
- **Fault Injection Sandbox (`src/app/page.tsx`, `SignalPipeline.tsx`):**
  - Interactive buttons to simulate Single Event Upsets (SEU):
    - *Inject SEC Error:* Flips 1 bit in register codeword &rarr; Core corrects in real time with green indicator.
    - *Inject DED Error:* Flips 2 bits in register codeword &rarr; Core asserts uncorrectable trap with red alarm.
    - *Inject ALU Fault:* Forces bit mismatch into ALU replica 1 &rarr; TMR voter masks fault, increments mismatch telemetry.
    - *Toggle TMR Mode:* Switches between low-power Simplex and mission-critical TMR modes.

### Launching the Web Dashboard
```bash
# Navigate to the dashboard directory
cd fpga-demo-dashboard

# Install Node.js dependencies
npm install

# Start local Next.js development server
npm run dev
```
Open **[http://localhost:3000](http://localhost:3000)** in Chrome or Edge (Web Serial API requires a Chromium-based browser for live hardware connection).

---

## 3. 🧪 RTL & Testbench Verification Suite

### RTL Microarchitecture Modules (`rtl/`)
| Module | Function & Hardware Protection Mechanism |
| :--- | :--- |
| `riscv_pkg.sv` | Global type definitions, ALU opcodes, and control state enums. |
| `riscv_core_top.sv` | Top-level processor wrapper with diagnostic telemetry and fault injection ports. |
| `if_stage.sv` | Instruction Fetch stage with Program Counter and control hazard flush logic. |
| `id_ex_stage.sv` | Instruction Decode & Execute stage with Triplicated ALUs and DMR Control Unit. |
| `wb_stage.sv` | Writeback stage with load data alignment and forwarding muxing. |
| `regfile.sv` | 16-entry register file protected by **Extended Hamming(38,32) SEC-DED ECC**. |
| `alu.sv` | 32-bit Arithmetic Logic Unit supporting all RV32E base operations. |
| `tmr_voter.sv` | 3-way bitwise majority voter with discrepancy detection and fatal mismatch alert. |
| `control_unit.sv` | Primary instruction decoder and duplicate DMR lockstep checker. |
| `hazard_unit.sv` | RAW data forwarding logic and 1-cycle Load-Use stall insertion. |

### Standalone Vivado Projects
- **`project_testing/project_testing.xpr`**: Verification project isolating the register file with 39-bit ECC injection testbenches (`tb/tb_regfile_unit.sv`).
- **`project_tmr/project_tmr.xpr`**: Verification project isolating the triplicated ALUs and majority voter (`tb/tb_tmr_unit.sv`).

---

## 4. 🛠️ Simulation & Verification Guide

### Cadence Xcelium Simulation
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
  rtl/tmr_voter.sv \
  rtl/riscv_core_top.sv \
  tb/tb_riscv_core_top.sv
```

### Siemens ModelSim / QuestaSim
```tcl
vlib work
vlog -sv rtl/riscv_pkg.sv rtl/*.sv tb/tb_riscv_core_top.sv
vsim -c tb_riscv_core_top -do "run -all; quit"
```

### Verilator
```bash
verilator -Wall --trace --cc rtl/riscv_pkg.sv rtl/*.sv --top-module riscv_core_top --exe tb/tb_riscv_core_top.cpp
make -C obj_dir -f Vriscv_core_top.mk Vriscv_core_top
./obj_dir/Vriscv_core_top
```

---

## 5. 🗺️ Cross-Branch Navigation

- **Golden Baseline RV32E Core:** [`RISC-V-Core`](https://github.com/Ad1thh/Final-Project-EV/tree/RISC-V-Core)
- **Cadence 90nm ASIC Implementation:** [`cadence`](https://github.com/Ad1thh/Final-Project-EV/tree/cadence)
- **Digilent Zybo Zynq-7000 SoC Deployment:** [`vitis-deployment`](https://github.com/Ad1thh/Final-Project-EV/tree/vitis-deployment)
- **Auto-Sync DevOps & Utilization Reports:** [`navaneeth/corrections`](https://github.com/Ad1thh/Final-Project-EV/tree/navaneeth/corrections)
- **Research Literature & Project Documentation:** [`docs`](https://github.com/Ad1thh/Final-Project-EV/tree/docs)
- **Master Unified Integration:** [`main`](https://github.com/Ad1thh/Final-Project-EV/tree/main)
