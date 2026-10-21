#!/bin/csh -f
# ==============================================================================
# Script: run_gls_gui.csh
# Description: Launch Cadence Xcelium & SimVision GUI for Gate-Level Simulation (GLS)
# ==============================================================================

if ( -f /home/install/cshrc ) then
    source /home/install/cshrc
endif

set SCRIPT_DIR = `dirname $0`
set SCRIPT_DIR = `cd "$SCRIPT_DIR" && pwd`
set PROJECT_DIR = `cd "$SCRIPT_DIR/../.." && pwd`
cd "$PROJECT_DIR"

echo "======================================================================"
echo " Launching Cadence SimVision GUI for Gate-Level Simulation (GLS)"
echo " Netlist: cadence/netlist/riscv_core_top_pr.v (90nm GPDK Post-Route)"
echo " SDF    : cadence/netlist/riscv_core_top_setup.sdf (Slow Corner 0.9V 125C)"
echo "======================================================================"

xrun -64bit -gui -access +rwc -sv -noparamerr +define+SDF_ANNOTATE -maxdelay \
     /home/install/FOUNDRY/digital/90nm/dig/vlog/slow.v \
     cadence/netlist/riscv_core_top_pr.v \
     tb/tb_gls_fault_injection.sv
