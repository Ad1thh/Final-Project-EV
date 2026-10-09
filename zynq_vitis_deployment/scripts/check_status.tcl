connect
configparams force-mem-access 1
targets -set -nocase -filter {name =~ "*Cortex-A9*#0"}
puts "=== Core 0 State ==="
puts [state]
puts "=== Core 0 PC ==="
puts [rrd pc]
puts "=== UART1 Channel Status (0xE000102C) ==="
puts [mrd 0xE000102C]
puts "=== UART1 Control Reg (0xE0001000) ==="
puts [mrd 0xE0001000]
puts "=== UART1 Baud Rate Gen (0xE0001018) ==="
puts [mrd 0xE0001018]
puts "=== UART1 Baud Rate Div (0xE0001034) ==="
puts [mrd 0xE0001034]
puts "=== PCAP_STATUS (0xF8007014) ==="
puts [mrd 0xF8007014]
puts "=== SLCR Level Shifter EN (0xF8000900) ==="
puts [mrd 0xF8000900]
puts "=== AXI GPIO Ch 1 (To PL: 0x41200000) ==="
puts [mrd 0x41200000]
puts "=== AXI GPIO Ch 2 (From PL: 0x41200008) ==="
puts [mrd 0x41200008]
puts "=== Done ==="
exit
