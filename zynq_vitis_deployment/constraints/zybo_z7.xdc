## ============================================================================
## File: zybo_z7.xdc
## Description: Board Constraint File for Digilent Zybo Z7 (Zynq-7000).
##              Maps 125MHz clock, active-high CPU reset, 4 LEDs, and PMOD UART.
## Standards: Xilinx Vivado XDC Constraints (LVCMOS33)
## ============================================================================

## ----------------------------------------------------------------------------
## Clock Signal (125 MHz System Oscillator)
## ----------------------------------------------------------------------------
set_property -dict { PACKAGE_PIN K17   IOSTANDARD LVCMOS33 } [get_ports { sysclk }];
create_clock -add -name sys_clk_pin -period 8.00 -waveform {0 4} [get_ports { sysclk }];

## ----------------------------------------------------------------------------
## Push Buttons (Active High)
## ----------------------------------------------------------------------------
set_property -dict { PACKAGE_PIN K18   IOSTANDARD LVCMOS33 } [get_ports { BTN0 }]; # Reset
set_property -dict { PACKAGE_PIN P16   IOSTANDARD LVCMOS33 } [get_ports { BTN1 }]; # SEC Fault
set_property -dict { PACKAGE_PIN K19   IOSTANDARD LVCMOS33 } [get_ports { BTN2 }]; # DED Fault
set_property -dict { PACKAGE_PIN Y16   IOSTANDARD LVCMOS33 } [get_ports { BTN3 }]; # ALU Fault

## ----------------------------------------------------------------------------
## Slide Switches
## ----------------------------------------------------------------------------
set_property -dict { PACKAGE_PIN G15   IOSTANDARD LVCMOS33 } [get_ports { SW0 }];  # Simplex/TMR Mode

## ----------------------------------------------------------------------------
## User LEDs (LED[3:0])
## ----------------------------------------------------------------------------
set_property -dict { PACKAGE_PIN M14   IOSTANDARD LVCMOS33 } [get_ports { LED[0] }];
set_property -dict { PACKAGE_PIN M15   IOSTANDARD LVCMOS33 } [get_ports { LED[1] }];
set_property -dict { PACKAGE_PIN G14   IOSTANDARD LVCMOS33 } [get_ports { LED[2] }];
set_property -dict { PACKAGE_PIN D18   IOSTANDARD LVCMOS33 } [get_ports { LED[3] }];

