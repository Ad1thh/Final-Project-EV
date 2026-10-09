# ==============================================================================
# Script: run_innovus_pnr.tcl
# Description: Cadence Innovus Physical Implementation (P&R) Startup Script
# Design: RV32E Fault-Tolerant Processor Core
# ==============================================================================

set DESIGN_NAME     "riscv_core_top"
set SCRIPT_DIR      [file dirname [file normalize [info script]]]
set CADENCE_ROOT    [file normalize "${SCRIPT_DIR}/.."]
set NETLIST_DIR     "${CADENCE_ROOT}/netlist"
set SDC_FILE        "${NETLIST_DIR}/riscv_core_top_syn.sdc"
set VERILOG_NETLIST "${NETLIST_DIR}/riscv_core_top_syn.v"

puts "======================================================================"
puts "  CADENCE INNOVUS PHYSICAL DESIGN FLOW: ${DESIGN_NAME}"
puts "======================================================================"

# 1. Verification of synthesized front-end outputs
if {![file exists $VERILOG_NETLIST]} {
    puts "ERROR: Synthesized netlist not found at: ${VERILOG_NETLIST}"
    puts "Please execute 'genus -f run_genus_syn.tcl' first."
    return
}

# 2. Design Initialization Setup
# In Innovus, specify the LEF files and MMMC file for your technology
set init_verilog $VERILOG_NETLIST
set init_top_cell $DESIGN_NAME
set init_pwr_net "VDD"
set init_gnd_net "VSS"

puts "--> Initializing design: ${DESIGN_NAME}"
# init_design

# 3. Standard Floorplan Template (Example: 70% utilization, square core)
# floorPlan -site CoreSite -r 1.0 0.70 15 15 15 15

# 4. Power Ring & Stripe Generation
# addRing -nets {VDD VSS} -width 2.0 -spacing 1.0 -layer {metal5 metal6}
# sroute -nets {VDD VSS}

# 5. Standard Cell Placement
# place_opt_design

# 6. Clock Tree Synthesis (Single clk domain)
# ccopt_design

# 7. Detailed Nanoroute
# routeDesign

# 8. Post-Route Optimization & Verification
# optDesign -postRoute
# verify_drc
# verify_connectivity
# timeDesign -postRoute

puts "======================================================================"
puts "  INNOVUS TEMPLATE READY — Configure PDK LEF/MMMC and proceed."
puts "======================================================================"
