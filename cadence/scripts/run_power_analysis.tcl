# ==============================================================================
# Script: run_power_analysis.tcl
# Description: Innovus Power Analysis (Vectored + SPEF and Vectorless)
# ==============================================================================

set PROJECT_DIR [file normalize [file join [file dirname [info script]] "../.."]]
cd $PROJECT_DIR

set REPORTS_DIR "${PROJECT_DIR}/cadence/reports"
set NETLIST_DIR "${PROJECT_DIR}/cadence/netlist"

puts "======================================================================"
puts " RESTORING INNOVUS ROUTED DESIGN DATABASE"
puts "======================================================================"
source ${NETLIST_DIR}/riscv_core_top.enc

puts "\n======================================================================"
puts " BACK-ANNOTATING POST-ROUTE SPEF PARASITICS"
puts "======================================================================"
spefIn -rc_corner rc_slow ${NETLIST_DIR}/riscv_core_top.spef

puts "\n======================================================================"
puts " 1. VECTORED POWER ANALYSIS (VCD from Gate Sim + Post-Route SPEF)"
puts " Workload: stress_test (2,428 RISC-V instructions, 24,335 ns)"
puts "======================================================================"
set_power_analysis_mode -reset
set_power_analysis_mode -method static
read_activity_file -format VCD -scope tb_compliance_run/dut -start 0ps -end 24335000ps ${REPORTS_DIR}/workload.vcd
report_power -outfile ${REPORTS_DIR}/innovus_power_vectored.rpt -hierarchy all
puts "--> Vectored Power report written to: ${REPORTS_DIR}/innovus_power_vectored.rpt"

puts "\n======================================================================"
puts " 2. VECTORLESS POWER ANALYSIS (0.2 Switching Activity + Post-Route SPEF)"
puts " Corner: GPDK 90nm Slow (0.9V, 125C, 100 MHz)"
puts "======================================================================"
set_power_analysis_mode -reset
set_power_analysis_mode -method static
read_activity_file -reset
set_default_switching_activity -input_activity 0.2 -seq_activity 0.2
report_power -outfile ${REPORTS_DIR}/innovus_power_vectorless.rpt -hierarchy all
puts "--> Vectorless Power report written to: ${REPORTS_DIR}/innovus_power_vectorless.rpt"

puts "\n======================================================================"
puts " POWER ANALYSIS FLOW COMPLETED"
puts "======================================================================"
exit
