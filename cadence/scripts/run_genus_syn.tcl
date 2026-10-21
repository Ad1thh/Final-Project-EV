# ==============================================================================
# Script: run_genus_syn.tcl
# Description: Automated Cadence Genus Synthesis Script
# Design: RV32E Fault-Tolerant Processor Core
# Flow: Cadence Common UI (Genus 19.x / 20.x / 21.x / 22.x)
# ==============================================================================

puts "======================================================================"
puts "  STARTING CADENCE GENUS SYNTHESIS: riscv_core_top"
puts "======================================================================"

# ------------------------------------------------------------------------------
# 1. ENVIRONMENT & DIRECTORY CONFIGURATION
# ------------------------------------------------------------------------------
set DESIGN_NAME     "riscv_core_top"
set SCRIPT_DIR      [file dirname [file normalize [info script]]]
set CADENCE_ROOT    [file normalize "${SCRIPT_DIR}/.."]
set PROJECT_ROOT    [file normalize "${CADENCE_ROOT}/.."]
set RTL_DIR         "${PROJECT_ROOT}/rtl"
set CONSTRAINTS_DIR "${CADENCE_ROOT}/constraints"
set OUTPUT_DIR      "${CADENCE_ROOT}/netlist"
set REPORT_DIR      "${CADENCE_ROOT}/reports"

file mkdir $OUTPUT_DIR
file mkdir $REPORT_DIR

# PDK Target Library Config (90nm Digital Standard Cell Library)
set DEFAULT_LIB_PATH   "/home/install/FOUNDRY/digital/90nm/dig/lib"
set DEFAULT_TARGET_LIB "slow.lib"

if {[info exists env(PDK_LIB_PATH)]} {
    set LIB_PATH $env(PDK_LIB_PATH)
} else {
    set LIB_PATH $DEFAULT_LIB_PATH
}

if {[info exists env(PDK_TARGET_LIB)]} {
    set TARGET_LIB $env(PDK_TARGET_LIB)
} else {
    set TARGET_LIB $DEFAULT_TARGET_LIB
}

set_db init_lib_search_path $LIB_PATH
set_db target_library $TARGET_LIB
set_db link_library   $TARGET_LIB
puts "--> Configured Target PDK Library: ${LIB_PATH}/${TARGET_LIB}"

# ------------------------------------------------------------------------------
# 2. READ HDL FILES IN DEPENDENCY ORDER
# ------------------------------------------------------------------------------
set_db init_hdl_search_path $RTL_DIR

set RTL_FILES [list \
    riscv_pkg.sv \
    alu.sv \
    control_unit.sv \
    hazard_unit.sv \
    tmr_voter.sv \
    clock_gater.sv \
    adaptive_redundancy_controller.sv \
    regfile.sv \
    if_stage.sv \
    wb_stage.sv \
    id_ex_stage.sv \
    riscv_core_top.sv \
]

puts "--> Reading SystemVerilog RTL sources from: ${RTL_DIR}"
read_hdl -language sv $RTL_FILES

# ------------------------------------------------------------------------------
# 3. ELABORATION & INITIALIZATION
# ------------------------------------------------------------------------------
puts "--> Elaborating top-level module: ${DESIGN_NAME}"
elaborate $DESIGN_NAME

check_design -unresolved

# ------------------------------------------------------------------------------
# 4. READ SDC TIMING CONSTRAINTS & SYNTHESIS MARGIN
# ------------------------------------------------------------------------------
set SDC_FILE "${CONSTRAINTS_DIR}/riscv_core_top.sdc"
if {[file exists $SDC_FILE]} {
    puts "--> Applying SDC constraints from: ${SDC_FILE}"
    read_sdc $SDC_FILE
} else {
    puts "--> WARNING: SDC file not found. Creating fallback 100MHz clock."
    create_clock -name clk -period 10.0 [get_ports clk]
}

# Synthesis margin override: synthesize against tighter clock period
# so Innovus physical implementation has positive timing margin.
set SIGNOFF_CLOCK_PERIOD 10.0
if {[info exists env(SYNTH_CLOCK_PERIOD)]} {
    set TARGET_SYNTH_PERIOD $env(SYNTH_CLOCK_PERIOD)
} else {
    set TARGET_SYNTH_PERIOD 9.2
}
create_clock -name clk -period $TARGET_SYNTH_PERIOD [get_ports clk]
set_clock_uncertainty -setup 0.250 [get_clocks clk]
set_clock_uncertainty -hold  0.100 [get_clocks clk]
set_clock_transition 0.100 [get_clocks clk]
puts "--> \[MARGIN\] Applied synthesis margin clock period: ${TARGET_SYNTH_PERIOD} ns (Signoff target: ${SIGNOFF_CLOCK_PERIOD} ns)"

# ------------------------------------------------------------------------------
# 5. PRE-GENERIC FAULT-TOLERANCE PRESERVATION CONSTRAINTS
# ------------------------------------------------------------------------------
puts "--> Applying pre-generic Fault-Tolerance preservation rules..."

# 5.1 Prevent automatic ungrouping across hierarchy
set_db auto_ungroup none
puts "    \[OK\] Preserved module hierarchy boundaries (auto_ungroup none)."

# 5.2 Prevent register merging, constant pruning, and unloaded instance pruning
set_db optimize_merge_flops false
set_db optimize_constant_0_flops false
set_db optimize_constant_1_flops false
set_db delete_unloaded_insts false
puts "    \[OK\] Disabled register merging, constant pruning, and unloaded instance deletion."

# 5.3 Lock ungroup_ok and boundary_opto on redundant submodules
set_db [get_db modules alu*] .ungroup_ok false
set_db [get_db modules control_unit*] .ungroup_ok false
set_db [get_db modules tmr_voter*] .ungroup_ok false
set_db [get_db modules adaptive_redundancy_controller*] .ungroup_ok false

