connect
targets -set -nocase -filter {name =~ "*Cortex-A9*#0"}
puts "=== Core 0 Status ==="
puts "State: [state]"
if {[state] == "Running"} {
    stop
    puts "Stopped Core 0"
    puts "PC  : [rrd pc]"
    puts "SP  : [rrd sp]"
    puts "LR  : [rrd lr]"
    puts "CPSR: [rrd cpsr]"
    con
} else {
    puts "PC  : [rrd pc]"
    puts "SP  : [rrd sp]"
    puts "LR  : [rrd lr]"
    puts "CPSR: [rrd cpsr]"
}
exit
