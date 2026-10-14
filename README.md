# RV32E Fault-Tolerant Core — Complete Zynq-7000 SoC & Vitis Deployment Package

**Target Hardware:** Digilent Zybo / Zybo Z7 Development Board (AMD/Xilinx Zynq-7000 `XC7Z010-1CLG400C`)  
**Architecture:** Heterogeneous Hardware-Software SoC Co-Design (ARM Cortex-A9 PS + Fault-Tolerant RV32E Soft-Core PL)  
**Host Interface:** High-Throughput Bidirectional USB-UART Bridge (`MIO48/49` @ 115200 baud) connecting to 3D Web Dashboard  
**Branch:** `vitis-deployment`  

---

## 1. 📌 Executive Summary & Architecture Overview

The **`vitis-deployment`** branch provides the complete, production-ready **Zynq-7000 SoC and Vitis Embedded Deployment Package**.

Instead of treating the RV32E core as an isolated FPGA soft processor, this branch embeds the **Fault-Tolerant RV32E Processor Core** into the Programmable Logic (PL) of the Zynq-7000 SoC, coupled with the ARM Cortex-A9 dual-core Processing System (PS) via an **AXI4-Lite AXI GPIO interconnect**.

```
+----------------------------------------------------------------------------------------------------+
|                                    DIGILENT ZYBO ZYNQ-7000 SOC                                     |
+----------------------------------------------------------------------------------------------------+
|                                                                                                    |
|  +---------------------------+                +-------------------------------------------------+  |
|  |   PROCESSING SYSTEM (PS)  |                |             PROGRAMMABLE LOGIC (PL)             |  |
|  |                           |                |                                                 |  |
|  |  [USB-UART FT2232]        |                |  +-------------------------------------------+  |  |
|  |   (MIO48/49 @ 115200)     |                |  |       32-bit RV32E RISC-V CPU Core        |  |  |
|  |           |               |   AXI4-Lite    |  |  - DMR Fail-Safe Control Unit             |  |  |
|  |  [ARM Cortex-A9 Core 0]  |<=============> |  |  - Triplicated ALUs & 2-of-3 Voter        |  |  |
|  |   (zynq_uart_bridge.elf)  |   (AXI GPIO)   |  |  - Triplicated Program Counters (PC A/B/C)|  |  |
|  |                           |                |  |  - Extended Hamming(38,32) SEC-DED ECC    |  |  |
|  +---------------------------+                |  +-------------------------------------------+  |  |
|                                               |                        |                        |  |
|  [Physical Zybo Controls]                     |  +-------------------------------------------+  |  |
|  - BTN0: System Master Reset                  |  |         HIL Controller Engine             |  |  |
|  - BTN1: Inject SEC Single-Bit Register Flip  |  |  - 6-Byte Command Packet RX Parser        |  |  |
|  - BTN2: Inject DED Double-Bit Parity Error   |  |  - 14-Byte Binary Telemetry Stream TX     |  |  |
|  - BTN3: Inject ALU TMR Mismatch Error        |  |  - Glitch-Free Button Edge Debouncers     |  |  |
|  - SW0 : Simplex (Low Power) / TMR Mode Switch|  +-------------------------------------------+  |  |
|                                               |                        |                        |  |
|                                               |  [LED3..0]: Real-Time Core Status Display       |  |
|                                               +-------------------------------------------------+  |
+----------------------------------------------------------------------------------------------------+
```

---

## 2. 🔌 Heterogeneous PS-PL Communications & Telemetry Protocol

### A. High-Throughput UART Bridge (`vitis_app/main.c`)
- Runs bare-metal on **ARM Cortex-A9 Core 0**.
- Intercepts serial bytes arriving from the host PC / 3D Dashboard over USB-UART (`MIO48`/`MIO49`).
- Maps packets across the AXI bus into the PL **Hardware-in-the-Loop (HIL) Controller**.
- Transmits raw binary telemetry packets back to the host at a continuous streaming rate.

### B. 6-Byte Host Command Packet Format (Host &rarr; Zybo)
| Byte Offset | Field | Description |
| :---: | :--- | :--- |
| `0` | **Header Byte** | Synchronizing marker: `0xAA` |
| `1` | **Command Opcode** | `0x01`: Reset, `0x02`: Mode Toggle, `0x03`: Inject Fault, `0x04`: Query |
| `2-3`| **Target Operand / Address** | Register address `x0-x15` or BRAM offset |
| `4` | **Bit-Flip Mask** | Bit index `0-38` for register injection or ALU instance selector |
| `5` | **Checksum** | Byte-wise XOR validation checksum |

### C. 14-Byte Telemetry Stream Packet Format (Zybo &rarr; Host)
| Byte Offset | Field | Description |
| :---: | :--- | :--- |
| `0` | **Sync Header** | Header marker: `0x55` |
| `1` | **System Status** | Bits `[0]`: Simplex/TMR, `[1]`: DMR Error, `[2]`: Fatal TMR, `[3]`: Core Halted |
| `2-5`| **Program Counter (PC)** | 32-bit current execution PC |
| `6-9`| **Instruction Word** | 32-bit current instruction opcode/data |
| `10`| **SEC Error Counter** | Cumulative count of single-bit errors corrected by ECC |
| `11`| **DED Error Counter** | Cumulative count of double-bit uncorrectable traps |
| `12`| **TMR Mismatch Counter**| Cumulative count of ALU voting discrepancies masked |
| `13`| **Checksum** | Byte-wise XOR packet checksum |

---

## 3. 📁 Repository Directory Structure

