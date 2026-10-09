connect
targets
targets -set -nocase -filter {name =~ "*Cortex-A9*#0"}
puts "=== Core 0 State ==="
puts [state]
exit
