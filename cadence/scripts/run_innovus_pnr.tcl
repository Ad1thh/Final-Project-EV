# ==============================================================================
# Script: run_innovus_pnr.tcl
# Description: Automated Cadence Innovus Physical Implementation (P&R) Flow
# Technology: 90nm GPDK Standard Cell Library (gsclib090)
# Design: RV32E Fault-Tolerant Processor Core (riscv_core_top)
# ==============================================================================

set DESIGN_NAME     "riscv_core_top"
set SCRIPT_DIR      [file dirname [file normalize [info script]]]
set CADENCE_ROOT    [file normalize "${SCRIPT_DIR}/.."]
set NETLIST_DIR     "${CADENCE_ROOT}/netlist"
set REPORT_DIR      "${CADENCE_ROOT}/reports"
set SDC_FILE        "${NETLIST_DIR}/riscv_core_top_syn.sdc"
set VERILOG_NETLIST "${NETLIST_DIR}/riscv_core_top_syn.v"

puts "======================================================================"
puts "  STARTING CADENCE INNOVUS P&R FLOW: ${DESIGN_NAME}"
puts "======================================================================"

# ------------------------------------------------------------------------------
# 1. VERIFY FRONT-END DELIVERABLES
# ------------------------------------------------------------------------------
if {![file exists $VERILOG_NETLIST]} {
    puts "ERROR: Synthesized netlist not found at: ${VERILOG_NETLIST}"
    puts "Please execute synthesis first: ./scripts/run_flow.csh"
    exit 1
}

if {![file exists $SDC_FILE]} {
    puts "ERROR: Synthesized SDC constraints not found at: ${SDC_FILE}"
    exit 1
}

file mkdir $NETLIST_DIR
file mkdir $REPORT_DIR
file mkdir "${REPORT_DIR}/innovus_timing"

# ------------------------------------------------------------------------------
# 2. MULTI-MODE MULTI-CORNER (MMMC) SETUP
# ------------------------------------------------------------------------------
set PDK_LIB_DIR    "/home/install/FOUNDRY/digital/90nm/dig/lib"
set PDK_LEF_FILE   "/home/install/FOUNDRY/digital/90nm/dig/lef/gsclib090_translated.lef"
set PDK_CAP_TABLE  "/home/install/FOUNDRY/digital/90nm/dig/captable/gpdk090.lef.extended.CapTbl"
set PDK_TIMING_LIB "${PDK_LIB_DIR}/slow.lib"

set MMMC_FILE "${CADENCE_ROOT}/scripts/viewDefinition.tcl"
set mmmc_fp [open $MMMC_FILE "w"]
puts $mmmc_fp "create_library_set -name slow_libs -timing \[list ${PDK_TIMING_LIB}\]"
puts $mmmc_fp "create_rc_corner -name default_rc -cap_table ${PDK_CAP_TABLE} -T 125.0"
puts $mmmc_fp "create_delay_corner -name slow_corner -library_set slow_libs -rc_corner default_rc"
puts $mmmc_fp "create_constraint_mode -name func_mode -sdc_files \[list ${SDC_FILE}\]"
puts $mmmc_fp "create_analysis_view -name slow_view -constraint_mode func_mode -delay_corner slow_corner"
puts $mmmc_fp "set_analysis_view -setup \[list slow_view\] -hold \[list slow_view\]"
close $mmmc_fp
puts "--> Generated MMMC View Definition: ${MMMC_FILE}"

# ------------------------------------------------------------------------------
# 3. DESIGN INITIALIZATION
# ------------------------------------------------------------------------------
set init_verilog   $VERILOG_NETLIST
set init_top_cell  $DESIGN_NAME
set init_lef_file  [list $PDK_LEF_FILE]
set init_mmmc_file $MMMC_FILE
set init_pwr_net   "VDD"
set init_gnd_net   "VSS"

puts "--> Loading Design & Technology Libraries into Innovus..."
init_design

# ------------------------------------------------------------------------------
# 4. FLOORPLANNING & POWER NETWORK SETUP
# ------------------------------------------------------------------------------
puts "--> Step 4.1: Creating Floorplan (70% utilization, square core)..."
floorPlan -site gsclib090site -r 1.0 0.70 15 15 15 15

