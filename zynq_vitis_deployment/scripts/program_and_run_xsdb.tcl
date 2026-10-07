# ============================================================================
# File: program_and_run_xsdb.tcl
# Description: XSDB Hardware Target Programming & Execution Script for Zybo
# Usage: xsdb scripts/program_and_run_xsdb.tcl
# ============================================================================

set script_dir [file normalize [file dirname [info script]]]
set base_dir [file normalize [file join $script_dir ".."]]
set bit_file [file join $base_dir "output" "fpga_top.bit"]

# Locate generated ELF
set elf_file ""
set candidates [list \
    [file join $base_dir "vitis_ws" "zynq_uart_bridge" "build" "zynq_uart_bridge.elf"] \
    [file join $base_dir "vitis_ws" "zynq_uart_bridge" "Debug" "zynq_uart_bridge.elf"] \
    [file join $base_dir "vitis_ws" "zynq_uart_bridge" "Release" "zynq_uart_bridge.elf"] \
]

foreach c $candidates {
    if {[file exists $c]} {
        set elf_file $c
        break
    }
}

puts "=========================================================================="
puts "  STARTING XSDB HARDWARE INITIALIZATION & DEPLOYMENT"
puts "=========================================================================="
puts " Bitstream : $bit_file"
puts " ELF File  : $elf_file"

# 1. Connect to Hardware Server
connect -url localhost:3121

# 2. Reset and Program FPGA PL
puts " === [1/5] Selecting JTAG Target Device..."
targets -set -nocase -filter {name =~ "*xc7z010*"}

puts " === [2/5] Programming PL Bitstream ($bit_file)..."
fpga $bit_file

# 3. Initialize PS (ARM Cortex-A9)
puts " === [3/5] Initializing ARM Cortex-A9 Core 0..."
targets -set -nocase -filter {name =~ "*Cortex-A9*#0"}
rst -srst

# Source ps7_init if available
set ps7_init_file [file join $base_dir "vitis_ws" "zybo_platform" "export" "zybo_platform" "sw" "zybo_platform" "standalone_domain" "bsp" "ps7_cortexa9_0" "libsrc" "standalone" "src" "ps7_init.tcl"]
if {[file exists $ps7_init_file]} {
    puts " Sourcing ps7_init.tcl..."
    source $ps7_init_file
    ps7_init
    ps7_post_config
}

# 4. Download and Run Application
if {$elf_file ne "" && [file exists $elf_file]} {
    puts " === [4/5] Downloading Application ELF ($elf_file)..."
    dow $elf_file
    puts " === [5/5] Resuming Cortex-A9 Execution..."
    con
} else {
    puts " [NOTICE] No ELF found to download. If you only wanted to flash PL bitstream, execution is live."
}

puts "=========================================================================="
puts "  HARDWARE DEPLOYMENT COMPLETE! PS UART & PL ARE LIVE ON COM PORT AT 115200"
puts "=========================================================================="
