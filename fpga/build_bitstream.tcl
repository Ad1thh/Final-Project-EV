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
read_verilog -sv [glob fpga/*.sv]

# 2. Read Target Board Constraints
read_xdc constraints/zybo_z7.xdc

# 3. Create Zynq Block Design for USB-UART Bridge
puts " === FPGA BUILD === Creating Zynq Block Design..."
create_bd_design "system"
create_bd_cell -type ip -vlnv xilinx.com:ip:processing_system7:5.5 processing_system7_0
apply_bd_automation -rule xilinx.com:bd_rule:processing_system7 -config {make_external "FIXED_IO, DDR" apply_board_preset "1" Master "Disable" Slave "Disable" }  [get_bd_cells processing_system7_0]

create_bd_cell -type ip -vlnv xilinx.com:ip:axi_gpio:2.0 axi_gpio_0
set_property -dict [list CONFIG.C_ALL_OUTPUTS {1} CONFIG.C_IS_DUAL {1} CONFIG.C_ALL_INPUTS_2 {1}] [get_bd_cells axi_gpio_0]

apply_bd_automation -rule xilinx.com:bd_rule:axi4 -config { Clk_master {Auto} Clk_slave {Auto} Clk_xbar {Auto} Master {/processing_system7_0/M_AXI_GP0} Slave {/axi_gpio_0/S_AXI} ddr_seg {Auto} intc_ip {New AXI Interconnect} master_apm {0}}  [get_bd_intf_pins axi_gpio_0/S_AXI]

make_bd_intf_pins_external  [get_bd_intf_pins axi_gpio_0/GPIO]
set_property name gpio_from_ps [get_bd_intf_ports GPIO_0]
make_bd_intf_pins_external  [get_bd_intf_pins axi_gpio_0/GPIO2]
set_property name gpio_to_ps [get_bd_intf_ports GPIO2_0]

save_bd_design
make_wrapper -files [get_files system.bd] -top
add_files -norecurse [file join [file dirname [get_property file_name [get_bd_designs system]]] "hdl" "system_wrapper.v"]
update_compile_order -fileset sources_1

# 4. Synthesize Design
puts " === FPGA BUILD === Running synth_design (Target: xc7z020clg400-1)..."
synth_design -top fpga_top -part xc7z020clg400-1 -flatten_hierarchy rebuilt

# 4. Optimization & Placement
puts " === FPGA BUILD === Running opt_design & place_design..."
opt_design
place_design

# 6. Routing
puts " === FPGA BUILD === Running route_design..."
route_design

# 7. Export Hardware for Vitis
set xsa_path [file join $project_dir "fpga" "system_wrapper.xsa"]
puts " === FPGA BUILD === Exporting Hardware to: $xsa_path"
write_hw_platform -fixed -include_bit -force -file $xsa_path

# 8. Generate Bitstream
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
