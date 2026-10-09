# Cadence Genus & Innovus ASIC Implementation Guide

This guide describes how to pull the repository and run the Cadence ASIC synthesis and place-and-route (P&R) flow on a Linux server/workstation.

---

## 1. Where to Pull the Code on Your Linux System

You can pull the repository to any directory on your Linux system where you have write permissions and fast I/O access. 

**Recommended locations:**
- User project workspace:
  ```bash
  cd ~
  mkdir -p ~/projects
  cd ~/projects
  ```
  or EDA working directory:
  ```bash
  cd /home/$USER/cadence_ws/
  ```
*(Avoid NFS shares with high latency or read-only mounted filesystems).*

---

## 2. How to Pull the Code in Linux

### Option A: If you are cloning the repo freshly on Linux
```bash
# Clone directly onto the cadence-asic-flow branch:
git clone -b cadence-asic-flow https://github.com/Ad1thh/Final-Project-EV.git

cd Final-Project-EV
```

### Option B: If the repo is already cloned on your Linux machine
```bash
cd /path/to/Final-Project-EV

# Fetch latest branches from origin
git fetch origin

# Switch to the new cadence-asic-flow branch
git checkout cadence-asic-flow

# Ensure you have the latest commits
git pull origin cadence-asic-flow
```

---

## 3. Directory Layout for Cadence Flow

```text
Final-Project-EV/
├── rtl/                          <-- Synthesizable SystemVerilog source files
│   ├── riscv_core_top.sv         <-- Top-level module
│   ├── alu.sv
│   ├── regfile.sv
│   ├── if_stage.sv
│   ├── id_ex_stage.sv
│   ├── wb_stage.sv
│   ├── control_unit.sv
│   ├── hazard_unit.sv
│   ├── tmr_voter.sv
│   ├── clock_gater.sv
│   ├── adaptive_redundancy_controller.sv
│   └── riscv_pkg.sv
└── cadence/                      <-- Cadence ASIC Flow Package
    ├── constraints/
    │   └── riscv_core_top.sdc    <-- 100 MHz timing constraints
    ├── scripts/
    │   ├── run_genus_syn.tcl     <-- Cadence Genus automated synthesis
    │   ├── run_innovus_pnr.tcl   <-- Cadence Innovus P&R startup script
    │   └── run_flow.sh           <-- 1-command Linux bash runner
    ├── reports/                  <-- Generated area, timing, power reports
    └── netlist/                  <-- Generated gate-level netlist & synthesized SDC
```

---

## 4. How to Run Cadence Genus Synthesis

### Step 4.1: Load Cadence Environment & License
Ensure Cadence Genus is in your `$PATH`. Typical environment setups in universities/labs:
```bash
# Environment module system:
module load cadence/genus
# OR source your lab's cshrc / bashrc profile:
source /tools/cadence/cshrc_genus
```

Verify that `genus` is ready:
```bash
genus -version
```

### Step 4.2: Target PDK Library Configuration
The synthesis script is configured with your 90nm foundry standard cell library by default:
- **Default Path:** `/home/install/FOUNDRY/digital/90nm/dig/lib`
- **Default Library:** `slow.lib` (worst-case setup corner for robust timing signoff)

If you wish to switch to typical or fast corners, you can optionally override via environment variables:
```bash
# Optional override for typical corner:
export PDK_TARGET_LIB="typical.lib"

# Optional override for fast corner:
export PDK_TARGET_LIB="fast.lib"
```

### Step 4.3: Execute Synthesis
From the `cadence/` directory:

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

## 5. What Genus Produces

After synthesis completes, inspect the outputs:
- **Quality of Results (QoR) Reports (`cadence/reports/`):**
  - `timing_report.rpt`: Setup & hold slack (target: 10.0 ns / 100 MHz).
  - `area_report.rpt`: Exact standard cell count, logic area (µm²), and wirelength estimate.
  - `power_report.rpt`: Dynamic, leakage, and total power dissipation.
  - `qor_summary.rpt`: Executive summary of design performance.
- **Handoff Netlists (`cadence/netlist/`):**
  - `riscv_core_top_syn.v`: Mapped gate-level Verilog netlist.
  - `riscv_core_top_syn.sdc`: Optimized post-synthesis SDC timing constraints.

---

## 6. Physical Design in Cadence Innovus (P&R)

Once `riscv_core_top_syn.v` is generated:
```bash
cd cadence
innovus
```
Then inside the Innovus prompt:
```tcl
source scripts/run_innovus_pnr.tcl
```
Proceed with floorplanning, power planning (`VDD`/`VSS`), placement, clock tree synthesis (`ccopt_design`), and routing (`routeDesign`).
