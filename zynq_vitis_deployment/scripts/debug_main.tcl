set base_dir [file normalize [file join [file dirname [info script]] ".."]]
set elf_file [file join $base_dir "output" "zynq_uart_bridge.elf"]

connect
targets -set 1
catch {rst -dap}
after 500

targets -set -nocase -filter {name =~ "*Cortex-A9*#0"}
rst -processor

puts "=== Downloading ELF ==="
dow $elf_file

puts "=== Setting Breakpoint at main ==="
bpadd -addr &main
con
after 500

puts "=== Target State after running to main ==="
puts [state]
puts "=== PC ==="
puts [rrd pc]

puts "=== Single stepping ==="
catch {stpi}
puts [state]
puts [rrd pc]

catch {stpi}
puts [state]
puts [rrd pc]

bpremove -all
exit
