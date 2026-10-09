set script_dir [file normalize [file dirname [info script]]]
set base_dir [file normalize [file join $script_dir ".."]]
set bit_file [file join $base_dir "output" "fpga_top.bit"]
set elf_file [file join $base_dir "output" "zynq_uart_bridge.elf"]
set ps7_file [file join $base_dir "vitis_ws" "zynq_uart_bridge" "_ide" "psinit" "ps7_init.tcl"]

connect

puts "=== [1/6] Generating Hardware SRST Pulse ==="
targets -set 1
rst -srst
after 1000

puts "=== [2/6] Initializing ARM Cortex-A9 and PS Clocks ==="
targets -set -nocase -filter {name =~ "*Cortex-A9*#0"}
rst -processor
source $ps7_file
ps7_init

puts "=== [3/6] Programming PL Bitstream ==="
targets -set -nocase -filter {name =~ "*xc7z010*"}
fpga $bit_file

puts "=== [4/6] Activating Level Shifters (ps7_post_config) ==="
targets -set -nocase -filter {name =~ "*Cortex-A9*#0"}
ps7_post_config

puts "=== [5/6] Downloading ELF ==="
dow $elf_file

puts "=== [6/6] Launching Execution ==="
con

puts "=== DEPLOYMENT COMPLETE AND RUNNING ==="
exit
