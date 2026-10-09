connect
targets -set -nocase -filter {name =~ "*Cortex-A9*#0"}
configparams force-mem-accesses 1
puts "=== SLCR MIO_PIN_47 (0xF80007BC) ==="
puts [mrd 0xF80007BC 1]
puts "=== PS GPIO DATA_0 (0xE00A0040) / DATA_1 (0xE00A0044) ==="
puts [mrd 0xE00A0040 2]
puts "=== PS GPIO DIRM_1 (0xE00A0244) / OEN_1 (0xE00A0248) ==="
puts [mrd 0xE00A0244 2]
exit
