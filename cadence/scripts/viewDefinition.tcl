create_library_set -name slow_libs -timing [list /home/install/FOUNDRY/digital/90nm/dig/lib/slow.lib]
create_rc_corner -name default_rc -cap_table /home/install/FOUNDRY/digital/90nm/dig/captable/gpdk090.lef.extended.CapTbl -T 125.0
create_delay_corner -name slow_corner -library_set slow_libs -rc_corner default_rc
create_constraint_mode -name func_mode -sdc_files [list /home/student/Final-Project-EV/cadence/netlist/riscv_core_top_syn.sdc]
create_analysis_view -name slow_view -constraint_mode func_mode -delay_corner slow_corner
set_analysis_view -setup [list slow_view] -hold [list slow_view]
