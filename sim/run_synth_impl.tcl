# ============================================================================
# Vivado TCL Script for Synthesis and Implementation (Artix-7 XC7A100T-1CSG324C)
# Target Top: riscv_core_top
# ============================================================================

set project_dir "C:/Main_Project/Final-Project-EV"
set output_dir "$project_dir/synth_impl_out"

file mkdir $output_dir

# Read SystemVerilog RTL Files in dependency order
read_verilog -sv "$project_dir/rtl/riscv_pkg.sv"
read_verilog -sv "$project_dir/rtl/clock_gater.sv"
read_verilog -sv "$project_dir/rtl/tmr_voter.sv"
read_verilog -sv "$project_dir/rtl/adaptive_redundancy_controller.sv"
read_verilog -sv "$project_dir/rtl/alu.sv"
read_verilog -sv "$project_dir/rtl/control_unit.sv"
read_verilog -sv "$project_dir/rtl/hazard_unit.sv"
read_verilog -sv "$project_dir/rtl/regfile.sv"
read_verilog -sv "$project_dir/rtl/if_stage.sv"
read_verilog -sv "$project_dir/rtl/id_ex_stage.sv"
read_verilog -sv "$project_dir/rtl/wb_stage.sv"
read_verilog -sv "$project_dir/rtl/riscv_core_top.sv"

# Set Target Device: Xilinx Artix-7 XC7A100T-1CSG324C
set_property part xc7a100tcsg324-1 [current_project]

# Step 1: Synthesis in Out-Of-Context (OOC) mode
puts "========================================================================="
puts "                     STEP 1: SYNTHESIS (OOC MODE)                        "
puts "========================================================================="
synth_design -top riscv_core_top -part xc7a100tcsg324-1 -mode out_of_context -flatten_hierarchy rebuilt

write_checkpoint -force "$output_dir/post_synth.dcp"
report_utilization -file "$output_dir/post_synth_utilization.rpt"

# Define 25MHz clock constraint (40ns period) suitable for Artix-7 -1 speed grade soft-core with TMR voting
create_clock -name clk -period 40.000 [get_ports clk]
set_input_delay -clock clk 5.000 [all_inputs]
set_output_delay -clock clk 5.000 [all_outputs]

# Step 2: Logic Optimization
puts "========================================================================="
puts "                     STEP 2: OPT DESIGN                                  "
puts "========================================================================="
opt_design

# Step 3: Placement
puts "========================================================================="
puts "                     STEP 3: PLACE DESIGN                                "
puts "========================================================================="
place_design

# Step 4: Physical Optimization
puts "========================================================================="
puts "                     STEP 4: PHYS OPT DESIGN                             "
puts "========================================================================="
phys_opt_design

# Step 5: Routing
puts "========================================================================="
puts "                     STEP 5: ROUTE DESIGN                                "
puts "========================================================================="
route_design

write_checkpoint -force "$output_dir/post_route.dcp"

# Step 6: Timing, DRC, Power, Utilization Reports
puts "========================================================================="
puts "                     STEP 6: GENERATING REPORTS                          "
puts "========================================================================="
report_timing_summary -file "$output_dir/post_route_timing.rpt"
report_drc -file "$output_dir/post_route_drc.rpt"
report_power -file "$output_dir/post_route_power.rpt"
report_utilization -file "$output_dir/post_route_utilization.rpt"

puts "========================================================================="
puts "             SYNTHESIS & IMPLEMENTATION COMPLETED SUCCESSFULLY!          "
puts "========================================================================="
exit 0
