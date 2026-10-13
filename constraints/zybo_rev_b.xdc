## ============================================================================
## File: zybo_rev_b.xdc
## Description: Board Constraint File for Digilent ZYBO Rev. B (XC7Z010-1CLG400C).
##              Maps 125MHz Ethernet PHY clock, pushbuttons (BTN0-BTN3),
##              slide switches (SW0-SW3), 4 User LEDs, and PMOD JE UART TX pin.
## Standards: Xilinx Vivado XDC Constraints (LVCMOS33)
## ============================================================================

## ----------------------------------------------------------------------------
## Clock Signal (125 MHz Clock from Ethernet PHY on ZYBO Rev. B)
## ----------------------------------------------------------------------------
set_property -dict { PACKAGE_PIN L16   IOSTANDARD LVCMOS33 } [get_ports { sysclk }];
create_clock -add -name sys_clk_pin -period 8.00 -waveform {0 4} [get_ports { sysclk }];

## ----------------------------------------------------------------------------
## Pushbuttons (BTN[3:0] on ZYBO Rev. B)
## BTN0: Master Reset (Active High)
## BTN1: SEC Fault Injection (Single-bit flip in Regfile)
## BTN2: DED Fault Injection (Double-bit flip in Regfile)
## BTN3: TMR Fault Injection (ALU replica divergence)
## ----------------------------------------------------------------------------
set_property -dict { PACKAGE_PIN R18   IOSTANDARD LVCMOS33 } [get_ports { BTN[0] }];
set_property -dict { PACKAGE_PIN P16   IOSTANDARD LVCMOS33 } [get_ports { BTN[1] }];
set_property -dict { PACKAGE_PIN V16   IOSTANDARD LVCMOS33 } [get_ports { BTN[2] }];
set_property -dict { PACKAGE_PIN Y16   IOSTANDARD LVCMOS33 } [get_ports { BTN[3] }];

## ----------------------------------------------------------------------------
## Slide Switches (SW[3:0] on ZYBO Rev. B)
## SW0: Redundancy Mode (0 = Simplex, 1 = TMR)
## SW1: Target Reg Select Bit 0
## SW2: Target Reg Select Bit 1
## SW3: Target Bit Select
## ----------------------------------------------------------------------------
set_property -dict { PACKAGE_PIN G15   IOSTANDARD LVCMOS33 } [get_ports { SW[0] }];
set_property -dict { PACKAGE_PIN P15   IOSTANDARD LVCMOS33 } [get_ports { SW[1] }];
set_property -dict { PACKAGE_PIN W13   IOSTANDARD LVCMOS33 } [get_ports { SW[2] }];
set_property -dict { PACKAGE_PIN T16   IOSTANDARD LVCMOS33 } [get_ports { SW[3] }];

## ----------------------------------------------------------------------------
## User LEDs (LED[3:0] on ZYBO Rev. B)
## LED0: Processor Heartbeat / Alive
## LED1: TMR Mode Active (SW0 status)
## LED2: SEC Corrected Pulse
## LED3: DED Detected / TMR Mismatch Fault Pulse
## ----------------------------------------------------------------------------
set_property -dict { PACKAGE_PIN M14   IOSTANDARD LVCMOS33 } [get_ports { LED[0] }];
set_property -dict { PACKAGE_PIN M15   IOSTANDARD LVCMOS33 } [get_ports { LED[1] }];
set_property -dict { PACKAGE_PIN G14   IOSTANDARD LVCMOS33 } [get_ports { LED[2] }];
set_property -dict { PACKAGE_PIN D18   IOSTANDARD LVCMOS33 } [get_ports { LED[3] }];

## ----------------------------------------------------------------------------
## UART Interface (Routed to Pmod JE on ZYBO Rev. B)
## Pin 1 (V12): TXD (FPGA -> Host)
## Pin 2 (W16): RXD (Host -> FPGA)
## ----------------------------------------------------------------------------
set_property -dict { PACKAGE_PIN V12   IOSTANDARD LVCMOS33 } [get_ports { UART_TXD }];
set_property -dict { PACKAGE_PIN W16   IOSTANDARD LVCMOS33 } [get_ports { UART_RXD }];
