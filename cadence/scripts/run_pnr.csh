#!/bin/csh -f
# ==============================================================================
# Script: run_pnr.csh
# Description: Automated Cadence Innovus P&R Wrapper for C-Shell (csh / tcsh)
# Environment: Sourced from /home/install/cshrc on sbinternetlab65
# ==============================================================================

# 1. Source lab environment profile if innovus is not already in PATH
which innovus >& /dev/null
if ( $status != 0 ) then
    if ( -f /home/install/cshrc ) then
        echo "--> Sourcing /home/install/cshrc..."
        source /home/install/cshrc
    endif
endif

# Check again after sourcing
which innovus >& /dev/null
if ( $status != 0 ) then
    echo "======================================================================"
    echo "ERROR: 'innovus' command could not be found."
    echo "Please verify /home/install/cshrc or contact your lab administrator."
    echo "======================================================================"
    exit 1
endif

# 2. Resolve Cadence working directory
if ( -f "scripts/run_innovus_pnr.tcl" ) then
    set CADENCE_DIR = `pwd`
else if ( -f "cadence/scripts/run_innovus_pnr.tcl" ) then
    cd cadence
    set CADENCE_DIR = `pwd`
else if ( "$0" != "" && "$0" != "csh" && "$0" != "tcsh" ) then
    set SCRIPT_DIR = `dirname "$0"`
    cd "$SCRIPT_DIR/.."
    set CADENCE_DIR = `pwd`
else if ( -d "/home/student/Final-Project-EV/cadence" ) then
    cd /home/student/Final-Project-EV/cadence
    set CADENCE_DIR = `pwd`
else
    echo "======================================================================"
    echo "ERROR: Could not locate cadence working directory."
    echo "Please cd to the 'cadence' directory and re-run this script."
    echo "======================================================================"
    exit 1
endif

echo "======================================================================"
echo " Starting Cadence Innovus P&R Flow (90nm GPDK)"
echo " Design: RV32E Fault-Tolerant Processor Core (riscv_core_top)"
echo " Host: `hostname`"
echo " Working directory: $CADENCE_DIR"
echo "======================================================================"

# Check synthesized netlist
if ( ! -f "$CADENCE_DIR/netlist/riscv_core_top_syn.v" ) then
    echo "======================================================================"
    echo "ERROR: Synthesized netlist not found in $CADENCE_DIR/netlist/"
    echo "Please run Genus synthesis first: ./scripts/run_flow.csh"
    echo "======================================================================"
    exit 1
endif

mkdir -p reports netlist

setenv BATCH_MODE 1

# Check if GUI flag is passed
if ( "$1" == "-gui" || "$1" == "-win" ) then
    echo "--> Launching Cadence Innovus with Interactive GUI..."
    innovus -win -files scripts/run_innovus_pnr.tcl -log reports/innovus_pnr.log
else
    echo "--> Launching Cadence Innovus in batch mode..."
    innovus -batch -files scripts/run_innovus_pnr.tcl -log reports/innovus_pnr.log
endif

set INNOVUS_STATUS = $status
if ( $INNOVUS_STATUS != 0 ) then
    echo "======================================================================"
    echo " ERROR: Cadence Innovus physical design failed (exit code $INNOVUS_STATUS)."
    echo " Please inspect the log: $CADENCE_DIR/reports/innovus_pnr.log"
    echo "======================================================================"
    exit $INNOVUS_STATUS
endif

echo "======================================================================"
echo " Cadence Innovus P&R completed successfully!"
echo " Check Routed Netlist in: $CADENCE_DIR/netlist/riscv_core_top_pr.v"
echo " Check Layout DEF in:     $CADENCE_DIR/netlist/riscv_core_top_routed.def"
echo " Check Reports in:        $CADENCE_DIR/reports/"
echo "======================================================================"