```text
Final-Project-EV/
├── zynq_vitis_deployment/                # Complete Zynq SoC Package
│   ├── 1_build_bitstream.bat             # Step 1: Vivado batch synthesis & XSA export (Windows)
│   ├── 2_build_vitis_app.bat             # Step 2: Vitis / XSCT baremetal C compilation (Windows)
│   ├── 3_program_and_run.bat             # Step 3: XSDB 1-click JTAG programming (Windows)
│   ├── run_all.bat                       # Master 1-Click execution script (Windows)
│   ├── run_all.sh                        # Master 1-Click execution script (Linux)
│   ├── README.md                         # Detailed sub-package deployment manual
│   │
│   ├── rtl/                              # Synthesizable SystemVerilog RV32E Core
│   │   ├── riscv_core_top.sv             # Top-level RISC-V CPU core
│   │   ├── control_unit.sv               # DMR Fail-Safe protected decoder
│   │   ├── alu.sv                        # Triplicated ALU unit
│   │   ├── tmr_voter.sv                  # 3-way majority voter
│   │   ├── regfile.sv                    # Extended Hamming(38,32) SEC-DED ECC regfile
│   │   ├── id_ex_stage.sv                # Decode/Execute pipeline stage
│   │   ├── if_stage.sv                   # Instruction Fetch stage with TMR PC
│   │   ├── wb_stage.sv                   # Writeback stage
│   │   └── hazard_unit.sv                # Hazard detection & forwarding
│   │
│   ├── fpga/                             # FPGA SoC Top & Peripheral Modules
│   │   ├── fpga_top.sv                   # Top-level SoC wrapper with PS AXI bridge
│   │   ├── hil_controller.sv             # Hardware-in-the-Loop UART telemetry engine
│   │   └── uart_rx.sv                    # Auxiliary UART receiver
│   │
│   ├── constraints/
│   │   └── zybo_z7.xdc                   # Digilent Zybo pin mappings (Clock, BTN0-3, SW0, LEDs)
│   │
│   ├── firmware/                         # RISC-V Baremetal Diagnostic Assembly
│   │   ├── hardware_test.s               # Self-checking assembly diagnostic suite
│   │   ├── firmware.hex                  # Assembled 32-bit machine code
│   │   └── asm.py                        # Standalone Python assembler
│   │
│   ├── vitis_app/                        # ARM Cortex-A9 Baremetal Firmware
│   │   └── main.c                        # High-throughput UART <-> AXI GPIO bridge
│   │
│   └── scripts/                          # Automated Toolchain Scripts
│       ├── build_soc_bitstream.tcl       # Vivado TCL for PS Block Design & Bitstream
│       ├── vitis_build_app.py            # Modern Vitis Python build script
│       ├── vitis_build_app_xsct.tcl      # Classic Vitis / XSCT build script
│       └── program_and_run_xsdb.tcl      # XSDB JTAG flash & execution script
│
├── drone-dashboard/                      # Next.js 15 + Three.js 3D Drone Telemetry Web Dashboard
├── fpga-demo-dashboard/                  # Alternative Next.js Web Dashboard
├── vitis_src/                            # Supplementary Vitis workspace sources
├── zynq_vitis_deployment.zip             # Standalone distributable archive
└── README.md                             # This document
```

---

## 4. 🚀 1-Click Build & Deployment Guide

### Prerequisites
- **AMD Vivado 2020.2 or later** installed on your system.
- **AMD Vitis Embedded Development Tools** (`vitis`, `xsct`, or `xsdb`) on your system `PATH`.
- Digilent Zybo or Zybo Z7 board connected via USB `PROG/UART`.

### Windows Execution
```cmd
cd zynq_vitis_deployment
run_all.bat
```
This automatically:
1. Runs Vivado non-interactive batch mode to generate the Zynq Processing System block design, synthesize the RV32E PL core, and generate `zynq_soc_wrapper.xsa`.
2. Invokes Vitis CLI to build `zynq_uart_bridge.elf` for ARM Cortex-A9.
3. Initializes the target over JTAG using XSDB, downloads the FPGA bitstream, and executes the ARM ELF.

### Linux Execution
```bash
cd zynq_vitis_deployment
chmod +x run_all.sh
./run_all.sh
```

---

## 5. 🎮 Connecting the 3D Drone Telemetry Web Dashboard

Once the SoC is programmed and running on the Zybo:
1. Navigate to the dashboard directory:
   ```bash
   cd drone-dashboard
   npm install
   npm run dev
   ```
2. Open `http://localhost:3000` in Google Chrome or Microsoft Edge.
3. Click **"Connect Hardware"** in the top navigation bar.
4. Select the Silicon Labs / FTDI USB-to-UART COM port corresponding to your Zybo board.
5. Watch the real-time 3D drone telemetry stream live data directly from the RV32E CPU running inside the Zybo FPGA!

---

## 6. 🗺️ Cross-Branch Navigation

- **Cadence 90nm ASIC Implementation:** Switch to [`cadence`](https://github.com/Ad1thh/Final-Project-EV/tree/cadence)
- **Golden Baseline RV32E Core (Nexys 4):** Switch to [`RISC-V-Core`](https://github.com/Ad1thh/Final-Project-EV/tree/RISC-V-Core)
- **Interactive 3D Web Dashboard:** Switch to [`arpith/corrections`](https://github.com/Ad1thh/Final-Project-EV/tree/arpith/corrections)
- **Auto-Sync DevOps & Utilization Reports:** Switch to [`navaneeth/corrections`](https://github.com/Ad1thh/Final-Project-EV/tree/navaneeth/corrections)
- **Research Literature & Theory:** Switch to [`docs`](https://github.com/Ad1thh/Final-Project-EV/tree/docs)
- **Unified Master Integration:** Switch to [`main`](https://github.com/Ad1thh/Final-Project-EV/tree/main)
