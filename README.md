# RV32E Fault-Tolerant Core — Continuous Sync DevOps & ASIC Utilization Signoff

**Branch:** `navaneeth/corrections`  
**Focus Areas:** Automated Branch Synchronization Daemon, ASIC/FPGA Utilization Reporting Suite, and Cadence 90nm P&R Signoff Deliverables  
**Target Architecture:** Synthesizable RV32E Core with Selective TMR & Hamming SEC-DED ECC  

---

## 1. 📌 Executive Summary & Branch Purpose

The **`navaneeth/corrections`** branch serves as the DevOps automation and analytical reporting hub of the project:

1. **Continuous Branch Synchronization Infrastructure:**
   - Features automated bidirectional synchronization scripts and daemons (`scripts/auto_sync.ps1`) to ensure developer workspaces stay continuously in sync with `main` without manual merge overhead.
   - Includes Windows Task Scheduler installers (`scripts/install_auto_sync_task.bat`, `scripts/uninstall_auto_sync_task.bat`) and GitHub Actions automation (`.github/workflows/auto_sync.yml`).
2. **ASIC & FPGA Utilization Comparison Reporting Engine:**
   - Complete analytical report generator (`scripts/generate_pdf_report.py`) compiling synthesis and place-and-route metrics across the baseline core (`RISC-V-Core`) and fault-tolerant core (`cadence`).
   - Generates publication-ready HTML (`utilization_comparison_report.html`) and PDF (`utilization_comparison_report.pdf`) comparison documents.
3. **Full Cadence 90nm ASIC Delivery Package:**
   - Merged the complete Cadence Genus synthesis and Innovus place-and-route deliverables from `cadence`, including post-route gate-level netlists (`riscv_core_top_pr.v`), routed DEF (`riscv_core_top_routed.def`), and Innovus database (`riscv_core_top.enc.dat`).

```
+----------------------------------------------------------------------------------------------------+
|                                  NAVANEETH/CORRECTIONS ARCHITECTURE                                |
+----------------------------------------------------------------------------------------------------+
|                                                                                                    |
|  +---------------------------+       +----------------------------+       +---------------------+  |
|  |   BRANCH SYNC DEVOPS      |       |  UTILIZATION REPORT SUITE  |       |  CADENCE 90nm ASIC  |  |
|  |                           |       |                            |       |                     |  |
|  | - scripts/auto_sync.ps1   |       | - generate_pdf_report.py   |       | - Genus Synthesis   |  |
|  | - install_auto_sync_task  | ====> | - utilization_report.html  | ====> | - Innovus Layout    |  |
|  | - .github/auto_sync.yml   |       | - utilization_report.pdf   |       | - 100 MHz Signoff   |  |
|  | - .vscode/settings.json   |       |   (Area, Timing, Power)    |       | - 0 DRC, 0 LVS Opens|  |
|  +---------------------------+       +----------------------------+       +---------------------+  |
|                                                                                                    |
+----------------------------------------------------------------------------------------------------+
```

---

## 2. 📁 Repository File Tree

```text
Final-Project-EV/
├── .github/
│   └── workflows/
│       └── auto_sync.yml                 # GitHub Actions workflow for automated branch sync
├── .vscode/
│   └── settings.json                     # VS Code auto-fetch and git editor integration
│
├── scripts/                              # DevOps & Reporting Scripts
│   ├── auto_sync.ps1                     # Robust PowerShell background synchronization script
│   ├── install_auto_sync_task.bat        # Registers Windows Task Scheduler background sync job
│   ├── uninstall_auto_sync_task.bat      # Unregisters Windows Task Scheduler background job
│   └── generate_pdf_report.py            # Python report compiler (HTML to PDF)
│
├── utilization_comparison_report.html    # Interactive HTML resource & utilization comparison
├── utilization_comparison_report.pdf     # Publication-grade PDF utilization report
│
├── cadence/                              # Complete Cadence ASIC Flow Package
│   ├── constraints/
│   │   └── riscv_core_top.sdc            # 100 MHz timing constraints
│   ├── scripts/
│   │   ├── run_flow.sh                   # 1-Click master bash runner
│   │   ├── run_flow.csh                  # 1-Click master C-shell runner
│   │   ├── run_genus_syn.tcl             # Genus synthesis script
│   │   ├── run_innovus_pnr.tcl           # Innovus Place & Route script
│   │   ├── run_pnr.csh                   # Standalone Innovus P&R runner
│   │   ├── view_layout.csh               # Instant GUI layout inspector
│   │   └── viewDefinition.tcl            # MMMC timing view setup
│   ├── netlist/                          # Generated Netlists & Physical Design Databases
│   │   ├── riscv_core_top_syn.v          # Synthesized netlist
│   │   ├── riscv_core_top_syn.sdc        # Synthesized SDC
│   │   ├── riscv_core_top_pr.v           # Post-route physical netlist
│   │   ├── riscv_core_top_routed.def     # Post-route routed DEF
│   │   └── riscv_core_top.enc.dat/       # Innovus design database
│   ├── reports/                          # Signoff Reports (Area, Timing, Power, DRC, LVS)
│   └── README_CADENCE_FLOW.md            # Cadence tool manual
│
├── rtl/                                  # Synthesizable SystemVerilog RTL
└── tb/                                   # Standalone SystemVerilog Testbenches
```

