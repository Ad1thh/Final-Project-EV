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

# PDK Target Library Config (Override via environment variables or edit here)
if {[info exists env(PDK_LIB_PATH)]} {
    set LIB_PATH $env(PDK_LIB_PATH)
} else {
    set LIB_PATH ""
}

if {[info exists env(PDK_TARGET_LIB)]} {
    set TARGET_LIB $env(PDK_TARGET_LIB)
} else {
    set TARGET_LIB ""
}

if {$LIB_PATH != "" && $TARGET_LIB != ""} {
    set_db init_lib_search_path $LIB_PATH
    set_db target_library $TARGET_LIB
    set_db link_library   "* $TARGET_LIB"
    puts "--> Configured Target PDK Library: ${TARGET_LIB}"
} else {
    puts "--> INFO: No external PDK_TARGET_LIB set in environment."
    puts "--> Operating with default available Genus technology library or generic mapping."
}

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
init_design

check_design -unresolved

# ------------------------------------------------------------------------------
# 4. READ SDC TIMING CONSTRAINTS
# ------------------------------------------------------------------------------
set SDC_FILE "${CONSTRAINTS_DIR}/riscv_core_top.sdc"
if {[file exists $SDC_FILE]} {
    puts "--> Applying SDC constraints from: ${SDC_FILE}"
    read_sdc $SDC_FILE
} else {
    puts "--> WARNING: SDC file not found. Creating fallback 100MHz clock."
    create_clock -name clk -period 10.0 [get_ports clk]
}

# ------------------------------------------------------------------------------
# 5. FAULT-TOLERANCE PRESERVATION CONSTRAINTS (CRITICAL FOR ASIC)
# ------------------------------------------------------------------------------
puts "--> Applying Fault-Tolerance preservation rules to protect redundancy..."

# 5.1 Prevent Genus from merging identical TMR PC register replicas
catch {
    set pc_regs [get_db registers -if {.name =~ *pc_reg_*}]
    if {[llength $pc_regs] > 0} {
        set_db $pc_regs .preserve true
        puts "    [OK] Preserved [llength $pc_regs] TMR PC registers."
    }
}

# 5.2 Prevent Genus from optimizing out the DMR Control Unit checker
catch {
    set_db [get_db instances */u_control_unit] .preserve true
    set_db [get_db instances */u_control_unit_checker] .preserve true
    puts "    [OK] Preserved primary Control Unit and DMR Checker instances."
}

# 5.3 Prevent Genus from merging the triplicated ALUs (u_alu_0, u_alu_1, u_alu_2)
catch {
    set_db [get_db instances */u_alu_0] .preserve true
    set_db [get_db instances */u_alu_1] .preserve true
    set_db [get_db instances */u_alu_2] .preserve true
    puts "    [OK] Preserved triplicated ALU instances (EX0, EX1, EX2)."
}

# 5.4 Prevent aggressive datapath sharing between ECC XOR trees and ALU
set_db /designs/$DESIGN_NAME .dp_max_sharing 0
puts "    [OK] Restricted datapath XOR sharing to protect ECC timing margins."

# ------------------------------------------------------------------------------
# 6. SYNTHESIS OPTIMIZATION (GENERIC -> MAP -> OPT)
# ------------------------------------------------------------------------------
puts "--> Executing generic synthesis (syn_generic)..."
syn_generic

puts "--> Mapping to target technology library (syn_map)..."
syn_map

puts "--> Executing gate-level timing and area optimization (syn_opt)..."
syn_opt

# ------------------------------------------------------------------------------
# 7. GENERATE COMPREHENSIVE QoR REPORTS
# ------------------------------------------------------------------------------
puts "--> Generating Quality of Results (QoR) reports in: ${REPORT_DIR}"
report_timing > "${REPORT_DIR}/timing_report.rpt"
report_area -depth 3 > "${REPORT_DIR}/area_report.rpt"
report_power > "${REPORT_DIR}/power_report.rpt"
report_qor > "${REPORT_DIR}/qor_summary.rpt"
report_gates > "${REPORT_DIR}/gates_report.rpt"

# ------------------------------------------------------------------------------
# 8. EXPORT DELIVERABLES FOR CADENCE INNOVUS (P&R)
# ------------------------------------------------------------------------------
puts "--> Writing synthesized gate-level Verilog netlist & SDC to: ${OUTPUT_DIR}"
write_hdl -mapped > "${OUTPUT_DIR}/riscv_core_top_syn.v"
write_sdc > "${OUTPUT_DIR}/riscv_core_top_syn.sdc"

puts "======================================================================"
puts "  GENUS SYNTHESIS COMPLETED SUCCESSFULLY!"
puts "  - Netlist: ${OUTPUT_DIR}/riscv_core_top_syn.v"
puts "  - SDC:     ${OUTPUT_DIR}/riscv_core_top_syn.sdc"
puts "  - Reports: ${REPORT_DIR}/"
puts "======================================================================"
