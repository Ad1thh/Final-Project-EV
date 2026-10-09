# Complete Zynq-7000 Hardware-Software SoC Deployment Package
### Target Board: Digilent Zybo / Zybo Z7 (XC7Z010-1CLG400C)
### Core Architecture: Fault-Tolerant RV32E RISC-V + Zynq PS ARM Cortex-A9

---

## 1. Overview & Architecture
This package contains all design files, SystemVerilog RTL, constraints, firmware, C drivers, and automated Vivado/Vitis build scripts to deploy the complete SoC flow on any machine with **AMD Vivado & Vitis Embedded Development** installed.

```
+-----------------------------------------------------------------------------------------+
|                                    DIGILENT ZYBO BOARD                                  |
|                                                                                         |
|  +---------------------------+                +---------------------------------------+ |
|  |   PROCESSING SYSTEM (PS)  |                |        PROGRAMMABLE LOGIC (PL)        | |
|  |                           |                |                                       | |
|  |  [USB-UART FT2232]        |                |  +---------------------------------+  | |
|  |   (MIO48/49 @ 115200)     |                |  |    32-bit RV32E RISC-V Core     |  | |
|  |           |               |   AXI4-Lite    |  |  - DMR Fail-Safe Control Unit   |  | |
|  |  [ARM Cortex-A9 Core 0]  |<=============> |  |  - TMR ALU & TMR PC             |  | |
|  |   (zynq_uart_bridge.elf)  |   (AXI GPIO)   |  |  - SEC-DED ECC Register File    |  | |
|  |                           |                |  +---------------------------------+  | |
|  +---------------------------+                |                 |                     | |
|                                               |  +---------------------------------+  | |
|  [Physical Controls]                          |  |      HIL Controller Engine      |  | |
|  - BTN0: Reset                                |  |  - 6-Byte Packet RX Parser      |  | |
|  - BTN1: SEC Register Fault Inject          |  |  - 14-Byte Telemetry Stream TX  |  | |
|  - BTN2: DED Parity Fault Inject            |  |  - Physical Button Edge Debounce |  | |
|  - BTN3: ALU TMR Fault Inject               |  +---------------------------------+  | |
|  - SW0 : Simplex / TMR Mode Switch           |                 |                     | |
|                                               |  [LED3..0]: MMIO Status Display       | |
|                                               +---------------------------------------+ |
+-----------------------------------------------------------------------------------------+
```

---

## 2. Directory Structure

```
zynq_vitis_deployment/
├── 1_build_bitstream.bat          # Step 1: Vivado batch synthesis & XSA export (Windows)
├── 2_build_vitis_app.bat          # Step 2: Vitis / XSCT baremetal C compilation (Windows)
├── 3_program_and_run.bat          # Step 3: XSDB 1-click JTAG programming (Windows)
├── run_all.bat                    # Master 1-Click execution script (Windows)
├── run_all.sh                     # Master 1-Click execution script (Linux)
├── README.md                      # Comprehensive deployment guide
│
├── rtl/                           # Fault-Tolerant RISC-V Core RTL (SystemVerilog)
│   ├── riscv_core_top.sv          # Top-level RISC-V CPU core
│   ├── control_unit.sv            # DMR Fail-Safe protected decode tree
│   ├── alu.sv                     # Triplicated ALU unit
│   ├── tmr_voter.sv               # Majority voting logic
│   ├── regfile.sv                 # (38,32) SEC-DED Hamming ECC register file
│   ├── id_ex_stage.sv             # Instruction Decode / Pipeline stage
│   ├── if_stage.sv                # Instruction Fetch stage with TMR PC
│   ├── wb_stage.sv                # Writeback stage
│   ├── hazard_unit.sv             # Hazard detection & forwarding
│   ├── adaptive_redundancy_controller.sv # Simplex/TMR dynamic switcher
│   └── riscv_pkg.sv               # Core package definitions
│
├── fpga/                          # FPGA SoC Top & Peripheral Modules
│   ├── fpga_top.sv                # Top-level SoC wrapper with PS AXI bridge
│   ├── hil_controller.sv          # Hardware-in-the-Loop UART telemetry engine
│   └── uart_rx.sv                 # Auxiliary UART receiver
│
├── constraints/                   # Target Board Pin Constraints
│   └── zybo_z7.xdc                # Digilent Zybo pin mappings (Clock, BTN0-3, SW0, LEDs)
│
├── firmware/                      # RISC-V Baremetal Diagnostic Assembly
│   ├── hardware_test.s            # Test program (ALU stress, ECC writes, branches)
│   ├── firmware.hex               # Assembled 32-bit machine code
│   └── asm.py                     # Standalone Python assembler
│
├── vitis_app/                     # ARM Cortex-A9 Baremetal Firmware
│   └── main.c                     # High-throughput UART <-> AXI GPIO bridge
│
└── scripts/                       # Automated Toolchain Scripts
    ├── build_soc_bitstream.tcl    # Vivado TCL for PS Block Design & Bitstream
    ├── vitis_build_app.py         # Modern Vitis Python build script
    ├── vitis_build_app_xsct.tcl   # Classic Vitis / XSCT build script
    └── program_and_run_xsdb.tcl   # XSDB JTAG flash & execution script
```

