# Cadence Genus & Innovus ASIC Implementation Guide

This guide details how to pull, execute, simulate, and inspect the Cadence ASIC synthesis and place-and-route (P&R) deliverables for the Fault-Tolerant RV32E Core on a Linux EDA server.

---

## 1. Quick-Start Pull Instructions

```bash
# Navigate to your EDA directory
cd ~/projects/Final-Project-EV

# Fetch latest commits
git fetch origin

# Switch to the dedicated cadence branch
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
│   ├── run_flow.sh               # 1-Click master bash runner (Synthesis + P&R)
│   ├── run_flow.csh              # 1-Click master C-shell runner
│   ├── run_genus_syn.tcl         # Genus synthesis Common UI script
│   ├── run_innovus_pnr.tcl       # Innovus floorplan, placement, CTS & routing script
│   ├── run_pnr.csh               # Standalone Innovus P&R runner
│   ├── view_layout.csh           # Instant GUI layout inspector
│   ├── run_sim_gui.csh           # SimVision RTL simulation GUI runner
│   ├── run_gls_gui.csh           # SimVision Gate-Level Simulation GUI runner
│   └── viewDefinition.tcl        # MMMC multi-corner timing configuration
├── netlist/
│   ├── riscv_core_top_syn.v      # Synthesized gate-level netlist
│   ├── riscv_core_top_syn.sdc    # Synthesized timing constraints
│   ├── riscv_core_top_pr.v       # Post-route physical gate-level netlist
│   ├── riscv_core_top_routed.def # Post-route complete layout DEF file
│   └── riscv_core_top.enc.dat/   # Encrypted Innovus layout design database
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

## 3. Tool Scripts Reference

| Script | Purpose & Usage |
| :--- | :--- |
| `scripts/run_flow.sh` | Full automated flow in Bash: Genus synthesis &rarr; Innovus P&R &rarr; Post-route verification &rarr; DEF export. |
| `scripts/run_flow.csh` | Full automated flow in CSH/TCSH for environments sourcing `/home/install/cshrc`. |
| `scripts/run_pnr.csh` | Runs physical layout only (assumes `netlist/riscv_core_top_syn.v` is already synthesized). |
| `scripts/view_layout.csh` | Restores `netlist/riscv_core_top.enc` in the Innovus GUI to visualize the routed silicon die. |
| `scripts/run_sim_gui.csh` | Compiles RTL with Xcelium and launches SimVision with waveforms pre-loaded. |
| `scripts/run_gls_gui.csh` | Compiles post-route netlist `riscv_core_top_pr.v` with TSMC 90nm Verilog models and launches SimVision for GLS. |

---

## 4. Foundry Library Paths

All scripts target the standard university foundry installation:
- **Foundry Base:** `/home/install/FOUNDRY/digital/90nm`
- **Timing Library (Slow Corner):** `/home/install/FOUNDRY/digital/90nm/dig/lib/slow.lib`
- **Physical LEF:** `/home/install/FOUNDRY/digital/90nm/lef/gsclib090_translated.lef`
- **Capacitance Table:** `/home/install/FOUNDRY/digital/90nm/CapTbl/gpdk090.lef.extended.CapTbl`
