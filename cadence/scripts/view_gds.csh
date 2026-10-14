#!/bin/csh -f
# ==============================================================================
# Script: view_gds.csh
# Description: Launch Cadence Pegasus / PVS Design Review to inspect streamed GDSII
# ==============================================================================

if ( ! -f /home/install/cshrc ) then
    echo "ERROR: /home/install/cshrc not found."
    exit 1
endif

source /home/install/cshrc

set SCRIPT_DIR = `dirname $0`
set CADENCE_DIR = `cd $SCRIPT_DIR/.. && pwd`
set GDS_FILE = "$CADENCE_DIR/netlist/riscv_core_top.gds"

if ( ! -f "$GDS_FILE" ) then
    echo "ERROR: GDSII file not found at $GDS_FILE"
    echo "Please run Innovus P&R to stream out GDSII: ./scripts/run_pnr.csh"
    exit 1
endif

echo "======================================================================"
echo "  Launching Cadence Pegasus Design Review for: $GDS_FILE"
echo "======================================================================"

/home/install/PVS222/bin/design_review -data "$GDS_FILE"