puts "--> Step 4.2: Connecting Global Power & Ground Nets..."
globalNetConnect VDD -type pgpin -pin VDD -all
globalNetConnect VSS -type pgpin -pin VSS -all
globalNetConnect VDD -type tiehi -all
globalNetConnect VSS -type tielo -all

puts "--> Step 4.3: Constructing Power Ring & Standard Cell Followpins..."
addRing -nets {VDD VSS} -type core_rings -width 2.0 -spacing 1.0 -layer {top Metal6 bottom Metal6 left Metal5 right Metal5}
sroute -connect {corePin} -nets {VDD VSS}

# ------------------------------------------------------------------------------
# 5. STANDARD CELL PLACEMENT & OPTIMIZATION
# ------------------------------------------------------------------------------
puts "--> Step 5: Executing Standard Cell Placement (place_opt_design)..."
place_opt_design

# ------------------------------------------------------------------------------
# 6. CLOCK TREE SYNTHESIS (CTS / CCOpt)
# ------------------------------------------------------------------------------
puts "--> Step 6: Performing Clock Tree Synthesis (ccopt_design)..."
create_ccopt_clock_tree_spec
set_ccopt_property target_max_trans 0.400
set_ccopt_property target_skew 0.150
ccopt_design

# ------------------------------------------------------------------------------
# 7. DETAILED NANOROUTE
# ------------------------------------------------------------------------------
puts "--> Step 7: Executing Detailed NanoRoute (routeDesign)..."
setNanoRouteMode -quiet -routeWithSiDriven false -routeWithTimingDriven true
routeDesign

# ------------------------------------------------------------------------------
# 8. POST-ROUTE OPTIMIZATION & PHYSICAL VERIFICATION
# ------------------------------------------------------------------------------
puts "--> Step 8: Post-Route Optimization & Design Rule Checks..."
setDelayCalMode -SIAware false
setOptMode -postRouteSetupRecovery false
if {[catch {optDesign -postRoute} err]} {
    puts "--> Note on optDesign -postRoute: $err"
}

puts "--> Running Design Rule Check (DRC)..."
verify_drc -limit 1000 -report "${REPORT_DIR}/innovus_drc.rpt"

puts "--> Running Connectivity Verification..."
verify_connectivity -type all -report "${REPORT_DIR}/innovus_connectivity.rpt"

# ------------------------------------------------------------------------------
# 9. EXPORT PHYSICAL DESIGN DELIVERABLES
# ------------------------------------------------------------------------------
puts "--> Step 9: Exporting Layout Deliverables..."

# 9.1 Gate-level routed Verilog Netlist
saveNetlist "${NETLIST_DIR}/riscv_core_top_pr.v"
puts "    \[OK\] Exported Routed Netlist: ${NETLIST_DIR}/riscv_core_top_pr.v"

# 9.2 Complete DEF Layout (for GDSII stream-out and DRC tools)
defOut -floorplan -netlist -routing "${NETLIST_DIR}/riscv_core_top_routed.def"
puts "    \[OK\] Exported Layout DEF: ${NETLIST_DIR}/riscv_core_top_routed.def"

# 9.3 Post-Route Timing Signoff Report
timeDesign -postRoute -prefix postRoute -outDir "${REPORT_DIR}/innovus_timing"

# 9.4 Final Area & Power Reports
redirect "${REPORT_DIR}/innovus_area.rpt" { report_area -detail }
redirect "${REPORT_DIR}/innovus_power.rpt" { report_power }
puts "    \[OK\] Exported Area & Power Reports to ${REPORT_DIR}/"

# 9.5 Innovus Encrypted Database
saveDesign "${NETLIST_DIR}/riscv_core_top.enc"
puts "    \[OK\] Saved Innovus Database: ${NETLIST_DIR}/riscv_core_top.enc"

puts "======================================================================"
puts "  CADENCE INNOVUS PHYSICAL DESIGN COMPLETED SUCCESSFULLY!"
puts "======================================================================"

if {[info exists env(BATCH_MODE)] || [info exists env(RUN_FLOW_BATCH)]} {
    puts "--> Automated batch flow complete. Exiting Innovus."
    exit 0
}
