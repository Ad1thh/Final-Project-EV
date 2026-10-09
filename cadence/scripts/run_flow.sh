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
echo " Working directory: ${CADENCE_DIR}"
echo "======================================================================"

cd "${CADENCE_DIR}"

mkdir -p reports netlist

# Check if genus executable is available in PATH
if ! command -v genus &> /dev/null; then
    echo "ERROR: 'genus' command not found in your PATH."
    echo "Please source your Cadence environment or load the module, for example:"
    echo "  module load cadence/genus"
    echo "  source /tools/cadence/cshrc_genus"
    exit 1
fi

echo "--> Launching Cadence Genus..."
genus -f "${SCRIPT_DIR}/run_genus_syn.tcl" -log "${CADENCE_DIR}/reports/genus_syn.log"

echo "======================================================================"
echo " Cadence Genus synthesis finished."
echo " Check QoR reports in: ${CADENCE_DIR}/reports/"
echo " Netlist output in:    ${CADENCE_DIR}/netlist/"
echo "======================================================================"
