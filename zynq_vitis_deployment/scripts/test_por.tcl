connect
targets 1
puts "=== Pulsing POR (Power-on Reset) ==="
catch {rst -por}
after 1000
puts "=== Targets after POR ==="
puts [targets]
exit
