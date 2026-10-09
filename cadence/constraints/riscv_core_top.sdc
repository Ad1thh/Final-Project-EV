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
set core_inputs [remove_from_collection [all_inputs] [get_ports {clk rst_n tmr_mode_pin fi_reg_en fi_reg_addr fi_reg_bit fi_alu_en fi_alu_sel fi_alu_bit}]]
set_input_delay -clock clk -max 2.000 $core_inputs
set_input_delay -clock clk -min 0.500 $core_inputs

# 3. Output Delays (Assuming 20% external budget for memory & status pads)
set_output_delay -clock clk -max 2.000 [all_outputs]
set_output_delay -clock clk -min 0.500 [all_outputs]

# 4. Asynchronous and Quasi-Static False Paths
# Active-low asynchronous reset
set_false_path -from [get_ports rst_n]

# External static hardware mode switch (SW0 / Pin)
set_false_path -from [get_ports tmr_mode_pin]

# Fault injection verification pins (used only during testbench/HIL emulation)
set_false_path -from [get_ports {fi_reg_en fi_reg_addr* fi_reg_bit* fi_alu_en fi_alu_sel* fi_alu_bit*}]

# 5. Output Load and Driving Cell Defaults
# (Can be overridden by standard cell library specific buffers in run_genus_syn.tcl)
set_load 0.050 [all_outputs]
