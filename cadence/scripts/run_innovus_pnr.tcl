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
# 2. MULTI-MODE MULTI-CORNER (MMMC) SETUP & PDK PATH CONFIGURATION
# ------------------------------------------------------------------------------
if {[info exists env(PDK_LIB_DIR)]} {
    set PDK_LIB_DIR $env(PDK_LIB_DIR)
} else {
    set PDK_LIB_DIR "/home/install/FOUNDRY/digital/90nm/dig/lib"
}

if {[info exists env(PDK_LEF_FILE)]} {
    set PDK_LEF_FILE $env(PDK_LEF_FILE)
} else {
    set PDK_LEF_FILE "/home/install/FOUNDRY/digital/90nm/dig/lef/gsclib090_translated.lef"
}

if {[info exists env(PDK_CAP_TABLE)]} {
    set PDK_CAP_TABLE $env(PDK_CAP_TABLE)
} else {
    set PDK_CAP_TABLE "/home/install/FOUNDRY/digital/90nm/dig/captable/gpdk090.lef.extended.CapTbl"
}

if {[info exists env(PDK_GDS_MAP)]} {
    set GDS_MAP_FILE $env(PDK_GDS_MAP)
} else {
    set GDS_MAP_FILE "/home/install/FOUNDRY/analog/90nm/soce/soce_gds.map"
}

if {[info exists env(PDK_GDS_DIR)]} {
    set GDS_DIR $env(PDK_GDS_DIR)
} else {
    set GDS_DIR "/home/install/FOUNDRY/digital/90nm/dig/gds"
}

set MMMC_FILE "${CADENCE_ROOT}/scripts/viewDefinition.tcl"
puts "--> Using MMMC View Definition: ${MMMC_FILE}"

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
setDesignMode -process 90

# ------------------------------------------------------------------------------
# 4. FLOORPLANNING & POWER NETWORK SETUP
# ------------------------------------------------------------------------------
puts "--> Step 4.1: Creating Floorplan (70% utilization, square core)..."
floorPlan -site gsclib090site -r 1.0 0.70 15 15 15 15

puts "--> Step 4.1b: Placing Top-Level I/O Pins on Core Boundary..."
setPinAssignMode -pinEditInBatch true
set in_ports  [get_db [get_db ports -if {.direction == in}] .name]
set out_ports [get_db [get_db ports -if {.direction == out}] .name]
puts "    Assigning [llength $in_ports] input pins to LEFT boundary (Metal3)..."
editPin -pin $in_ports  -spreadType SIDE -layer Metal3 -side LEFT  -spreadDirection clockwise
puts "    Assigning [llength $out_ports] output pins to RIGHT boundary (Metal3)..."
editPin -pin $out_ports -spreadType SIDE -layer Metal3 -side RIGHT -spreadDirection clockwise

puts "--> Step 4.2: Connecting Global Power & Ground Nets..."
globalNetConnect VDD -type pgpin -pin VDD -all
globalNetConnect VSS -type pgpin -pin VSS -all
globalNetConnect VDD -type tiehi -all
globalNetConnect VSS -type tielo -all

puts "--> Step 4.3: Constructing Power Ring, Stripes & Followpins..."
# Core Ring: Horizontal segments on Metal5, Vertical segments on Metal6
addRing -nets {VDD VSS} -type core_rings -width 2.0 -spacing 1.0 -layer {top Metal5 bottom Metal5 left Metal6 right Metal6}

# Power Stripes: Consistent with LEF layer directions (Metal4 Vertical, Metal5 Horizontal)
addStripe -nets {VDD VSS} -layer Metal4 -direction vertical   -width 1.5 -spacing 1.0 -set_to_set_distance 40.0 -start_offset 15.0
addStripe -nets {VDD VSS} -layer Metal5 -direction horizontal -width 1.5 -spacing 1.0 -set_to_set_distance 40.0 -start_offset 15.0

# Connect standard cell power pins
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
set_ccopt_property buffer_cells {CLKBUFX12 CLKBUFX16 CLKBUFX2 CLKBUFX20 CLKBUFX3 CLKBUFX4 CLKBUFX6 CLKBUFX8 BUFX12 BUFX16 BUFX2 BUFX20 BUFX3 BUFX4 BUFX6 BUFX8}
set_ccopt_property inverter_cells {CLKINVX1 CLKINVX12 CLKINVX16 CLKINVX2 CLKINVX20 CLKINVX3 CLKINVX4 CLKINVX6 CLKINVX8 INVX1 INVX12 INVX16 INVX2 INVX20 INVX3 INVX4 INVX6 INVX8 INVXL}
set_ccopt_property target_max_trans 0.400
set_ccopt_property target_skew 0.150
ccopt_design

# ------------------------------------------------------------------------------
# 7. DETAILED NANOROUTE (SI-Driven)
# ------------------------------------------------------------------------------
puts "--> Step 7: Executing Detailed NanoRoute with SI enabled (routeDesign)..."
setNanoRouteMode -quiet -routeWithSiDriven true -routeWithTimingDriven true
routeDesign

