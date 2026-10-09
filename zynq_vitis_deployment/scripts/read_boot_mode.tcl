connect
targets -set -nocase -filter {name =~ "*APU*"}
puts "=== BOOT_MODE via AP0 (AHB-AP) ==="
puts [mrd -address-space AP0 0xf800025c]
exit
