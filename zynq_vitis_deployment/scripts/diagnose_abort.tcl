connect
targets -set -nocase -filter {name =~ "*Cortex-A9*#0"}
catch {stop}
puts "=== Core 0 State: [state] ==="
puts "PC   : [rrd pc]"
puts "LR   : [rrd lr]"
puts "SP   : [rrd sp]"
puts "CPSR : [rrd cpsr]"
puts "=== All Registers ==="
puts [rrd]
exit
