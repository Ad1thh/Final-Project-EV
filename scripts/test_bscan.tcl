connect
jtag targets 3
set seq [jtag sequence]
$seq state RESET
$seq state IDLE
$seq irshift -state IDLE -hex 6 02
$seq drshift -state IDLE -capture -hex 64 0000000000000000
set res [$seq run -hex]
puts "BSCANE2 CAPTURE RESULT: $res"
$seq delete
