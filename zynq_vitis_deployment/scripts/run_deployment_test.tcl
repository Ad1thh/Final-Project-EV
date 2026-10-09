set script_dir [file normalize [file dirname [info script]]]
set base_dir [file normalize [file join $script_dir ".."]]
set bit_file [file join $base_dir "output" "fpga_top.bit"]
set elf_file [file join $base_dir "output" "zynq_uart_bridge.elf"]
set ps7_file [file join $base_dir "vitis_ws" "zynq_uart_bridge" "_ide" "psinit" "ps7_init.tcl"]

if {![file exists $ps7_file]} {
    set ps7_file [file join $base_dir "vitis_ws" "zybo_platform" "export" "zybo_platform" "hw" "sdt" "ps7_init.tcl"]
}

puts "=== Step 1: Connect ==="
connect

puts "=== Step 2: Ensure DAP is ready ==="
set cur_targets [targets]
puts "$cur_targets"
if {[string match "*APB AP transaction error*" $cur_targets]} {
    puts "DAP error detected, issuing rst -srst..."
    targets 1
    catch {rst -srst}
    after 1000
    puts [targets]
}

puts "=== Step 3: Halting cores ==="
targets -set -nocase -filter {name =~ "*Cortex-A9*#0"}
catch {stop}
puts "Core 0 state: [state]"
targets -set -nocase -filter {name =~ "*Cortex-A9*#1"}
catch {stop}

puts "=== Step 4: PS7 Init ==="
targets -set -nocase -filter {name =~ "*Cortex-A9*#0"}
rst -processor
source $ps7_file
ps7_init
puts "PS7 Init completed successfully."

puts "=== Step 5: Program FPGA ==="
targets -set -nocase -filter {name =~ "*xc7z010*"}
fpga $bit_file
puts "FPGA programming completed."

puts "=== Step 6: Level Shifters (ps7_post_config) ==="
targets -set -nocase -filter {name =~ "*Cortex-A9*#0"}
ps7_post_config
puts "ps7_post_config completed."

puts "=== Step 7: Download ELF ==="
dow $elf_file
puts "Download ELF completed."
puts "Current PC before resume: [rrd pc]"

puts "=== Step 8: Resume Execution ==="
con
after 500
puts "Current Core 0 state: [state]"
puts "Current PC: [rrd pc]"

puts "=== Deployment Complete ==="
exit
