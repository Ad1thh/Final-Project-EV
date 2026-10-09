# ============================================================================
# File: build_soc_bitstream.tcl
# Description: Automated Vivado TCL script for Zynq-7000 PS + RISC-V PL SoC
# Target: Digilent Zybo / Zybo Z7 (XC7Z010-1CLG400C)
# Usage: vivado -mode batch -source scripts/build_soc_bitstream.tcl
# ============================================================================

set script_dir [file normalize [file dirname [info script]]]
set base_dir [file normalize [file join $script_dir ".."]]
cd $base_dir

# Enable maximum performance / multi-threading across CPU cores (8 threads max in Vivado engine)
set_param general.maxThreads 8

set part_name "xc7z010clg400-1"
set proj_name "zybo_soc_proj"
set proj_dir  [file join $base_dir "vivado_output" $proj_name]
set proj_file [file join $proj_dir "$proj_name.xpr"]

puts "=========================================================================="
puts "  STARTING VIVADO ZYNQ SOC BITSTREAM GENERATION ($part_name)"
puts "  Maximum Performance: maxThreads = 8, Parallel Jobs = 12"
puts "=========================================================================="

file mkdir [file join $base_dir "output"]

# Ensure firmware.hex exists at all expected runtime paths
if {[file exists firmware/firmware.hex]} {
    file copy -force firmware/firmware.hex [file join $base_dir "firmware.hex"]
}

