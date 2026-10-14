# Cadence Genus & Innovus ASIC Implementation Guide

This guide details the standard Cadence ASIC synthesis and place-and-route (P&R) implementation for the Fault-Tolerant RV32E Core using standard EDA tool commands.

---

## 1. Quick-Start Pull Instructions

```bash
# Navigate to your project directory
cd ~/projects/Final-Project-EV

# Fetch latest commits and switch to cadence branch
git fetch origin
git checkout cadence
git pull origin cadence
```

---

## 2. Directory Layout

```text
cadence/
├── constraints/
│   └── riscv_core_top.sdc        # 100 MHz timing constraints (10.0 ns period)
├── scripts/
│   ├── syn.tcl                   # Cadence Genus synthesis script (Common UI)
│   ├── pnr.tcl                   # Cadence Innovus floorplanning, placement, CTS & routing script
│   └── viewDefinition.tcl        # MMMC multi-corner timing configuration
├── netlist/
│   ├── riscv_core_top_syn.v      # Synthesized gate-level netlist
│   ├── riscv_core_top_syn.sdc    # Synthesized timing constraints
│   ├── riscv_core_top_pr.v       # Post-route physical gate-level netlist
│   ├── riscv_core_top_routed.def # Post-route complete layout DEF file
│   ├── riscv_core_top.gds        # Streamed GDSII Silicon Mask Layout (14.1 MB)
│   └── riscv_core_top.enc.dat/   # Innovus layout design database
└── reports/
    ├── qor_summary.rpt           # Quality-of-Results summary
    ├── area_report.rpt           # Genus area report (68,019.58 um^2)
    ├── timing_report.rpt         # Genus timing slack report (WNS = 0.0 ps)
    ├── power_report.rpt          # Genus power breakdown
    ├── innovus_area.rpt          # Innovus standard cell area (71,664.81 um^2)
    ├── innovus_power.rpt         # Innovus power report (1.27 mW)
    ├── innovus_drc.rpt           # Innovus DRC verification (0 violations)
    ├── innovus_connectivity.rpt  # Innovus LVS/connectivity verification (0 opens)
    └── innovus_timing/           # PostRoute timing slack reports
```

---

## 3. How to Run Synthesis & Physical Design

### Step 3.1: Environment Setup
```csh
# Switch to C-Shell and source the lab profile
csh
source /home/install/cshrc
```

### Step 3.2: Logic Synthesis (Cadence Genus)
From the `cadence/` directory:
```csh
genus -f scripts/syn.tcl
```
*(Or inside the interactive Genus prompt: `genus` &rarr; `source scripts/syn.tcl`)*

### Step 3.3: Physical Place & Route (Cadence Innovus)
Once the synthesized netlist is generated in `netlist/`:
```csh
innovus -f scripts/pnr.tcl
```
*(Or inside the interactive Innovus GUI: `innovus` &rarr; `source scripts/pnr.tcl`)*

---

## 4. Foundry Library Configuration (GPDK090)

The scripts target the university 90nm digital standard cell library:
- **Timing Library (Slow Corner):** `/home/install/FOUNDRY/digital/90nm/dig/lib/slow.lib`
- **Physical LEF:** `/home/install/FOUNDRY/digital/90nm/dig/lef/gsclib090_translated.lef`
- **Capacitance Table:** `/home/install/FOUNDRY/digital/90nm/dig/captable/gpdk090.lef.extended.CapTbl`
