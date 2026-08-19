## ============================================================================
## File: nexys4.xdc
## Description: Board Constraint File for Xilinx Nexys 4 (Artix-7 XC7A100T-1CSG324C).
##              Maps 100MHz clock, active-low CPU reset, and 16 LEDs.
## Standards: Xilinx Vivado XDC Constraints (LVCMOS33)
## ============================================================================

## ----------------------------------------------------------------------------
## Clock Signal (100 MHz System Oscillator)
## ----------------------------------------------------------------------------
set_property -dict { PACKAGE_PIN E3    IOSTANDARD LVCMOS33 } [get_ports { CLK100MHZ }];
create_clock -add -name sys_clk_pin -period 10.00 -waveform {0 5} [get_ports { CLK100MHZ }];

## ----------------------------------------------------------------------------
## Reset Button (CPU_RESETN - Active Low Pushbutton)
## ----------------------------------------------------------------------------
set_property -dict { PACKAGE_PIN E16   IOSTANDARD LVCMOS33 } [get_ports { CPU_RESETN }];

## ----------------------------------------------------------------------------
## User LEDs (LED[15:0])
## ----------------------------------------------------------------------------
set_property -dict { PACKAGE_PIN T8   IOSTANDARD LVCMOS33 } [get_ports { LED[0]  }];
set_property -dict { PACKAGE_PIN V9   IOSTANDARD LVCMOS33 } [get_ports { LED[1]  }];
set_property -dict { PACKAGE_PIN R8   IOSTANDARD LVCMOS33 } [get_ports { LED[2]  }];
set_property -dict { PACKAGE_PIN T6   IOSTANDARD LVCMOS33 } [get_ports { LED[3]  }];
set_property -dict { PACKAGE_PIN T5   IOSTANDARD LVCMOS33 } [get_ports { LED[4]  }];
set_property -dict { PACKAGE_PIN T4   IOSTANDARD LVCMOS33 } [get_ports { LED[5]  }];
set_property -dict { PACKAGE_PIN U7   IOSTANDARD LVCMOS33 } [get_ports { LED[6]  }];
set_property -dict { PACKAGE_PIN U6   IOSTANDARD LVCMOS33 } [get_ports { LED[7]  }];
set_property -dict { PACKAGE_PIN V4   IOSTANDARD LVCMOS33 } [get_ports { LED[8]  }];
set_property -dict { PACKAGE_PIN U3   IOSTANDARD LVCMOS33 } [get_ports { LED[9]  }];
set_property -dict { PACKAGE_PIN V1   IOSTANDARD LVCMOS33 } [get_ports { LED[10] }];
set_property -dict { PACKAGE_PIN R1   IOSTANDARD LVCMOS33 } [get_ports { LED[11] }];
set_property -dict { PACKAGE_PIN P5   IOSTANDARD LVCMOS33 } [get_ports { LED[12] }];
set_property -dict { PACKAGE_PIN U1   IOSTANDARD LVCMOS33 } [get_ports { LED[13] }];
set_property -dict { PACKAGE_PIN R2   IOSTANDARD LVCMOS33 } [get_ports { LED[14] }];
set_property -dict { PACKAGE_PIN P2   IOSTANDARD LVCMOS33 } [get_ports { LED[15] }];

## ----------------------------------------------------------------------------
## Configuration Voltage & Mode Settings for Artix-7
## ----------------------------------------------------------------------------
set_property CFGBVS VCCO [current_design]
set_property CONFIG_VOLTAGE 3.3 [current_design]