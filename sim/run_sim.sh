#!/bin/bash
set -e

PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$PROJECT_DIR"

# Step 1: Default to stress_test if no file provided
ASM_FILE="${1:-tests/stress_test.s}"
HEX_FILE="${ASM_FILE%.s}.hex"

# Step 2: Assemble target assembly file
if [ -f "$ASM_FILE" ]; then
    python3 sim/asm.py "$ASM_FILE" "$HEX_FILE"
else
    echo "ERROR: Assembly file $ASM_FILE not found!"
    exit 1
fi

# Step 3: Compile SystemVerilog RTL
iverilog -g2012 -o sim/sim.vvp -f filelist.f > sim/compile.log 2>&1

# Step 4: Run Simulation with Signature Arguments
vvp sim/sim.vvp +HEX="$HEX_FILE" +SIG_FILE=sim/dut.signature +SIG_START=00000100 +SIG_END=00000200 > sim/sim.log 2>&1
cat sim/sim.log

if grep -q "TEST PASSED" sim/sim.log || grep -q "RESULT: TEST PASSED" sim/sim.log; then
    echo "---------------------------------"
    echo "STATUS: SIMULATION_SUCCESS"
    exit 0
else
    echo "---------------------------------"
    echo "STATUS: SIMULATION_FAILED"
    exit 1
fi
