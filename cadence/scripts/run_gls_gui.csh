#!/bin/csh -f
# ==============================================================================
# Script: run_gls_gui.csh
# Description: Launch Cadence Xcelium & SimVision GUI for Gate-Level Simulation (GLS)
# ==============================================================================

if ( -f /home/install/cshrc ) then
    source /home/install/cshrc
endif

cd /home/student/Final-Project-EV

echo "======================================================================"
echo " Launching Cadence SimVision GUI for Gate-Level Simulation (GLS)"
echo " Netlist: cadence/netlist/riscv_core_top_pr.v (90nm GPDK Post-Route)"
echo " Testbench: tb/tb_riscv_core_top.sv"
echo "======================================================================"

xrun -64bit -gui -access +rwc -sv -noparamerr \
     /home/install/FOUNDRY/digital/90nm/dig/vlog/slow.v \
     cadence/netlist/riscv_core_top_pr.v \
     tb/tb_riscv_core_top.sv
