# ============================================================================
# File: vitis_build_app_xsct.tcl
# Description: XSCT Batch Script for Vitis Classic Embedded Flow
# Usage: xsct scripts/vitis_build_app_xsct.tcl
# ============================================================================

set script_dir [file normalize [file dirname [info script]]]
set base_dir [file normalize [file join $script_dir ".."]]
set ws_dir [file join $base_dir "vitis_ws"]
set xsa_file [file join $base_dir "output" "system_wrapper.xsa"]
set c_source [file join $base_dir "vitis_app" "main.c"]

puts "=========================================================================="
puts "  STARTING XSCT EMBEDDED APPLICATION BUILD"
puts "=========================================================================="
puts " Workspace : $ws_dir"
puts " XSA Path  : $xsa_file"

setws $ws_dir

# 1. Create Hardware Platform
puts " === [1/4] Creating Platform from XSA..."
platform create -name "zybo_platform" -hw $xsa_file -proc "ps7_cortexa9_0" -os "standalone"
platform generate

# 2. Create Baremetal Application
puts " === [2/4] Creating Application Project 'zynq_uart_bridge'..."
app create -name "zynq_uart_bridge" -platform "zybo_platform" -domain "standalone_domain" -template "Empty Application(C)"

# 3. Import C Source
puts " === [3/4] Importing main.c into Application..."
importsources -name "zynq_uart_bridge" -path $c_source -soft-link

# 4. Build Application
puts " === [4/4] Compiling Application ELF..."
app build -name "zynq_uart_bridge"

puts "=========================================================================="
puts "  XSCT EMBEDDED BUILD COMPLETE!"
puts "=========================================================================="
