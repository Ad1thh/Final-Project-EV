# RV32E Fault-Tolerant Processor Core — Cadence ASIC Implementation

**Target EDA Suite:** Cadence Genus (Synthesis) & Cadence Innovus (Physical P&R)  
**Target Process:** 90nm Digital Standard Cell Library (`/home/install/FOUNDRY/digital/90nm/dig/lib/slow.lib`)  
**Design Specification:** Synthesizable SystemVerilog-2012  
**Target Frequency:** 100 MHz (10.0 ns Clock Period)  
**Target Architecture:** RV32E (16 Registers, Integer Base Instruction Set, Zero DSP Primitives)  

---

## 1. Overview & Fault-Tolerant Architecture

This repository branch (`cadence`) contains the clean, uncluttered ASIC delivery package for the **RV32E 3-Stage Pipelined Fault-Tolerant RISC-V Processor Core** (`riscv_core_top`). All FPGA-specific IP, Zynq SoC software wrappers, and external web dashboards have been stripped out, leaving a pure digital ASIC implementation ready for synthesis and place-and-route in a Linux EDA environment.

The processor integrates four independent layers of hardware fault tolerance designed for mission-critical, radiation-prone aerospace and edge applications:

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
|                    [ TMR Voter (2-of-3) ] ===> instr_addr (32-bit)                                 |
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

## 2. Directory Structure & File Map

Every file in this branch is strictly relevant to RTL design, simulation verification, Cadence synthesis/P&R, or architectural context:

```text
Final-Project-EV/
├── rtl/                                  # Pure Synthesizable SystemVerilog RTL (ASIC Ready)
│   ├── riscv_core_top.sv                 # Top-level ASIC module integrating all stages & interfaces
│   ├── riscv_pkg.sv                      # Opcodes, funct3/7 definitions, ALU operations, and state enums
│   ├── alu.sv                            # 32-bit RV32E Arithmetic Logic Unit (zero DSP primitives)
│   ├── regfile.sv                        # 16x39-bit SEC-DED ECC protected register file
│   ├── if_stage.sv                       # Fetch Stage: Triplicated PC registers + majority voter
│   ├── id_ex_stage.sv                    # Decode & Execute: DMR Control Unit + Triplicated ALUs
│   ├── wb_stage.sv                       # Writeback Stage: Load alignment & result multiplexing
│   ├── control_unit.sv                   # Latch-free single-cycle instruction decoder
│   ├── hazard_unit.sv                    # Data forwarding, load-use interlock stall, and branch flush
│   ├── tmr_voter.sv                      # Parameterized 3-input bitwise majority voter
│   ├── clock_gater.sv                    # Glitch-free clock gating cell for low-power Simplex mode
│   ├── adaptive_redundancy_controller.sv # Dynamic mode switch (Simplex vs TMR) & operand isolation
│   ├── uart_tx.sv                        # Compact diagnostic UART transmitter
│   ├── HANDOFF_INTERFACE_DOC.md          # Architectural interface reference (pinout & protocol)
│   └── walkthrough.md                    # Detailed microarchitectural pipeline walkthrough
│
├── cadence/                              # Cadence ASIC Flow Package
│   ├── constraints/
│   │   └── riscv_core_top.sdc            # 100 MHz timing constraints, clock uncertainty, false paths
│   ├── scripts/
│   │   ├── run_genus_syn.tcl             # Automated Common UI Genus synthesis script
│   │   ├── run_innovus_pnr.tcl           # Innovus Place & Route startup script
│   │   └── run_flow.sh                   # 1-command executable Linux bash runner
│   ├── reports/                          # Generated timing, area, power, and QoR reports
│   ├── netlist/                          # Output gate-level netlist (Verilog) & synthesized SDC
│   └── README_CADENCE_FLOW.md            # Cadence tool command and parameter reference
│
├── tb/                                   # Standalone SystemVerilog Testbenches (Cadence Xcelium)
│   ├── tb_riscv_core_top.sv              # Top-level comprehensive core testbench
│   ├── tb_fault_tolerance.sv             # End-to-end fault injection and masking verification
│   ├── tb_tmr_adversarial.sv             # Negative & positive controls for ALU & PC voting
│   ├── tb_sec_ded_adversarial.sv         # Single-bit correction and double-bit trap tests
│   ├── tb_adaptive_redundancy_control.sv # Simplex vs TMR dynamic transition verification
│   ├── tb_regfile_unit.sv                # ECC register file unit testbench
│   ├── tb_tmr_unit.sv                    # Majority voter unit testbench
│   ├── tb_reset_probe.sv                 # Asynchronous and synchronous reset behavior
│   ├── tb_compliance_run.sv              # RV32E base instruction compliance verification
│   ├── tb_core_stress_adversarial.sv     # Pipeline hazard & multi-fault stress testbench
│   └── tb_uart_tx.sv                     # UART diagnostic output testbench
│
├── cu_protection_method.md               # Context: Formal derivation of DMR Control Unit protection
├── memory_protection_method.md           # Context: Extended Hamming(38,32) parity matrix & syndrome equations
├── README.md                             # This document
└── .gitignore                            # Filters Cadence logs (*.log, *.cmd, fv/), temporary files
```

