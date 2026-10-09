connect
targets -set -nocase -filter {name =~ "*Cortex-A9*#0"}
stop
puts "=== PC Register ==="
puts [rrd pc]
puts "=== Backtrace ==="
catch {puts [bt]} err_bt
con
exit