if {[file exists $proj_file]} {
    puts " === (FAST INCREMENTAL BUILD) Opening existing project: $proj_file"
    open_project $proj_file
    set_param general.maxThreads 8
    
    # Ensure source files are re-read
    update_compile_order -fileset sources_1
    set_property top fpga_top [current_fileset]
    
    puts " === Resetting synthesis and implementation for rapid multi-threaded rebuild..."
    reset_run synth_1
    reset_run impl_1
    
    puts " === [1/2] Launching Synthesis with 12 parallel jobs..."
    launch_runs synth_1 -jobs 12
    wait_on_run synth_1
    if {[get_property PROGRESS [get_runs synth_1]] != "100%"} {
        puts " === ERROR === Synthesis failed! Check Vivado log."
        exit 1
    }
    
    puts " === [2/2] Launching Implementation to Bitstream with 12 parallel jobs..."
    launch_runs impl_1 -to_step write_bitstream -jobs 12
    wait_on_run impl_1
    if {[get_property PROGRESS [get_runs impl_1]] != "100%"} {
        puts " === ERROR === Bitstream generation failed! Check Vivado log."
        exit 1
    }

} else {
    # 1. Create Project
    create_project -force $proj_name $proj_dir -part $part_name

    # 2. Add SystemVerilog RTL and FPGA Sources
    add_files [glob rtl/*.sv]
    add_files [glob fpga/*.sv]
    if {[file exists firmware/firmware.hex]} {
        add_files firmware/firmware.hex
    }

    # 3. Add Zybo Board Constraints
    add_files -fileset constrs_1 constraints/zybo_z7.xdc

    # 4. Create Block Design
    puts " === [1/5] Constructing Zynq Processing System & AXI GPIO Block Design..."
    create_bd_design "system"

    create_bd_cell -type ip -vlnv xilinx.com:ip:processing_system7:5.5 processing_system7_0

    # Configure Processing System 7
    set_property -dict [list \
        CONFIG.PCW_CRYSTAL_PERIPHERAL_FREQMHZ {50.000000} \
        CONFIG.PCW_PRESET_BANK1_VOLTAGE {LVCMOS 1.8V} \
        CONFIG.PCW_APU_PERIPHERAL_FREQMHZ {650} \
        CONFIG.PCW_USE_M_AXI_GP0 {1} \
        CONFIG.PCW_EN_CLK0_PORT {1} \
        CONFIG.PCW_FPGA0_PERIPHERAL_FREQMHZ {50} \
        CONFIG.PCW_UART1_PERIPHERAL_ENABLE {1} \
        CONFIG.PCW_UART1_UART1_IO {MIO 48 .. 49} \
        CONFIG.PCW_UART1_BAUD_RATE {115200} \
        CONFIG.PCW_UIPARAM_DDR_ENABLE {1} \
        CONFIG.PCW_USE_FABRIC_INTERRUPT {0} \
    ] [get_bd_cells processing_system7_0]

    apply_bd_automation -rule xilinx.com:bd_rule:processing_system7 -config {make_external "FIXED_IO, DDR" apply_board_preset "1" Master "Disable" Slave "Disable" }  [get_bd_cells processing_system7_0]

    # Add AXI GPIO for Fast Inter-Processor Communication
    create_bd_cell -type ip -vlnv xilinx.com:ip:axi_gpio:2.0 axi_gpio_0
    set_property -dict [list \
        CONFIG.C_ALL_OUTPUTS {1} \
        CONFIG.C_IS_DUAL {1} \
        CONFIG.C_ALL_INPUTS_2 {1} \
        CONFIG.C_GPIO_WIDTH {32} \
        CONFIG.C_GPIO2_WIDTH {32} \
    ] [get_bd_cells axi_gpio_0]

    apply_bd_automation -rule xilinx.com:bd_rule:axi4 -config { Clk_master {Auto} Clk_slave {Auto} Clk_xbar {Auto} Master {/processing_system7_0/M_AXI_GP0} Slave {/axi_gpio_0/S_AXI} ddr_seg {Auto} intc_ip {New AXI Interconnect} master_apm {0}}  [get_bd_intf_pins axi_gpio_0/S_AXI]

    make_bd_intf_pins_external  [get_bd_intf_pins axi_gpio_0/GPIO]
    set_property name gpio_from_ps [get_bd_intf_ports GPIO_0]
    make_bd_intf_pins_external  [get_bd_intf_pins axi_gpio_0/GPIO2]
    set_property name gpio_to_ps [get_bd_intf_ports GPIO2_0]

    create_bd_port -dir O -type clk fclk_clk0
    connect_bd_net [get_bd_pins processing_system7_0/FCLK_CLK0] [get_bd_ports fclk_clk0]

    save_bd_design

    # 5. Generate Block Design Wrapper
    puts " === [2/5] Generating Block Design Wrapper..."
    generate_target all [get_files [file join $proj_dir "$proj_name.srcs" "sources_1" "bd" "system" "system.bd"]]
    make_wrapper -files [get_files [file join $proj_dir "$proj_name.srcs" "sources_1" "bd" "system" "system.bd"]] -top
    add_files -norecurse [file join $proj_dir "$proj_name.srcs" "sources_1" "bd" "system" "hdl" "system_wrapper.v"]
    update_compile_order -fileset sources_1

    # Set Top Module
    set_property top fpga_top [current_fileset]
    update_compile_order -fileset sources_1

    # 6. Run Synthesis & Implementation
    puts " === [3/5] Running Synthesis with 12 parallel jobs..."
    launch_runs synth_1 -jobs 12
    wait_on_run synth_1

    if {[get_property PROGRESS [get_runs synth_1]] != "100%"} {
        puts " === ERROR === Synthesis failed! Check Vivado log."
        exit 1
    }

    puts " === [4/5] Running Implementation with 12 parallel jobs..."
    launch_runs impl_1 -to_step write_bitstream -jobs 12
    wait_on_run impl_1

    if {[get_property PROGRESS [get_runs impl_1]] != "100%"} {
        puts " === ERROR === Bitstream generation failed! Check Vivado log."
        exit 1
    }
}

# Export Outputs
set generated_bit [file join $proj_dir "$proj_name.runs" "impl_1" "fpga_top.bit"]
set out_bit [file join $base_dir "output" "fpga_top.bit"]
set out_xsa [file join $base_dir "output" "system_wrapper.xsa"]

file copy -force $generated_bit $out_bit
puts " === Copied bitstream to: $out_bit"

puts " === Exporting Hardware Platform (.xsa) for Vitis..."
write_hw_platform -fixed -include_bit -force -file $out_xsa
puts " Hardware Platform generated at: $out_xsa"

puts "=========================================================================="
puts "  VIVADO SOC BUILD SUCCESSFUL! (12 parallel jobs)"
puts "=========================================================================="
exit
