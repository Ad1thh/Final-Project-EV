#!/usr/bin/env bash
# ==============================================================================
# Script: run_flow.sh
# Description: Automated execution wrapper for Cadence Genus Synthesis
# ==============================================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CADENCE_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"

echo "======================================================================"
echo " Starting Cadence ASIC Flow for RV32E Fault-Tolerant Core"
echo " Host: $(hostname 2>/dev/null || echo 'Linux Server')"
echo " Working directory: ${CADENCE_DIR}"
echo "======================================================================"

cd "${CADENCE_DIR}"

mkdir -p reports netlist

# 1. Check if genus executable is available in PATH
if ! command -v genus &> /dev/null; then
    # If csh and /home/install/cshrc exist, delegate directly to run_flow.csh
    if command -v csh &> /dev/null && [ -f /home/install/cshrc ]; then
        echo "--> Sourcing Cadence environment via csh (/home/install/cshrc)..."
        exec csh -f "${SCRIPT_DIR}/run_flow.csh"
    fi

    echo "--> 'genus' not currently in PATH. Attempting automated environment setup..."
    if [ -f "${SCRIPT_DIR}/setup_cadence_env.sh" ]; then
        # shellcheck disable=SC1091
        source "${SCRIPT_DIR}/setup_cadence_env.sh"
    fi
fi

if ! command -v genus &> /dev/null; then
    echo "======================================================================"
    echo "ERROR: 'genus' command could not be found."
    echo "On your server (sbinternetlab65), use the C-shell environment:"
    echo "  1) csh"
    echo "  2) source /home/install/cshrc"
    echo "  3) ./scripts/run_flow.csh"
    echo "======================================================================"
    exit 1
fi

# 2. Configure batch execution mode
export RUN_FLOW_BATCH=1

# 3. Launch Cadence Genus Synthesis
echo "--> Launching Cadence Genus in batch mode..."
genus -batch -f "${SCRIPT_DIR}/run_genus_syn.tcl" -log "${CADENCE_DIR}/reports/genus_syn.log"

echo "======================================================================"
echo " Cadence Genus synthesis completed successfully!"
echo " Check QoR reports in: ${CADENCE_DIR}/reports/"
echo " Netlist output in:    ${CADENCE_DIR}/netlist/"
echo "======================================================================"

# 4. Display Quick QoR Summary if reports exist
if [ -f "${CADENCE_DIR}/reports/timing_report.rpt" ]; then
    echo "----------------------------------------------------------------------"
    echo " [TIMING SLACK SUMMARY]"
    grep -E "Slack|Endpoint|Path" "${CADENCE_DIR}/reports/timing_report.rpt" | head -n 10 || true
fi

if [ -f "${CADENCE_DIR}/reports/area_report.rpt" ]; then
    echo "----------------------------------------------------------------------"
    echo " [AREA SUMMARY]"
    grep -E "Total Area|Cell Count|riscv_core_top" "${CADENCE_DIR}/reports/area_report.rpt" | head -n 10 || true
fi

if [ -f "${CADENCE_DIR}/reports/power_report.rpt" ]; then
    echo "----------------------------------------------------------------------"
    echo " [POWER SUMMARY]"
    grep -E "Total Power|Leakage|Dynamic" "${CADENCE_DIR}/reports/power_report.rpt" | head -n 10 || true
fi
echo "======================================================================"
