connect
puts [jtag targets]
jtag targets 2
set seq [jtag sequence]
$seq irshift -state IDLE -hex 6 02
set r [$seq run]
puts "JTAG RUN RESULT: $r"
$seq delete