---

## 3. 🔄 Continuous Synchronization Guide

### A. How `auto_sync.ps1` Works
The synchronization script performs intelligent safe syncing:
1. Checks working tree status with `git status --porcelain`.
2. Fetches upstream changes from `origin`.
3. If clean, merges upstream tracking commits via fast-forward.
4. If local uncommitted work exists, automatically creates a safe stash or commit checkpoint before updating.
5. Pushes validated commits to remote if permitted.

### B. Installing the Background Sync Daemon (Windows)
Run from an elevated or standard Windows Command Prompt / PowerShell:
```cmd
.\scripts\install_auto_sync_task.bat
```
This registers a Windows Task Scheduler task that runs silently in the background, keeping your branch in sync with the team.

### C. Uninstalling the Background Sync Daemon
```cmd
.\scripts\uninstall_auto_sync_task.bat
```

---

## 4. 📊 Utilization Comparison Reporting Engine

The script [`scripts/generate_pdf_report.py`](scripts/generate_pdf_report.py) parses synthesis results and formats comparative metrics across the baseline core and the fault-tolerant core:

### Summary Utilization Metrics (90nm ASIC @ 100 MHz)
| Metric | Baseline RV32E | Fault-Tolerant RV32E | Overhead | Protection Provided |
| :--- | :---: | :---: | :---: | :--- |
| **Clock Frequency** | 100 MHz | 100 MHz | 0.0% | Zero frequency degradation |
| **Setup Timing Slack (WNS)** | +0.420 ns | **+0.138 ns** | -0.282 ns | Passes with positive margin |
| **Total Standard Cells** | ~6,410 | **11,463** | +78.8% | Full structural redundancy |
| **Total Core Area** | ~38,900 &mu;m&sup2; | **71,664.81 &mu;m&sup2;** | +84.2% | SEC-DED, TMR ALU, TMR PC, DMR CU |
| **Power Dissipation** | 0.72 mW | **1.27 mW** | +76.4% | Mitigated by operand isolation |
| **DRC Violations** | 0 | **0** | 0 | Clean physical layout signoff |
| **LVS Open Nets** | 0 | **0** | 0 | Clean connectivity verification |

To regenerate the PDF report:
```bash
python scripts/generate_pdf_report.py
```

---

## 5. 🚀 Cadence Flow & Layout Inspection

To inspect the post-route ASIC layout directly from this branch on an EDA workstation:
```csh
cd cadence
./scripts/view_layout.csh
```
This launches Cadence Innovus, restores `cadence/netlist/riscv_core_top.enc`, and opens the 90nm routed die layout.

---

## 6. 🗺️ Cross-Branch Navigation

- **Dedicated Clean ASIC Package:** Switch to [`cadence`](https://github.com/Ad1thh/Final-Project-EV/tree/cadence)
- **Golden Baseline RV32E Core (Nexys 4):** Switch to [`RISC-V-Core`](https://github.com/Ad1thh/Final-Project-EV/tree/RISC-V-Core)
- **Zynq SoC & Vitis Deployment:** Switch to [`vitis-deployment`](https://github.com/Ad1thh/Final-Project-EV/tree/vitis-deployment)
- **Interactive 3D Web Dashboard:** Switch to [`arpith/corrections`](https://github.com/Ad1thh/Final-Project-EV/tree/arpith/corrections)
- **Research Literature & Project Theory:** Switch to [`docs`](https://github.com/Ad1thh/Final-Project-EV/tree/docs)
- **Unified Master Integration:** Switch to [`main`](https://github.com/Ad1thh/Final-Project-EV/tree/main)
