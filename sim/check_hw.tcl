open_hw_manager
connect_hw_server -url localhost:3121
open_hw_target
puts "TARGET: [current_hw_target]"
foreach dev [get_hw_devices] {
    puts "DEVICE: $dev | PART: [get_property PART $dev]"
}
close_hw_target
close_hw_manager
