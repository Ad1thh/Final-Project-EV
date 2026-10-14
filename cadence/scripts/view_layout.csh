#!/bin/csh -f
# ==============================================================================
# Script: view_layout.csh
# Description: Instantly open the routed layout in Cadence Innovus GUI
# ==============================================================================

if ( -f /home/install/cshrc ) then
    source /home/install/cshrc
endif

if ( -f "netlist/riscv_core_top.enc" ) then
    set CADENCE_DIR = `pwd`
else if ( -f "cadence/netlist/riscv_core_top.enc" ) then
    cd cadence
    set CADENCE_DIR = `pwd`
else
    cd /home/student/Final-Project-EV/cadence
    set CADENCE_DIR = `pwd`
endif

echo "======================================================================"
echo " Opening Cadence Innovus GUI for RV32E Fault-Tolerant Processor Core"
echo " Loading routed layout from: $CADENCE_DIR/netlist/riscv_core_top.enc"
echo "======================================================================"

innovus -win -execute "source netlist/riscv_core_top.enc"
