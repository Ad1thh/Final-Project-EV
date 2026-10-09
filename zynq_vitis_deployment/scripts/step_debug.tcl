connect
targets -set -nocase -filter {name =~ "*Cortex-A9*#0"}
catch {stop}
rwr pc 0x100000

for {set i 0} {$i < 20} {incr i} {
    set cur_pc [rrd pc]
    puts "Step $i: PC = $cur_pc"
    if {[catch {stp} err]} {
        puts "Step error: $err"
        break
    }
}
exit
