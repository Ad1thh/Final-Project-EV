connect
configparams force-mem-access 1
targets -set -nocase -filter {name =~ "*Cortex-A9*#0"}
puts "=== Memory at 0x000004a0 ==="
puts [mrd 0x000004a0 8]
puts "=== Memory at 0x00000000 ==="
puts [mrd 0x00000000 8]
puts "=== Memory at 0x00100000 (DDR) ==="
puts [mrd 0x00100000 8]
exit
