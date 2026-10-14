#!/bin/csh -f
# ==============================================================================
# Script: run_sim_gui.csh
# Description: Launch Cadence Xcelium & SimVision GUI for RTL Simulation
# ==============================================================================

if ( -f /home/install/cshrc ) then
    source /home/install/cshrc
endif

cd /home/student/Final-Project-EV

echo "======================================================================"
echo " Launching Cadence SimVision GUI for RTL Simulation"
echo " Testbench: tb/tb_riscv_core_top.sv"
echo "======================================================================"

xrun -64bit -gui -access +rwc -sv \
     rtl/riscv_pkg.sv \
     rtl/adaptive_redundancy_controller.sv \
     rtl/alu.sv \
     rtl/clock_gater.sv \
     rtl/control_unit.sv \
     rtl/hazard_unit.sv \
     rtl/id_ex_stage.sv \
     rtl/if_stage.sv \
     rtl/regfile.sv \
     rtl/tmr_voter.sv \
     rtl/uart_tx.sv \
     rtl/wb_stage.sv \
     rtl/riscv_core_top.sv \
     tb/tb_riscv_core_top.sv
