## ============================================================================
## File: zybo_z7.xdc
## Description: Board Constraint File for Digilent Zybo Z7 (Zynq-7000).
##              Maps 125MHz clock, active-high CPU reset, 4 LEDs, and PMOD UART.
## Standards: Xilinx Vivado XDC Constraints (LVCMOS33)
## ============================================================================

## ----------------------------------------------------------------------------
## Clock Signal (Internal Zynq PS FCLK_CLK0 used, no external pin required)
## ----------------------------------------------------------------------------
# set_property -dict { PACKAGE_PIN L16   IOSTANDARD LVCMOS33 } [get_ports { sysclk }];
# create_clock -add -name sys_clk_pin -period 8.00 -waveform {0 4} [get_ports { sysclk }];

## ----------------------------------------------------------------------------
## Push Buttons (Active High on ZYBO Rev. B)
## ----------------------------------------------------------------------------
set_property -dict { PACKAGE_PIN R18   IOSTANDARD LVCMOS33 } [get_ports { BTN0 }]; # Reset (BTN0)
set_property -dict { PACKAGE_PIN P16   IOSTANDARD LVCMOS33 } [get_ports { BTN1 }]; # SEC Fault (BTN1)
set_property -dict { PACKAGE_PIN V16   IOSTANDARD LVCMOS33 } [get_ports { BTN2 }]; # DED Fault (BTN2)
set_property -dict { PACKAGE_PIN Y16   IOSTANDARD LVCMOS33 } [get_ports { BTN3 }]; # ALU Fault (BTN3)

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

