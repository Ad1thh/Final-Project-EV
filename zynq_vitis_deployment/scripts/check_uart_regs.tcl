connect
targets -set -nocase -filter {name =~ "*Cortex-A9*#0"}
configparams force-mem-accesses 1
puts "=== Full UART1 Regs (0xE0001000 - 0xE0001034) ==="
puts [mrd 0xE0001000 14]
exit
