# ============================================================================
# File: program_fpga.tcl
# Description: Vivado Hardware Manager TCL Script to Flash Nexys 4 FPGA Board
# ============================================================================

set project_dir [file normalize [file join [file dirname [info script]] ".."]]
set bitstream_file [file join $project_dir "fpga" "fpga_top.bit"]

if {![file exists $bitstream_file]} {
    puts " === ERROR === Bitstream file not found: $bitstream_file"
    puts " Please run 'build_bitstream.tcl' first!"
    exit 1
}

puts "========================================================"
puts " === FPGA PROGRAM === Connecting to Vivado Hardware Server..."
puts "========================================================"

open_hw_manager
connect_hw_server -allow_non_jtag
open_hw_target

# Auto-select connected Artix-7 target device
set hw_device [lindex [get_hw_devices] 0]
current_hw_device $hw_device
refresh_hw_device -update_hw_probes false $hw_device

puts " === FPGA PROGRAM === Programming device: $hw_device"
puts " Bitstream: $bitstream_file"

set_property PROGRAM.FILE $bitstream_file $hw_device
program_hw_devices $hw_device
refresh_hw_device $hw_device

puts "========================================================"
puts " === FPGA PROGRAM SUCCESS === Bitstream Loaded onto FPGA!"
puts " Observe board LEDs for real-time validation results."
puts "========================================================"
close_hw_target
close_hw_manager
