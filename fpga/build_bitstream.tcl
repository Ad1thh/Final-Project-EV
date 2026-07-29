# ============================================================================
# File: build_bitstream.tcl
# Description: Vivado Batch TCL Script for Automated Bitstream Generation
# Target Board: Xilinx Nexys 4 (Artix-7 XC7A100T-1CSG324C)
# ============================================================================

set project_dir [file normalize [file join [file dirname [info script]] ".."]]
cd $project_dir

puts "========================================================"
puts " === FPGA BUILD === Starting Non-Interactive Vivado Synthesis"
puts "========================================================"

# 1. Read SystemVerilog RTL Sources
read_verilog -sv [glob rtl/*.sv]
read_verilog -sv fpga/fpga_top.sv

# 2. Read Target Board Constraints
read_xdc constraints/nexys4.xdc

# 3. Synthesize Design
puts " === FPGA BUILD === Running synth_design (Target: xc7a100tcsg324-1)..."
synth_design -top fpga_top -part xc7a100tcsg324-1 -flatten_hierarchy rebuilt

# 4. Optimization & Placement
puts " === FPGA BUILD === Running opt_design & place_design..."
opt_design
place_design

# 5. Routing
puts " === FPGA BUILD === Running route_design..."
route_design

# 6. Generate Bitstream
set bitstream_path [file join $project_dir "fpga" "fpga_top.bit"]
puts " === FPGA BUILD === Writing bitstream to: $bitstream_path"
write_bitstream -force $bitstream_path

# 7. Summary & Reports
report_utilization -file fpga/utilization_report.txt
report_timing_summary -file fpga/timing_report.txt

puts "========================================================"
puts " === FPGA BUILD SUCCESS === Bitstream Generated Successfully!"
puts " Output: $bitstream_path"
puts "========================================================"
