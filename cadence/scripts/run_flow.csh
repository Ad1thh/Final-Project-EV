#!/bin/csh -f
# ==============================================================================
# Script: run_flow.csh
# Description: Cadence Genus Synthesis Wrapper for C-Shell (csh / tcsh)
# Environment: Sourced from /home/install/cshrc on sbinternetlab65
# ==============================================================================

# 1. Source lab environment profile if genus is not already found
which genus >& /dev/null
if ( $status != 0 ) then
    if ( -f /home/install/cshrc ) then
        echo "--> Sourcing /home/install/cshrc..."
        source /home/install/cshrc
    endif
endif

# Check again after sourcing
which genus >& /dev/null
if ( $status != 0 ) then
    echo "======================================================================"
    echo "ERROR: 'genus' command could not be found."
    echo "Please verify /home/install/cshrc or contact your lab administrator."
    echo "======================================================================"
    exit 1
endif

# 2. Resolve Cadence working directory
set SCRIPT_PATH = `readlink -f $0 2>/dev/null || which $0`
set SCRIPT_DIR  = `dirname $SCRIPT_PATH`
cd $SCRIPT_DIR/..
set CADENCE_DIR = `pwd`

echo "======================================================================"
echo " Starting Cadence ASIC Flow for RV32E Fault-Tolerant Core (csh)"
echo " Host: `hostname`"
echo " Working directory: $CADENCE_DIR"
echo "======================================================================"

mkdir -p reports netlist

# Set batch flag so run_genus_syn.tcl exits cleanly upon completion
setenv RUN_FLOW_BATCH 1

echo "--> Launching Cadence Genus in batch mode..."
genus -batch -f scripts/run_genus_syn.tcl -log reports/genus_syn.log

echo "======================================================================"
echo " Cadence Genus synthesis completed successfully!"
echo " Check QoR reports in: $CADENCE_DIR/reports/"
echo " Netlist output in:    $CADENCE_DIR/netlist/"
echo "======================================================================"

# Quick QoR Summary display
if ( -f reports/timing_report.rpt ) then
    echo "----------------------------------------------------------------------"
    echo " [TIMING SLACK SUMMARY]"
    grep -E "Slack|Endpoint|Path" reports/timing_report.rpt | head -n 10
endif

if ( -f reports/area_report.rpt ) then
    echo "----------------------------------------------------------------------"
    echo " [AREA SUMMARY]"
    grep -E "Total Area|Cell Count|riscv_core_top" reports/area_report.rpt | head -n 10
endif

if ( -f reports/power_report.rpt ) then
    echo "----------------------------------------------------------------------"
    echo " [POWER SUMMARY]"
    grep -E "Total Power|Leakage|Dynamic" reports/power_report.rpt | head -n 10
endif
echo "======================================================================"
