
connect

# Select JTAG target for PL (xc7z010)
jtag targets 3
set seq [jtag sequence]
$seq state RESET
$seq state IDLE
$seq irshift -state IDLE -hex 6 02

proc send_pkt {bytes} {
    set mwr_cmds [list]
    foreach b $bytes {
        lappend mwr_cmds "mwr -address-space AP0 0xE0001030 $b"
    }
    targets 1
    catch {eval [join $mwr_cmds "; "]}
    jtag targets 3
}

set last_seq ""
set last_sw -1
set last_btn 0
set hb_time [clock seconds]

# Initial Heartbeat
send_pkt {170 4 0 0 255 0 0 0 15 0 0 0 1 85}
puts ">>> INITIAL HEARTBEAT TRANSMITTED TO MIO48 / COM10 <<<"

while {1} {
    $seq drshift -state IDLE -capture -hex 64 0000000000000000
    set res [$seq run -hex]
    
    if {[string length $res] >= 16} {
        set sync [string range $res 14 15]
        set evt  [string range $res 12 13]
        set sw_btn [string range $res 10 11]
        set flags  [string range $res 8 9]
        set seq_num [string range $res 0 7]

        if {$sync == "a5"} {
            scan $sw_btn "%x" sw_btn_val
            set sw  [expr {($sw_btn_val >> 4) & 0xF}]
            set btn [expr {$sw_btn_val & 0xF}]

            scan $flags "%x" flag_val
            set treg [expr {$flag_val & 0xF}]
            if {$treg == 0} { set treg 3 }

            # 1. Physical Button Pressed
            if {$btn != 0 && $btn != $last_btn} {
                set last_btn $btn
                puts "\[PHYSICAL PIN EVENT\] Button BTN Pressed: $btn | Switches: $sw"

                if {$btn == 1} {
                    # BTN1 = SEC (Single Error Correction)
                    puts "  --> Transmitting SEC frame (Register x$treg, Bit 3, Corrected: 40, Raw: 8)"
                    send_pkt [list 170 1 $treg 3 255 0 0 0 40 0 0 0 8 85]
                } elseif {$btn == 2} {
                    # BTN2 = DED (Double Error Detection)
                    puts "  --> Transmitting DED frame (Register x$treg, Bit 0, Raw: 0xDEADBEEF)"
                    send_pkt [list 170 2 $treg 0 255 0 0 0 0 222 173 190 239 85]
                } elseif {$btn == 4} {
                    # BTN3 = TMR Mismatch & Recovery
                    puts "  --> Transmitting TMR Recovery frame (ALU Instance 1, Corrected: 25, Raw: 27)"
                    send_pkt [list 170 3 0 2 1 0 0 0 25 0 0 0 27 85]
                }
            } elseif {$btn == 0} {
                set last_btn 0
            }

            # 2. Physical Switch SW0 Toggled (Mode Change)
            set cur_sw0 [expr {$sw & 1}]
            if {$cur_sw0 != $last_sw && $last_sw != -1} {
                set last_sw $cur_sw0
                puts "\[PHYSICAL PIN EVENT\] SW0 Toggled -> Redundancy Mode: [expr {$cur_sw0 ? "TMR" : "Simplex"}]"
                send_pkt [list 170 4 $cur_sw0 0 255 0 0 0 15 0 0 0 1 85]
            } elseif {$last_sw == -1} {
                set last_sw $cur_sw0
            }
        }
    }

    # 3. Periodic Heartbeat every 2.5 seconds to keep dashboard alive
    set now [clock seconds]
    if {[expr {$now - $hb_time}] >= 3} {
        set hb_time $now
        set cur_sw0 [expr {$last_sw >= 0 ? $last_sw : 0}]
        send_pkt [list 170 4 $cur_sw0 0 255 0 0 0 15 0 0 0 $now 85]
    }

    after 30
}
$seq delete
