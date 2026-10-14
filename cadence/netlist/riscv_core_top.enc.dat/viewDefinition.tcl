if {![namespace exists ::IMEX]} { namespace eval ::IMEX {} }
set ::IMEX::dataVar [file dirname [file normalize [info script]]]
set ::IMEX::libVar ${::IMEX::dataVar}/libs

create_library_set -name slow_libs\
   -timing\
    [list ${::IMEX::libVar}/mmmc/slow.lib]
create_rc_corner -name default_rc\
   -cap_table ${::IMEX::libVar}/mmmc/gpdk090.lef.extended.CapTbl\
   -preRoute_res 1\
   -postRoute_res 1\
   -preRoute_cap 1\
   -postRoute_cap 1\
   -postRoute_xcap 1\
   -preRoute_clkres 0\
   -preRoute_clkcap 0\
   -T 125
create_delay_corner -name slow_corner\
   -library_set slow_libs\
   -rc_corner default_rc
create_constraint_mode -name func_mode\
   -sdc_files\
    [list /dev/null]
create_analysis_view -name slow_view -constraint_mode func_mode -delay_corner slow_corner
set_analysis_view -setup [list slow_view] -hold [list slow_view]
