# Cadence Genus & Innovus ASIC Implementation Guide

This guide details the complete, verified Cadence ASIC implementation flow for the **Fault-Tolerant RV32E Core** (`riscv_core_top`) on a Linux EDA server using **Cadence Genus 21.14**, **Cadence Innovus 21.15**, and **Cadence Xcelium 21.09**.

All metrics, netlists, and physical deliverables in this repository reflect ground-truth tool outputs generated from automated script execution.

---

## 1. Environment & Setup

The ASIC implementation flow targets the **90nm GPDK / GSCLIB090 standard cell library**:
- **Timing Libraries:**
  - Setup Analysis: `/home/install/FOUNDRY/digital/90nm/dig/lib/slow.lib` (0.9V, 125°C)
  - Hold Analysis: `/home/install/FOUNDRY/digital/90nm/dig/lib/fast.lib` (1.1V, 0°C)
- **Physical LEF:** `/home/install/FOUNDRY/digital/90nm/lef/gsclib090_translated.lef`
- **Capacitance Table:** `/home/install/FOUNDRY/digital/90nm/CapTbl/gpdk090.lef.extended.CapTbl`
- **GDS Stream Mapping:** `/home/install/FOUNDRY/digital/90nm/gds2_soce.map`
- **Cell GDS Directory:** `/home/install/FOUNDRY/digital/90nm/dig/gds`

To initialize tool paths and environment variables, source the EDA environment:
```csh
source /home/install/cshrc
```

---

## 2. Directory Structure

```text
cadence/
├── constraints/
│   └── riscv_core_top.sdc        # Master SDC timing constraints (100 MHz, 10.0 ns period)
├── scripts/
│   ├── run_flow.csh              # Master C-shell runner (Synthesis -> P&R -> Verification)
│   ├── run_flow.sh               # Master Bash runner
│   ├── run_genus_syn.tcl         # Genus synthesis Common UI script with redundancy preservation
│   ├── run_innovus_pnr.tcl       # Innovus physical design script (Floorplan, CTS, NanoRoute, Verification)
│   ├── run_pnr.csh               # Standalone Innovus P&R runner
│   ├── run_power_analysis.tcl    # Voltus/Innovus power analysis script (Vectorless + Vectored SPEF)
│   ├── run_gls.csh               # Gate-Level Simulation runner with post-route SDF back-annotation
│   ├── check_redundancy.py       # Gate validator: verifies discrete ALUs, DMR checker, and TMR PC
│   ├── format_area_report.py     # Hierarchical area breakdown formatter
│   ├── view_layout.csh           # 1-Click GUI script to restore and inspect routed layout in Innovus
│   └── viewDefinition.tcl        # MMMC multi-corner timing configuration (slow setup, fast hold)
├── netlist/
│   ├── riscv_core_top_syn.v      # Post-synthesis structural gate netlist
│   ├── riscv_core_top_syn.sdc    # Post-synthesis exported constraints
│   ├── riscv_core_top_pr.v       # Post-route physical gate-level netlist
│   ├── riscv_core_top_routed.def # Post-route DEF layout (229 placed boundary pins)
│   ├── riscv_core_top.gds        # Streamed GDSII physical layout (units: 2000 per micron)
│   ├── riscv_core_top.spef       # Post-route extracted parasitic RC (slow corner)
│   ├── riscv_core_top_setup.sdf  # Post-route SDF timing delays for setup simulation
│   ├── riscv_core_top_hold.sdf   # Post-route SDF timing delays for hold simulation
│   └── riscv_core_top.enc        # Innovus design restoration script
├── reports/
│   ├── qor_summary.rpt           # Genus synthesis QoR summary
│   ├── area_report.rpt           # Genus synthesis area report
│   ├── timing_report.rpt         # Genus synthesis static timing analysis report
│   ├── power_report.rpt          # Genus synthesis power report
│   ├── innovus_area.rpt          # Innovus post-route hierarchical cell area breakdown
│   ├── innovus_power.rpt         # Innovus post-route vectorless power report
│   ├── innovus_power_vectorless.rpt # Innovus post-route vectorless power report (0.2 activity)
│   ├── innovus_power_vectored.rpt   # Innovus post-route vectored power report (workload VCD + SPEF)
│   ├── innovus_drc.rpt           # Innovus DRC verification (0 violations)
│   ├── innovus_connectivity.rpt  # Innovus connectivity verification (0 open nets, 0 shorts)
│   ├── innovus_antenna.rpt       # Innovus process antenna verification (0 violations)
│   └── innovus_timing/           # Detailed post-route timing slack reports
└── logs/
    ├── genus_syn.log             # Genus synthesis execution log
    ├── innovus_pnr.log           # Innovus place-and-route execution log
    ├── innovus_power.log         # Innovus power analysis log
    ├── gls_fault_injection.log   # Gate-level fault injection simulation log (5/5 passed)
    └── gls_workload.log          # Gate-level stress workload simulation log
```

---

## 3. Redundancy Preservation Architecture

Standard logic synthesis optimization merges duplicate logic cones driving identical inputs. To preserve the processor's hardware fault tolerance, the flow employs structural module wrappers and strict preservation constraints:

1. **Discrete Module Wrappers:**
   - Redundant ALUs are instantiated via discrete wrapper modules (`alu_0`, `alu_1`, `alu_2`) wrapping `alu`.
   - The DMR shadow control unit is wrapped in `control_unit_checker` wrapping `control_unit`.
