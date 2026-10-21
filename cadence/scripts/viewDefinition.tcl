# ==============================================================================
# File: viewDefinition.tcl
# Description: Multi-Mode Multi-Corner (MMMC) Analysis View Definition
# Technology: 90nm GPDK (gsclib090)
# Setup Corner: slow.lib (0.9V, 125C, rc_slow)
# Hold Corner:  fast.lib (1.1V, 0C,   rc_fast)
# ==============================================================================

if {[info exists env(PDK_LIB_DIR)]} {
    set PDK_LIB_DIR $env(PDK_LIB_DIR)
} else {
    set PDK_LIB_DIR "/home/install/FOUNDRY/digital/90nm/dig/lib"
}

if {[info exists env(PDK_CAP_TABLE)]} {
    set PDK_CAP_TABLE $env(PDK_CAP_TABLE)
} else {
    set PDK_CAP_TABLE "/home/install/FOUNDRY/digital/90nm/dig/captable/gpdk090.lef.extended.CapTbl"
}

set SCRIPT_DIR   [file dirname [file normalize [info script]]]
set CADENCE_ROOT [file normalize "${SCRIPT_DIR}/.."]
set SDC_FILE     "${CADENCE_ROOT}/netlist/riscv_core_top_syn.sdc"

# Library Sets (Setup: slow.lib, Hold: fast.lib)
create_library_set -name slow_libs -timing [list ${PDK_LIB_DIR}/slow.lib]
create_library_set -name fast_libs -timing [list ${PDK_LIB_DIR}/fast.lib]

# RC Extraction Corners
create_rc_corner -name rc_slow -cap_table ${PDK_CAP_TABLE} -T 125.0
create_rc_corner -name rc_fast -cap_table ${PDK_CAP_TABLE} -T 0.0

# Delay Corners
create_delay_corner -name slow_corner -library_set slow_libs -rc_corner rc_slow
create_delay_corner -name fast_corner -library_set fast_libs -rc_corner rc_fast

# Constraint Mode (SDC)
create_constraint_mode -name func_mode -sdc_files [list ${SDC_FILE}]

# Analysis Views
create_analysis_view -name setup_view -constraint_mode func_mode -delay_corner slow_corner
create_analysis_view -name hold_view  -constraint_mode func_mode -delay_corner fast_corner

# Set Active Views
set_analysis_view -setup [list setup_view] -hold [list hold_view]
