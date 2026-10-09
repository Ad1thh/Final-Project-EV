connect
targets -set -nocase -filter {name =~ "*Cortex-A9*#0"}
configparams force-mem-accesses 1
puts "=== Core 0 State: [state] ==="
puts "=== Memory at 0x480 ==="
puts [mrd 0x480 24]
exit
