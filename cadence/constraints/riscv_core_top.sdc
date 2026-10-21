# ==============================================================================
# File: riscv_core_top.sdc
# Description: Synopsys Design Constraints (SDC) for Cadence Genus & Innovus
# Target: RV32E Fault-Tolerant Processor Core @ 100 MHz (10.0 ns)
# ==============================================================================

# 1. Primary Clock Definition
# 100 MHz target (10.0 ns period)
create_clock -name clk -period 10.0 [get_ports clk]

# Clock Uncertainty (Jitter + Margin)
set_clock_uncertainty -setup 0.250 [get_clocks clk]
set_clock_uncertainty -hold  0.100 [get_clocks clk]
set_clock_transition 0.100 [get_clocks clk]

# 2. Input Delays (Assuming 20% external budget for I/O paths)
# Reset recovery and removal are strictly constrained; rst_n is not false-pathed.
set static_inputs [get_ports -quiet {clk tmr_mode_pin fi_reg_en fi_reg_addr* fi_reg_bit* fi_alu_en fi_alu_sel* fi_alu_bit*}]
set core_inputs [remove_from_collection [all_inputs] $static_inputs]
set_input_delay -clock clk -max 2.000 $core_inputs
set_input_delay -clock clk -min 0.500 $core_inputs

# 3. Output Delays (Assuming 20% external budget for memory & status pads)
set_output_delay -clock clk -max 2.000 [all_outputs]
set_output_delay -clock clk -min 0.500 [all_outputs]

# 4. Asynchronous and Quasi-Static False Paths
# External static hardware mode switch (SW0 / Pin)
set_false_path -from [get_ports tmr_mode_pin]

# Fault injection verification pins (used only during testbench/HIL emulation when present)
set fi_ports [get_ports -quiet {fi_reg_en fi_reg_addr* fi_reg_bit* fi_alu_en fi_alu_sel* fi_alu_bit*}]
if {[sizeof_collection $fi_ports] > 0} {
    set_false_path -from $fi_ports
}

# 5. Output Load and Driving Cell Constraints
# Standard 90nm standard cell buffer driver BUFX2 and 50fF output load
set non_clk_inputs [remove_from_collection [all_inputs] [get_ports clk]]
set_driving_cell -lib_cell BUFX2 $non_clk_inputs
set_load 0.050 [all_outputs]
