connect
targets -set -filter {name =~ "*Cortex-A9*#0"}
configparams force-mem-access 1
puts "=== AXI GPIO REGS (0x41200000) ==="
puts [mrd 0x41200000 4]
puts "=== UART1 REGS (0xE0001000) ==="
puts [mrd 0xE0001000 16]
puts "=== CPU REGS ==="
puts [rrd]
disconnect
exit
