wconnect
targets -set -nocase -filter {name =~ "*Cortex-A9*#0"}
configparams force-mem-accesses 1
puts "=== Current 0x41200000: ==="
puts [mrd 0x41200000 1]
puts "=== Writing 0x000001AA to 0x41200000 ==="
mwr 0x41200000 0x000001AA
puts "=== Readback 0x41200000: ==="
puts [mrd 0x41200000 1]
puts "=== Readback Channel 2 (0x41200008): ==="
puts [mrd 0x41200008 1]
exit