---

## 3. Quick-Start Guide (Linux EDA Workstation)

### Step 1: Pull the Branch on Your Linux Machine
```bash
# Navigate to your project directory
cd /home/student/EV2327_Projects/Final-Project-EV

# Fetch all remote branches
git fetch origin

# Switch to the dedicated cadence branch
git checkout cadence

# Ensure your local branch is updated to the latest commit
git pull origin cadence
```

### Step 2: Cadence Environment Setup & Troubleshooting
If running `genus` yields `bash: genus: command not found`, configure your lab shell environment:

```bash
# Method A: Using Environment Modules (Standard in university labs)
module avail
module load cadence/genus
module load cadence/innovus

# Method B: Source Lab Setup Script (if provided by sysadmin)
# source /home/install/cadence_profile.sh
# source /home/install/cshrc_genus

# Method C: Manually locate the Cadence binary
find /home/install -name genus -type f 2>/dev/null

# Once located (e.g., /home/install/GENUS/bin/genus), add it to your PATH:
export PATH=/home/install/GENUS/bin:$PATH
```

Verify that the tool executes correctly:
```bash
genus -version
```

---

## 4. Running Cadence Genus Synthesis

### Option 1: One-Command Automated Execution (Recommended)
From the repository root:
```bash
cd cadence
chmod +x scripts/run_flow.sh
./scripts/run_flow.sh
```

### Option 2: Running Genus in Batch Mode
```bash
cd cadence
genus -f scripts/run_genus_syn.tcl -log reports/genus_syn.log
```

### Option 3: Running Genus in Interactive GUI Mode
```bash
cd cadence
genus -gui
```
Inside the Genus Common UI console prompt:
```tcl
source scripts/run_genus_syn.tcl
```

---

## 5. Synthesis Deliverables & Quality-of-Results (QoR) Verification

Once synthesis completes, all deliverables and analytical reports are automatically stored in `cadence/`:

| Output File | Content & Signoff Verification Criteria |
| :--- | :--- |
| `cadence/reports/timing_report.rpt` | **Static Timing Analysis (STA):** Verify **Worst Negative Slack (WNS) &ge; 0.00 ns** at 100 MHz (10.0 ns period). No setup or hold violations. |
| `cadence/reports/area_report.rpt` | **Area Breakdown:** Standard cell instance counts, logic area ($\mu m^2$), and hierarchical module breakdown. |
| `cadence/reports/power_report.rpt` | **Power Dissipation:** Leakage, internal, and dynamic switching power in mW. |
| `cadence/reports/qor_summary.rpt` | **Quality of Results Summary:** Top-level clock frequency, critical endpoint, total cell count, and run runtime. |
| `cadence/netlist/riscv_core_top_syn.v` | **Gate-Level Netlist:** Synthesized structural Verilog netlist mapped to 90nm standard cells for Innovus P&R. |
| `cadence/netlist/riscv_core_top_syn.sdc` | **Synthesized SDC:** Preserved and mapped timing constraints for physical layout. |

