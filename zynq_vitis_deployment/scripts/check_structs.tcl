connect
targets -set -nocase -filter {name =~ "*Cortex-A9*#0"}
configparams force-mem-accesses 1
puts "=== Gpio struct at 0x80E4: ==="
puts [mrd 0x80E4 4]
puts "=== Uart struct at 0x8094: ==="
puts [mrd 0x8094 4]
exit
