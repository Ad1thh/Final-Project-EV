#!/bin/bash
# ============================================================================
# Master 1-Click Zynq-7000 SoC Build & Deployment Flow for Linux
# ============================================================================
set -e

echo "=========================================================================="
echo "  MASTER 1-CLICK ZYNQ-7000 SOC BUILD & RUNTIME DEPLOYMENT (LINUX)"
echo "  Target: Digilent Zybo (Zynq-7000 XC7Z010-1CLG400C)"
echo "=========================================================================="

echo ""
echo " === [STEP 1] Generating Bitstream and XSA Platform ==="
vivado -mode batch -source scripts/build_soc_bitstream.tcl -log output/vivado_build.log -journal output/vivado_build.jou

echo ""
echo " === [STEP 2] Building Baremetal ARM Application in Vitis ==="
if command -v vitis &> /dev/null; then
    vitis -s scripts/vitis_build_app.py
elif command -v xsct &> /dev/null; then
    xsct scripts/vitis_build_app_xsct.tcl
else
    echo "[ERROR] Neither 'vitis' nor 'xsct' command found in PATH."
    exit 1
fi

echo ""
echo " === [STEP 3] Programming Zybo Board and Launching Firmware ==="
xsdb scripts/program_and_run_xsdb.tcl

echo ""
echo "=========================================================================="
echo "  [SUCCESS] SoC Hardware & Software Running on Digilent Zybo Board!"
echo "=========================================================================="