---

## 6. Critical Redundancy Preservation Rules (Anti-Pruning)

Because this core uses **hardware structural redundancy** (TMR and DMR) for fault tolerance, default synthesis optimization algorithms assume identical parallel logic cones are redundant and prune them to minimize area.

To prevent Genus from merging or optimizing away the redundant hardware, the following protection mechanisms are implemented:

1. **RTL Attributes:**
   - [`rtl/if_stage.sv`](rtl/if_stage.sv): `(* dont_touch = "true", preserve = "true" *)` on PC registers (`pc_reg_a`, `pc_reg_b`, `pc_reg_c`).
   - [`rtl/id_ex_stage.sv`](rtl/id_ex_stage.sv): `(* dont_touch = "true", preserve = "true" *)` on triplicated ALUs (`u_alu_0`, `u_alu_1`, `u_alu_2`) and DMR decoder (`u_control_unit_checker`).

2. **Synthesis TCL Constraints ([`cadence/scripts/run_genus_syn.tcl`](cadence/scripts/run_genus_syn.tcl)):**
   ```tcl
   # 1. Prevent Genus from merging the 3 TMR PC register replicas
   set_db [get_db registers -if {.name =~ *pc_reg_*}] .preserve true

   # 2. Prevent Genus from merging the DMR Control Unit checker
   set_db [get_db instances */u_control_unit] .preserve true
   set_db [get_db instances */u_control_unit_checker] .preserve true

   # 3. Prevent Genus from merging the triplicated ALUs
   set_db [get_db instances */u_alu_0] .preserve true
   set_db [get_db instances */u_alu_1] .preserve true
   set_db [get_db instances */u_alu_2] .preserve true

   # 4. Disable datapath sharing on ECC XOR trees to avoid timing degradation
   set_db /designs/riscv_core_top .dp_max_sharing 0
   ```

---

## 7. Physical Implementation (Cadence Innovus P&R)

Once `riscv_core_top_syn.v` is generated by Genus, proceed to physical layout:

```bash
cd cadence
innovus -f scripts/run_innovus_pnr.tcl
```

Inside the Innovus environment:
1. **Floorplanning:** Set core utilization (e.g., 0.70) and aspect ratio (1.0).
2. **Power Planning:** Create `VDD` and `VSS` power rings, power stripes, and follow-pins.
3. **Standard Cell Placement:** Run `place_opt_design` to place standard cells with timing-driven optimization.
4. **Clock Tree Synthesis (CTS):** Run `ccopt_design` to build low-skew clock distribution trees for the 100 MHz clock.
5. **Detailed Routing:** Run `routeDesign` with NanoRoute to complete signal routing without DRC violations.
6. **Signoff:** Perform RC extraction (`extractRC`), final static timing verification, and export GDSII / OASIS.

---

## 8. Summary Command Cheatsheet

| Task | Shell Command |
| :--- | :--- |
| **Check Current Branch** | `git branch --show-current` |
| **Update Branch** | `git pull origin cadence` |
| **Run Synthesis** | `cd cadence && ./scripts/run_flow.sh` |
| **Inspect Timing Slack** | `grep -E "Slack|Endpoint" cadence/reports/timing_report.rpt` |
| **Inspect Total Area** | `grep -E "Total Area|Cell Count" cadence/reports/area_report.rpt` |
| **Launch Innovus P&R** | `cd cadence && innovus -f scripts/run_innovus_pnr.tcl` |