# ------------------------------------------------------------------------------
# 8. POST-ROUTE OPTIMIZATION (SETUP & HOLD)
# ------------------------------------------------------------------------------
puts "--> Step 8: Post-Route Optimization (Setup & Hold)..."
setAnalysisMode -analysisType onChipVariation -cppr both
setDelayCalMode -SIAware true
setOptMode -postRouteSetupRecovery true
setOptMode -postRouteHoldRecovery true

puts "    Running optDesign -postRoute (Setup)..."
optDesign -postRoute

puts "    Running optDesign -postRoute -hold (Hold)..."
optDesign -postRoute -hold

# ------------------------------------------------------------------------------
# 9. POST-ROUTE TIMING SIGNOFF (SETUP & HOLD)
# ------------------------------------------------------------------------------
puts "--> Step 9: Post-Route Timing Signoff..."
timeDesign -postRoute -prefix postRoute_setup -outDir "${REPORT_DIR}/innovus_timing"
timeDesign -postRoute -hold -prefix postRoute_hold -outDir "${REPORT_DIR}/innovus_timing"

# ------------------------------------------------------------------------------
# 10. PHYSICAL CELL INSERTION (FILLER CELLS)
# ------------------------------------------------------------------------------
puts "--> Step 10: Adding Standard Cell Fillers..."
addFiller -cell {FILL64 FILL32 FILL16 FILL8 FILL4 FILL2 FILL1} -prefix FILLER

# ------------------------------------------------------------------------------
# 11. PHYSICAL VERIFICATION (DRC, LVS/CONNECTIVITY, ANTENNA) BEFORE STREAMOUT
# ------------------------------------------------------------------------------
puts "--> Step 11: Executing Physical Design Verification..."
puts "    Running Design Rule Check (DRC)..."
verify_drc -limit 1000 -report "${REPORT_DIR}/innovus_drc.rpt"

puts "    Running Connectivity Verification..."
verify_connectivity -type all -report "${REPORT_DIR}/innovus_connectivity.rpt"

puts "    Running Process Antenna Verification..."
verifyProcessAntenna -report "${REPORT_DIR}/innovus_antenna.rpt"

# ------------------------------------------------------------------------------
# 12. RC EXTRACTION & SDF EXPORT
# ------------------------------------------------------------------------------
puts "--> Step 12: Extracting Post-Route Parasitics & SDF..."
extractRC
rcOut -spef "${NETLIST_DIR}/riscv_core_top.spef"
puts "    \[OK\] Exported Post-Route SPEF: ${NETLIST_DIR}/riscv_core_top.spef"

write_sdf -view setup_view -version 3.0 "${NETLIST_DIR}/riscv_core_top_setup.sdf"
write_sdf -view hold_view  -version 3.0 "${NETLIST_DIR}/riscv_core_top_hold.sdf"
puts "    \[OK\] Exported Setup & Hold SDF: ${NETLIST_DIR}/riscv_core_top_*.sdf"

# ------------------------------------------------------------------------------
# 13. EXPORT PHYSICAL DESIGN DELIVERABLES
# ------------------------------------------------------------------------------
puts "--> Step 13: Exporting Layout Deliverables..."

# 13.1 Gate-level routed Verilog Netlist
saveNetlist "${NETLIST_DIR}/riscv_core_top_pr.v"
puts "    \[OK\] Exported Routed Netlist: ${NETLIST_DIR}/riscv_core_top_pr.v"

# 13.2 Complete DEF Layout (units 2000 matching LEF)
defOut -floorplan -netlist -routing "${NETLIST_DIR}/riscv_core_top_routed.def"
puts "    \[OK\] Exported Layout DEF: ${NETLIST_DIR}/riscv_core_top_routed.def"

# 13.3 Final Area & Power Reports
redirect "${REPORT_DIR}/innovus_area.rpt" { report_area -detail }
redirect "${REPORT_DIR}/innovus_power.rpt" { report_power }
puts "    \[OK\] Exported Area & Power Reports to ${REPORT_DIR}/"

# 13.4 Innovus Encrypted Database
saveDesign "${NETLIST_DIR}/riscv_core_top.enc"
puts "    \[OK\] Saved Innovus Database: ${NETLIST_DIR}/riscv_core_top.enc"

# 13.5 Stream Out Final GDSII Silicon Mask Layout (units 2000 matches LEF DATABASE MICRONS)
set GDS_CELL_FILES [glob -nocomplain "${GDS_DIR}/*.gds"]
if {[file exists $GDS_MAP_FILE] && [llength $GDS_CELL_FILES] > 0} {
    streamOut "${NETLIST_DIR}/riscv_core_top.gds" -mapFile $GDS_MAP_FILE -merge $GDS_CELL_FILES -units 2000 -mode ALL
    puts "    \[OK\] Exported Silicon GDSII Layout: ${NETLIST_DIR}/riscv_core_top.gds"
} else {
    puts "    \[WARN\] GDS map or cell files not found, skipping streamOut."
}

puts "======================================================================"
puts "  CADENCE INNOVUS PHYSICAL DESIGN COMPLETED SUCCESSFULLY!"
puts "======================================================================"

if {[info exists env(BATCH_MODE)] || [info exists env(RUN_FLOW_BATCH)]} {
    puts "--> Automated batch flow complete. Exiting Innovus."
    exit 0
}
