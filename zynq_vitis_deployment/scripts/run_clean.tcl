connect
targets -set -nocase -filter {name =~ "*Cortex-A9*#0"}
catch {bpremove -all}
rwr pc 0x0
con
after 500
puts "State: [state]"
puts "PC   : [rrd pc]"
exit
