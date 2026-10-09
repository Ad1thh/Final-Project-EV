# ============================================================================
# File: build_bitstream.tcl
# Description: Vivado TCL Script for Zynq-7000 SoC Block Design + RISC-V PL
# Target Board: Digilent Zybo (Zynq-7000 XC7Z010-1CLG400C)
# ============================================================================

set project_dir [file normalize [file join [file dirname [info script]] ".."]]
cd $project_dir

set part_name "xc7z010clg400-1"
set proj_name "zynq_soc"
set proj_path [file join $project_dir "fpga" $proj_name]

puts "========================================================"
puts " === FPGA BUILD === Creating Vivado SoC Project ($part_name)"
puts "========================================================"

create_project -force $proj_name $proj_path -part $part_name

# 1. Add SystemVerilog Sources
add_files [glob rtl/*.sv]
add_files [glob fpga/*.sv]

# 2. Add Constraints
add_files -fileset constrs_1 constraints/zybo_z7.xdc

# 3. Create Zynq PS + AXI GPIO Block Design
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

# 4. Generate BD Targets and Wrapper
puts " === FPGA BUILD === Generating Block Design Targets..."
generate_target all [get_files [file join $proj_path "$proj_name.srcs" "sources_1" "bd" "system" "system.bd"]]
make_wrapper -files [get_files [file join $proj_path "$proj_name.srcs" "sources_1" "bd" "system" "system.bd"]] -top
add_files -norecurse [file join $proj_path "$proj_name.srcs" "sources_1" "bd" "system" "hdl" "system_wrapper.v"]
update_compile_order -fileset sources_1

# Set Top Module
set_property top fpga_top [current_fileset]
update_compile_order -fileset sources_1

# 5. Run Synthesis, Implementation, and Bitstream Generation
puts " === FPGA BUILD === Running Synthesis and Implementation..."
launch_runs impl_1 -to_step write_bitstream -jobs 8
wait_on_run impl_1

if {[get_property PROGRESS [get_runs impl_1]] != "100%"} {
    puts " === ERROR === Implementation failed!"
    exit 1
}

# 6. Copy Bitstream & Export Hardware (XSA)
set generated_bit [file join $proj_path "$proj_name.runs" "impl_1" "fpga_top.bit"]
set target_bit [file join $project_dir "fpga" "fpga_top.bit"]
set target_xsa [file join $project_dir "fpga" "system_wrapper.xsa"]

file copy -force $generated_bit $target_bit
puts " === FPGA BUILD === Copied bitstream to: $target_bit"

puts " === FPGA BUILD === Exporting Hardware XSA to: $target_xsa"
write_hw_platform -fixed -include_bit -force -file $target_xsa

puts "========================================================"
puts " === FPGA BUILD SUCCESS === SoC Flow Completed!"
puts "========================================================"
