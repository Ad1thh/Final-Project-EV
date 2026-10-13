open_hw_manager
connect_hw_server -allow_non_jtag
puts "HW SERVERS: [get_hw_servers]"
open_hw_target
puts "HW TARGET: [current_hw_target]"
set dev [get_hw_devices xc7z010_1]
current_hw_device $dev
puts "TARGET DEVICE: $dev"
set bitfile [file normalize "fpga/fpga_top.bit"]
puts "PROGRAMMING FILE: $bitfile"
set_property PROGRAM.FILE $bitfile $dev
program_hw_devices $dev
puts " === FPGA PROGRAM SUCCESS === Digilent ZYBO xc7z010 programmed successfully!"
close_hw_target
disconnect_hw_server
close_hw_manager
exit 0
