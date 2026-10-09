set script_dir [file normalize [file dirname [info script]]]
set base_dir [file normalize [file join $script_dir ".."]]
set bit_file [file join $base_dir "output" "fpga_top.bit"]
set elf_file [file join $base_dir "output" "zynq_uart_bridge.elf"]
set ps7_file [file join $base_dir "vitis_ws" "zynq_uart_bridge" "_ide" "psinit" "ps7_init.tcl"]

if {![file exists $ps7_file]} {
    set ps7_file [file join $base_dir "vitis_ws" "zybo_platform" "export" "zybo_platform" "hw" "sdt" "ps7_init.tcl"]
}

connect
puts "Connected to hw_server."

targets -set -nocase -filter {name =~ "*Cortex-A9*#0"}
catch {stop}
targets -set -nocase -filter {name =~ "*Cortex-A9*#1"}
catch {stop}
puts "All A9 cores halted."

# 2. Reset processor with stop
targets -set -nocase -filter {name =~ "*Cortex-A9*#0"}
catch {rst -processor -stop -clear-registers}
targets -set -nocase -filter {name =~ "*Cortex-A9*#1"}
catch {rst -processor -stop -clear-registers}

# 3. ps7_init
targets -set -nocase -filter {name =~ "*Cortex-A9*#0"}
source $ps7_file
ps7_init
puts "ps7_init done."

# 4. Program FPGA
targets -set -nocase -filter {name =~ "*xc7z010*"}
fpga $bit_file
puts "FPGA programmed."

# 5. ps7_post_config
targets -set -nocase -filter {name =~ "*Cortex-A9*#0"}
ps7_post_config
puts "ps7_post_config done."

# 6. Download ELF
dow $elf_file
puts "ELF downloaded. Entry PC: [rrd pc]"

# 7. Start execution on Core 0 only
con
after 500
puts "Core 0 state: [state]"
puts "Core 0 PC: [rrd pc]"
targets -set -nocase -filter {name =~ "*Cortex-A9*#1"}
puts "Core 1 state: [state]"

exit
