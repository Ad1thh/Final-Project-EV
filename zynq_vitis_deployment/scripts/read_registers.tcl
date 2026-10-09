connect
targets -set -nocase -filter {name =~ "*Cortex-A9*#0"}
catch {stop}
puts "=== Core 0 Status ==="
puts "State: [state]"
puts "PC: [rrd pc]"

puts "=== UART1 Status (0xE0001000) ==="
puts "SR (0xE000102C): [mrd 0xe000102c]"
puts "CR (0xE0001000): [mrd 0xe0001000]"

puts "=== AXI GPIO Status (0x41200000) ==="
puts "GPIO Ch1 Data (PS->PL): [mrd 0x41200000]"
puts "GPIO Ch1 Tri          : [mrd 0x41200004]"
puts "GPIO Ch2 Data (PL->PS): [mrd 0x41200008]"
puts "GPIO Ch2 Tri          : [mrd 0x4120000c]"

con
exit
