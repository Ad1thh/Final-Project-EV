# RV32E Fault-Tolerant Processor Core — Cadence ASIC Implementation

**Target Flow:** Cadence Genus (Synthesis) & Cadence Innovus (Physical P&R)  
**Target Library:** 90nm Digital Standard Cell Library (`/home/install/FOUNDRY/digital/90nm/dig/lib/slow.lib`)  
**Design Level:** ASIC Synthesizable SystemVerilog-2012  
**Clock Target:** 100 MHz (10.0 ns period)  

---

## 1. Overview & Architecture

This repository contains the complete ASIC-synthesizable delivery package for an open-source, high-reliability **RV32E 3-Stage Pipelined RISC-V Processor Core** (`riscv_core_top`).

The core integrates comprehensive multi-layer fault tolerance designed to operate reliably in harsh, radiation-prone environments without functional interruption:

1. **TMR Program Counter (Fetch Stage):**
   - Three independent 32-bit PC register replicas (`pc_reg_a`, `pc_reg_b`, `pc_reg_c`) updated synchronously.
   - 3-input majority voter (`u_pc_voter`) transparently masks single-replica SEUs (Single-Event Upsets).
2. **Dual Modular Redundancy (DMR) Control Unit (Decode Stage):**
   - Parallel duplicate decoder (`u_control_unit_checker`) running concurrently with the primary Control Unit.
   - Real-time XOR comparator with **Fail-Safe Clamping**: destructive write signals (`mem_write`, `reg_write`) are immediately clamped to zero upon any mismatch to prevent architectural corruption.
3. **Adaptive Triple Modular Redundancy (TMR) ALU Cluster (Execute Stage):**
   - Three 32-bit execution units (`u_alu_0`, `u_alu_1`, `u_alu_2`) with 3-input majority voting.
   - Dynamic mode switching: **Simplex Mode** (lowest power, operands isolated and clamped to zero) vs. **TMR Mode** (all three ALUs active with 2-of-3 majority voting).
4. **Extended Hamming(38,32) SEC-DED ECC Register File:**
   - 16 x 32-bit RV32E register file with 6 parity bits and 1 overall parity bit (39 bits storage per register).
   - Single-bit error correction (SEC) and double-bit error detection (DED) with hardware trap generation.
5. **Hardware Hazard Handling:**
   - Full WB-to-ID/EX data forwarding, 1-cycle Load-Use stall insertion, and branch/jump redirection.

---

## 2. Directory Structure

```text
Final-Project-EV/
├── rtl/                          # 12 Synthesizable SystemVerilog Core Files
│   ├── riscv_core_top.sv         # Top-level ASIC module
│   ├── riscv_pkg.sv              # Opcodes, funct3/7, and control enums
│   ├── alu.sv                    # 32-bit RV32E Arithmetic Logic Unit
│   ├── regfile.sv                # 16x39-bit SEC-DED ECC Register File
│   ├── if_stage.sv               # Stage 1: TMR PC & Fetch
│   ├── id_ex_stage.sv            # Stage 2: DMR Decoder & Triplicated ALUs
│   ├── wb_stage.sv               # Stage 3: Load alignment & Writeback mux
│   ├── control_unit.sv           # Latch-free instruction decoder
│   ├── hazard_unit.sv            # Forwarding, load-use stall & flush
│   ├── tmr_voter.sv              # 3-input bitwise majority voter
│   ├── clock_gater.sv            # Glitch-free clock gating cell
│   ├── adaptive_redundancy_controller.sv # Operand isolation & TMR voter
│   ├── HANDOFF_INTERFACE_DOC.md  # Core port and signal specification
│   └── walkthrough.md            # Microarchitecture pipeline walkthrough
│
├── cadence/                      # Cadence ASIC Flow Package
│   ├── constraints/
│   │   └── riscv_core_top.sdc    # 100 MHz timing constraints
│   ├── scripts/
│   │   ├── run_genus_syn.tcl     # Automated Genus synthesis script
│   │   ├── run_innovus_pnr.tcl   # Innovus place & route startup script
│   │   └── run_flow.sh           # 1-command Linux synthesis runner
│   ├── reports/                  # Generated timing, area, power reports
│   ├── netlist/                  # Synthesized gate-level netlist & SDC
│   └── README_CADENCE_FLOW.md    # Detailed Cadence tool documentation
│
├── tb/                           # Pure SystemVerilog testbenches (for Cadence Xcelium)
├── cu_protection_method.md       # Engineering note on Control Unit DMR
├── memory_protection_method.md   # Engineering note on ECC SEC-DED
└── .gitignore                    # Ignores Cadence run logs (*.log, *.cmd, fv/)
```

---

## 3. Quick-Start Guide (Linux Terminal)

### Step 1: Clone or Pull the Branch
```bash
cd /home/student/EV2327_Projects/Final-Project-EV

# Switch to the dedicated clean branch:
git checkout cadence
git pull origin cadence
```

### Step 2: Ensure Cadence Genus is Loaded
If your lab uses environment modules:
```bash
module load cadence/genus
# OR source your lab's tool profile:
# source /tools/cadence/cshrc_genus
```
Confirm Genus is ready:
```bash
genus -version
```

### Step 3: Run Automated Synthesis
From the repository root:
```bash
cd cadence

# Make script executable (first time only)
chmod +x scripts/run_flow.sh

# Run synthesis
./scripts/run_flow.sh
```

Or run interactively inside Genus:
```bash
cd cadence
genus -f scripts/run_genus_syn.tcl
```

---

## 4. Synthesis Output Deliverables

After Genus completes, inspect the generated deliverables:

| File Location | Description |
| :--- | :--- |
| `cadence/reports/timing_report.rpt` | Static Timing Analysis (slack, critical paths, 100 MHz signoff) |
| `cadence/reports/area_report.rpt` | Standard cell gate count, instance hierarchy, and area ($\mu m^2$) |
| `cadence/reports/power_report.rpt` | Leakage, internal, and dynamic switching power dissipation |
| `cadence/reports/qor_summary.rpt` | Executive Quality-of-Results summary |
| `cadence/netlist/riscv_core_top_syn.v` | Mapped gate-level Verilog netlist (handoff to Cadence Innovus) |
| `cadence/netlist/riscv_core_top_syn.sdc` | Synthesized SDC constraints for physical implementation |

---

## 5. Critical Genus Preservation Constraints

Because this core uses **structural redundancy** for fault tolerance, default synthesis optimization will attempt to prune duplicate hardware. The script [`cadence/scripts/run_genus_syn.tcl`](cadence/scripts/run_genus_syn.tcl) automatically enforces these mandatory preservation rules:

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

# 4. Restrict datapath sharing on ECC XOR trees to avoid timing violations
set_db /designs/riscv_core_top .dp_max_sharing 0
```

---

## 6. Physical Implementation (Cadence Innovus P&R)

Once the gate-level netlist is produced:
```bash
cd cadence
innovus -f scripts/run_innovus_pnr.tcl
```
Proceed with floorplanning, power grid creation, standard cell placement, clock tree synthesis (`ccopt_design`), routing (`routeDesign`), and DRC/LVS signoff.