set_db [get_db modules alu*] .boundary_opto false
set_db [get_db modules control_unit*] .boundary_opto false
set_db [get_db modules tmr_voter*] .boundary_opto false
set_db [get_db modules adaptive_redundancy_controller*] .boundary_opto false
puts "    \[OK\] Disabled ungrouping and boundary optimization on alu*, control_unit*, tmr_voter*, and ARC modules."

# 5.4 Lock instance ungrouping
set alu_insts [get_db hinsts u_id_ex_stage/u_alu_*]
if {[llength $alu_insts] > 0} {
    set_db $alu_insts .ungroup_ok false
    puts "    \[OK\] Disabled ungrouping on [llength $alu_insts] ALU instances: [get_db $alu_insts .name]"
}

set cu_insts [get_db hinsts u_id_ex_stage/u_control_unit*]
if {[llength $cu_insts] > 0} {
    set_db $cu_insts .ungroup_ok false
    puts "    \[OK\] Disabled ungrouping on [llength $cu_insts] Control Unit instances: [get_db $cu_insts .name]"
}

set voter_insts [get_db hinsts -if {.name =~ "*voter*"}]
if {[llength $voter_insts] > 0} {
    set_db $voter_insts .ungroup_ok false
    puts "    \[OK\] Disabled ungrouping on [llength $voter_insts] Voter instances: [get_db $voter_insts .name]"
}

# ------------------------------------------------------------------------------
# 6. GENERIC SYNTHESIS
# ------------------------------------------------------------------------------
puts "--> Executing generic synthesis (syn_generic)..."
syn_generic

# ------------------------------------------------------------------------------
# 7. TECHNOLOGY MAPPING, POST-MAP PRESERVATION & OPTIMIZATION
# ------------------------------------------------------------------------------
puts "--> Mapping to target technology library (syn_map)..."
syn_map

puts "--> Applying post-mapping instance and net preservation rules..."
set alu_insts [get_db hinsts u_id_ex_stage/u_alu_*]
if {[llength $alu_insts] > 0} {
    set_db $alu_insts .preserve true
    puts "    \[OK\] Preserved [llength $alu_insts] TMR ALU instances: [get_db $alu_insts .name]"
}

set cu_insts [get_db hinsts u_id_ex_stage/u_control_unit*]
if {[llength $cu_insts] > 0} {
    set_db $cu_insts .preserve true
    puts "    \[OK\] Preserved [llength $cu_insts] Control Unit DMR instances: [get_db $cu_insts .name]"
}

set arc_insts [get_db hinsts u_id_ex_stage/u_adaptive_redundancy_controller*]
if {[llength $arc_insts] > 0} {
    set_db $arc_insts .preserve true
    puts "    \[OK\] Preserved [llength $arc_insts] ARC instances: [get_db $arc_insts .name]"
}

set voter_insts [get_db hinsts -if {.name =~ "*voter*"}]
if {[llength $voter_insts] > 0} {
    set_db $voter_insts .preserve true
    puts "    \[OK\] Preserved [llength $voter_insts] Voter instances: [get_db $voter_insts .name]"
}

set chk_nets [get_db nets -if {.name =~ "*chk_*"}]
if {[llength $chk_nets] > 0} {
    set_db $chk_nets .preserve true
    puts "    \[OK\] Preserved [llength $chk_nets] DMR checker nets."
}

puts "--> Executing gate-level timing and area optimization (syn_opt)..."
syn_opt

# ------------------------------------------------------------------------------
# 8. GENERATE COMPREHENSIVE QoR REPORTS
# ------------------------------------------------------------------------------
puts "--> Generating Quality of Results (QoR) reports in: ${REPORT_DIR}"
report_timing > "${REPORT_DIR}/timing_report.rpt"
report_area -depth 3 > "${REPORT_DIR}/area_report.rpt"
report_power > "${REPORT_DIR}/power_report.rpt"
report_qor > "${REPORT_DIR}/qor_summary.rpt"
report_gates > "${REPORT_DIR}/gates_report.rpt"

# ------------------------------------------------------------------------------
# 9. EXPORT DELIVERABLES FOR CADENCE INNOVUS (P&R)
# ------------------------------------------------------------------------------
# Restore signoff clock period of 10.0ns (100 MHz) before exporting SDC for Innovus
create_clock -name clk -period $SIGNOFF_CLOCK_PERIOD [get_ports clk]
set_clock_uncertainty -setup 0.250 [get_clocks clk]
set_clock_uncertainty -hold  0.100 [get_clocks clk]
set_clock_transition 0.100 [get_clocks clk]
puts "--> Restored signoff clock period to ${SIGNOFF_CLOCK_PERIOD} ns for Innovus deliverable SDC."

puts "--> Writing synthesized gate-level Verilog netlist & SDC to: ${OUTPUT_DIR}"
write_hdl -mapped > "${OUTPUT_DIR}/riscv_core_top_syn.v"
write_sdc > "${OUTPUT_DIR}/riscv_core_top_syn.sdc"

puts "======================================================================"
puts "  GENUS SYNTHESIS COMPLETED SUCCESSFULLY!"
puts "  - Netlist: ${OUTPUT_DIR}/riscv_core_top_syn.v"
puts "  - SDC:     ${OUTPUT_DIR}/riscv_core_top_syn.sdc"
puts "  - Reports: ${REPORT_DIR}/"
puts "======================================================================"

# Clean exit for automated batch runs
if {[info exists env(RUN_FLOW_BATCH)] || [info exists env(BATCH_MODE)]} {
    puts "--> Automated batch flow complete. Exiting Genus."
    exit 0
}
