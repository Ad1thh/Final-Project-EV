set script_dir [file normalize [file dirname [info script]]]
set base_dir [file normalize [file join $script_dir ".."]]
set bit_file [file join $base_dir "output" "fpga_top.bit"]
set elf_file [file join $base_dir "output" "zynq_uart_bridge.elf"]
set ps7_file [file join $base_dir "vitis_ws" "zynq_uart_bridge" "_ide" "psinit" "ps7_init.tcl"]

if {![file exists $ps7_file]} {
    set ps7_file [file join $base_dir "vitis_ws" "zybo_platform" "export" "zybo_platform" "hw" "sdt" "ps7_init.tcl"]
}

connect
puts "=== [1] Halting Cores ==="
targets -set -nocase -filter {name =~ "*Cortex-A9*#0"}
catch {stop}
targets -set -nocase -filter {name =~ "*Cortex-A9*#1"}
catch {stop}

puts "=== [2] Processor Reset (No SRST) ==="
targets -set -nocase -filter {name =~ "*Cortex-A9*#0"}
catch {rst -processor -stop -clear-registers}
targets -set -nocase -filter {name =~ "*Cortex-A9*#1"}
catch {rst -processor -stop -clear-registers}

puts "=== [3] ps7_init ==="
targets -set -nocase -filter {name =~ "*Cortex-A9*#0"}
source $ps7_file
ps7_init

puts "=== [4] Program FPGA ==="
targets -set -nocase -filter {name =~ "*xc7z010*"}
fpga $bit_file

puts "=== [5] Post Config ==="
targets -set -nocase -filter {name =~ "*Cortex-A9*#0"}
ps7_post_config

puts "=== [6] Download and Launch ELF ==="
dow $elf_file
puts "Entry PC: [rrd pc]"
con

after 500
puts "Final Core 0 State: [state]"
puts "Final Core 0 PC: [rrd pc]"
exit
