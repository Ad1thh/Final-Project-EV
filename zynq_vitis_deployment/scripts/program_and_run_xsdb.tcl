# ============================================================================
# File: program_and_run_xsdb.tcl
# Description: Robust XSDB Hardware Deployment Script for Digilent Zybo
# Usage: xsdb scripts/program_and_run_xsdb.tcl
# ============================================================================

set script_dir [file normalize [file dirname [info script]]]
set base_dir [file normalize [file join $script_dir ".."]]
set bit_file [file join $base_dir "output" "fpga_top.bit"]
set elf_file [file join $base_dir "output" "zynq_uart_bridge.elf"]
set ps7_file [file join $base_dir "vitis_ws" "zynq_uart_bridge" "_ide" "psinit" "ps7_init.tcl"]

if {![file exists $ps7_file]} {
    set ps7_file [file join $base_dir "vitis_ws" "zybo_platform" "export" "zybo_platform" "hw" "sdt" "ps7_init.tcl"]
}

puts "=========================================================================="
puts "  STARTING XSDB HARDWARE INITIALIZATION & DEPLOYMENT"
puts "=========================================================================="
puts " Bitstream : $bit_file"
puts " ELF File  : $elf_file"
puts " PS7 Init  : $ps7_file"

# 1. Connect to Hardware Server
connect
configparams force-mem-access 1

# 2. Check DAP Health and Assert Reset
targets 1
catch {rst -srst}
after 50

# 3. Halt All Cores Immediately (Prevent QSPI Linux / U-Boot execution)
puts " === [1/6] Halting Cortex-A9 Cores..."
targets -set -nocase -filter {name =~ "*Cortex-A9*#0"}
catch {stop}
targets -set -nocase -filter {name =~ "*Cortex-A9*#1"}
catch {stop}

# 4. Reset Processors in stopped state
targets -set -nocase -filter {name =~ "*Cortex-A9*#0"}
catch {rst -processor -stop -clear-registers}
targets -set -nocase -filter {name =~ "*Cortex-A9*#1"}
catch {rst -processor -stop -clear-registers}

# 5. Initialize PS (ARM Cortex-A9 & Clocks)
puts " === [2/6] Initializing Processing System (ps7_init)..."
targets -set -nocase -filter {name =~ "*Cortex-A9*#0"}
source $ps7_file
ps7_init

# 6. Program PL Bitstream
puts " === [3/6] Programming PL Bitstream ($bit_file)..."
targets -set -nocase -filter {name =~ "*xc7z010*"}
fpga $bit_file

# 7. Post-Config Level Shifters
puts " === [4/6] Level Shifter Post-Config..."
targets -set -nocase -filter {name =~ "*Cortex-A9*#0"}
if {[catch {ps7_post_config} err]} {
    puts " [INFO] ps7_post_config warning ($err), writing SLCR level shifters directly..."
    catch {mwr 0xF8000008 0xDF0D}
    catch {mwr 0xF8000900 0xF}
    catch {mwr 0xF8000004 0x767B}
}

# 8. Download Application
puts " === [5/6] Downloading Application ELF ($elf_file)..."
dow $elf_file

# 9. Start Core 0 Only
puts " === [6/6] Resuming Cortex-A9 #0 Execution..."
con
after 500
puts " Core 0 Status: [state]"

puts "=========================================================================="
puts "  HARDWARE DEPLOYMENT COMPLETE! PS UART & PL ARE LIVE ON COM PORT AT 115200"
puts "=========================================================================="
exit
