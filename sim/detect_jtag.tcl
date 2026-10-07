open_hw_manager
connect_hw_server -url localhost:3121
puts "========================================================================="
puts "                       DETECTING HARDWARE TARGETS                        "
puts "========================================================================="
if {[catch {open_hw_target} err]} {
    puts "ERROR opening hw_target: $err"
} else {
    puts "HW_TARGET: [current_hw_target]"
    puts "HW_DEVICES: [get_hw_devices]"
    foreach dev [get_hw_devices] {
        puts "  -> Found Device: $dev ([get_property PART $dev])"
    }
}
close_hw_target
disconnect_hw_server
close_hw_manager
exit 0
