connect
targets -set -nocase -filter {name =~ "*Cortex-A9*#0"}
catch {stop}
puts "=== Memory at 0x00100000 ==="
puts [mrd 0x00100000 8]
exit
