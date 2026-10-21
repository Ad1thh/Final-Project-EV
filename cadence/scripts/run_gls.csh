#!/bin/csh -f
# ==============================================================================
# Script: run_gls.csh
# Description: Batch Gate-Level Simulation (GLS) with Post-Route SDF Timing
# Netlist: cadence/netlist/riscv_core_top_pr.v
# SDF: cadence/netlist/riscv_core_top_setup.sdf
# ==============================================================================

if ( -f /home/install/cshrc ) then
    source /home/install/cshrc
endif

set SCRIPT_DIR = `dirname $0`
set SCRIPT_DIR = `cd "$SCRIPT_DIR" && pwd`
set PROJECT_DIR = `cd "$SCRIPT_DIR/../.." && pwd`
cd "$PROJECT_DIR"

echo "======================================================================"
echo " Cadence Xcelium Gate-Level Simulation (GLS) Flow"
echo " Netlist: cadence/netlist/riscv_core_top_pr.v (Post-Route 90nm GPDK)"
echo " SDF    : cadence/netlist/riscv_core_top_setup.sdf (Slow Corner 0.9V 125C)"
echo " Host   : `hostname`"
echo "======================================================================"

set SIM_MODE = "all"
if ( $#argv >= 1 ) then
    set SIM_MODE = "$1"
endif

mkdir -p cadence/reports

if ( "$SIM_MODE" == "fault" || "$SIM_MODE" == "all" ) then
    echo "\n>>> Running Gate-Level Fault Injection Suite (tb_gls_fault_injection.sv)..."
    xrun -64bit -sv -noparamerr +define+SDF_ANNOTATE -maxdelay \
         /home/install/FOUNDRY/digital/90nm/dig/vlog/slow.v \
         cadence/netlist/riscv_core_top_pr.v \
         tb/tb_gls_fault_injection.sv \
         -clean -run -l cadence/reports/gls_fault_injection.log

    if ( $status != 0 ) then
        echo "[ERROR] GLS Fault Injection suite failed!"
        exit 1
    endif
    echo "[SUCCESS] GLS Fault Injection suite passed cleanly!"
endif

if ( "$SIM_MODE" == "workload" || "$SIM_MODE" == "all" ) then
    echo "\n>>> Running Gate-Level Workload Simulation (tb_compliance_run.sv with stress_test)..."
    xrun -64bit -sv -noparamerr +define+SDF_ANNOTATE -maxdelay \
         /home/install/FOUNDRY/digital/90nm/dig/vlog/slow.v \
         cadence/netlist/riscv_core_top_pr.v \
         tb/tb_compliance_run.sv \
         +HEX=tests/stress_test_bytes.hex \
         -clean -run -l cadence/reports/gls_workload.log

    if ( $status != 0 ) then
        echo "[ERROR] GLS Workload simulation failed!"
        exit 1
    endif
    echo "[SUCCESS] GLS Workload simulation passed cleanly!"
endif

echo "\n======================================================================"
echo " ALL GLS RUNS COMPLETED SUCCESSFULLY"
echo " Reports logged under cadence/reports/"
echo "======================================================================"
exit 0