---

## 3. Quick Start (1-Click Deployment)

### On Windows:
1. Connect the Digilent Zybo board to your PC via the USB `PROG/UART` micro-USB port.
2. Ensure the board power switch `SW4` is turned **ON** and the power jumper is set to **USB**.
3. Double-click **`run_all.bat`** (or run `1_build_bitstream.bat` -> `2_build_vitis_app.bat` -> `3_program_and_run.bat`).

### On Linux:
```bash
chmod +x run_all.sh
./run_all.sh
```

---

## 4. Manual / GUI Steps (Optional)

### A. Vivado GUI:
1. Open Vivado and run:
   ```tcl
   source scripts/build_soc_bitstream.tcl
   ```
2. The script will automatically generate the Block Design (`system.bd`), wrap it, synthesize, place, route, and write `output/fpga_top.bit` and `output/system_wrapper.xsa`.

### B. Vitis Embedded GUI:
1. Launch Vitis and select workspace `vitis_ws`.
2. Click **Create Platform Component** -> Select `output/system_wrapper.xsa` -> Processor: `ps7_cortexa9_0` -> OS: `standalone`.
3. Click **Create Application Component** -> Name: `zynq_uart_bridge` -> Target Platform: `zybo_platform`.
4. Import `vitis_app/main.c` into `src/`.
5. Build the application (`zynq_uart_bridge.elf`).
6. Run as **Launch Hardware (Single Application Debug)**.

---

## 5. Bidirectional UART Protocol & Drone Dashboard Verification

### Baud Rate: `115200`, 8 Data Bits, 1 Stop Bit, No Parity

#### A. PC -> FPGA (Command Injection - 6 Bytes):
```
[ 0xAA | CMD_TYPE | REG_NUM | BIT_POS | ALU_ID | 0x55 ]
  - 0x01: Single Error Correction (SEC) injection
  - 0x02: Double Error Detection (DED) injection
  - 0x03: ALU TMR Fault injection
  - 0x04: Simplex / TMR Mode Toggle
  - 0x05: CPU Core Reset
```

#### B. FPGA -> PC (Telemetry Response - 14 Bytes):
```
[ 0xAA | EVENT_TYPE | REG | BIT | ALU | G3 | G2 | G1 | G0 | B3 | B2 | B1 | B0 | 0x55 ]
  - EVENT_TYPE: 0x01 (SEC Corrected), 0x02 (DED Trapped), 0x03 (TMR Recovered)
  - G[3:0]: Expected Corrected Value (Big-Endian 32-bit)
  - B[3:0]: Raw Faulty Value (Big-Endian 32-bit)
```

#### C. Physical Board Verification:
- **BTN1**: Injects SEC fault into register file (LED indicators flash, packet sent to dashboard).
- **BTN2**: Injects DED fault into register file (CPU traps safely without architectural corruption).
- **BTN3**: Injects ALU fault into ALU Instance 0 (TMR majority voter masks fault instantly).
- **SW0**: Toggles between Single Core Simplex mode and Triple Modular Redundancy (TMR) mode.
