connect
targets 1
catch {rst -srst}
after 1000
puts "=== Targets After srst ==="
puts [targets]
exit