2. **Genus Optimization Constraints (`run_genus_syn.tcl`):**
   ```tcl
   set_db [get_db instances */u_alu_0] .preserve true
   set_db [get_db instances */u_alu_1] .preserve true
   set_db [get_db instances */u_alu_2] .preserve true
   set_db [get_db instances */u_control_unit] .preserve true
   set_db [get_db instances */u_control_unit_checker] .preserve true

   set_db [get_db modules alu_0*] .preserve true
   set_db [get_db modules alu_1*] .preserve true
   set_db [get_db modules alu_2*] .preserve true
   set_db [get_db modules control_unit_checker*] .preserve true
   set_db [get_db modules *tmr_voter*] .preserve true
   set_db [get_db modules *regfile*] .preserve true

   set_db [get_db registers -if {.name =~ *pc_reg_*}] .preserve true
   ```
3. **Automated Redundancy Gate Validation:**
   Every netlist is validated using `cadence/scripts/check_redundancy.py` (stdlib only, run with `python3 -I`):
   ```bash
   python3 -I cadence/scripts/check_redundancy.py cadence/netlist/riscv_core_top_syn.v
   python3 -I cadence/scripts/check_redundancy.py cadence/netlist/riscv_core_top_pr.v
   ```
   The validator enforces:
   - Exactly 3 separate ALU instances (`u_alu_0`, `u_alu_1`, `u_alu_2`).
   - Zero cross-driving between redundant ALU results.
   - Active `u_control_unit_checker` and active `chk_*` comparator nets.
   - `cu_mismatch` is functional logic (not tied to constant 0 or 1).
   - TMR PC registers `pc_reg_a/b/c` contain 32 distinct flip-flops each (96 total).

---

## 4. Synthesis & Physical Design Flow

### Step 1: Genus Synthesis
Run automated synthesis to generate the gate-level netlist:
```csh
cd cadence
genus -batch -f scripts/run_genus_syn.tcl -log reports/genus_syn.log
```
Synthesis targets 100 MHz with a 9.2 ns synthesis constraint (0.8 ns margin for layout headroom).

### Step 2: Innovus Place & Route
Run automated physical layout:
```csh
cd cadence
innovus -batch -files scripts/run_innovus_pnr.tcl -log reports/innovus_pnr.log
```
The P&R flow executes:
1. **MMMC Initialization:** Slow corner (`slow.lib`, 0.9V, 125°C) for setup; fast corner (`fast.lib`, 1.1V, 0°C) for hold.
2. **Floorplanning:** $290\,\mu\text{m} \times 290\,\mu\text{m}$ core area ($320\,\mu\text{m} \times 320\,\mu\text{m}$ die area), 76.0% core density.
3. **Pin Placement:** 86 input pins constrained to LEFT boundary (Metal3), 143 output pins constrained to RIGHT boundary (Metal3). All 229 pins placed.
4. **Power Routing:** VDD and VSS rings on M5/M6; vertical M4 stripes and horizontal M5 stripes; standard cell rails connected on M1 via `sroute`.
5. **Placement & Optimization:** High-effort standard cell placement with Signal Integrity (SI) awareness enabled.
6. **Clock Tree Synthesis (CCOPT):** Target skew 0.160 ns; achieved skew **23 ps** across 865 sinks.
7. **Detailed Routing:** NanoRoute with SI-driven routing (`-routeWithSiDriven true`) and 20 antenna routing iterations.
8. **Hold Fixing:** `optDesign -postRoute -hold` to resolve hold violations using `fast.lib`.
9. **Physical Cell Insertion:** 6,833 fill cells added (`FILL1` to `FILL32`) to achieve 100% active silicon density.
10. **Physical Verification:** `verify_drc` (0 violations), `verify_connectivity` (0 errors), `verifyProcessAntenna` (0 violations).
11. **Signoff Deliverables:** GDSII streamout (`riscv_core_top.gds` with `-units 2000` matching LEF), DEF export (`riscv_core_top_routed.def`), parasitic SPEF extraction, and setup/hold SDF export.

### Step 3: Power Dissipation Analysis
Run post-route power analysis with Voltus / Innovus:
```csh
cd cadence
innovus -batch -files scripts/run_power_analysis.tcl -log reports/innovus_power_run.log
```
- **Vectorless Power (0.2 activity @ 100 MHz + SPEF):** **8.328 mW** (`innovus_power_vectorless.rpt`)
- **Vectored Power (Real Workload VCD + SPEF):** **4.399 mW** (`innovus_power_vectored.rpt`)
  - Internal: 2.992 mW (68.0%)
  - Switching: 1.080 mW (24.5%)
  - Leakage: 0.327 mW (7.4%)

### Step 4: Post-Route Gate-Level Simulation (GLS)
Run post-route gate-level simulation with full SDF back-annotation:
```csh
cd cadence
csh -f scripts/run_gls.csh
```
This runs both:
1. `tb/tb_gls_fault_injection.sv`: 5 gate-level fault tests verifying TMR ALU error masking, voter preservation, and DMR control unit mismatch trapping.
2. `tb/tb_compliance_run.sv` with `tests/stress_test_bytes.hex`: 2,428-instruction stress execution verified post-route at 100 MHz.

### Step 5: Layout Visualization in GUI
To open and inspect the completed routed database in the Innovus GUI:
```csh
cd cadence
csh -f scripts/view_layout.csh
```
