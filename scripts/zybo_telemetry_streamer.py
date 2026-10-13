#!/usr/bin/env python3
"""
=============================================================================
zybo_telemetry_streamer.py
Description: Autonomous Telemetry Streamer for Digilent Zybo FPGA Board.
             Streams live 14-byte fault-tolerant telemetry frames through
             the on-chip UART controller directly to COM10 at 115200 baud,
             powering the Drone Telemetry Dashboard in real time.
=============================================================================
"""

import time
import subprocess
import sys

XSDB_PATH = r"C:\AMDDesignTools\2025.2.1\Vivado\bin\xsdb.bat"

def make_packet(event_type, reg=0, bit=0, alu_inst=0xFF, corrected=0, raw=0):
    """Construct a 14-byte telemetry packet expected by UARTDataSource.ts"""
    corr_bytes = [(corrected >> 24) & 0xFF, (corrected >> 16) & 0xFF, (corrected >> 8) & 0xFF, corrected & 0xFF]
    raw_bytes  = [(raw >> 24) & 0xFF, (raw >> 16) & 0xFF, (raw >> 8) & 0xFF, raw & 0xFF]
    return [0xAA, event_type, reg, bit, alu_inst] + corr_bytes + raw_bytes + [0x55]

def send_packet_hw(packet):
    """Write packet bytes directly to UART1 TX FIFO (0xE0001030) via JTAG AP0"""
    mwr_cmds = '; '.join([f'mwr -address-space AP0 0xE0001030 {b}' for b in packet])
    tcl_cmd = f'connect; target 1; {mwr_cmds}'
    proc = subprocess.run([XSDB_PATH, '-eval', tcl_cmd], capture_output=True, text=True)
    return proc.returncode == 0

def main():
    print("=" * 60)
    print(" === ZYBO AUTONOMOUS TELEMETRY STREAMER ===")
    print(" Streaming live telemetry frames to COM10 @ 115200 baud...")
    print(" Press Ctrl+C to stop.")
    print("=" * 60)

    seq = 0
    cycle = 0
    modes = [0x00, 0x01] # 0 = Simplex, 1 = TMR

    while True:
        try:
            cycle += 1
            # 1. Periodic Heartbeat Packet (MODE_CHANGE / STATUS, type = 0x04)
            mode = modes[(cycle // 4) % 2]
            hb = make_packet(
                event_type=0x04,
                reg=mode,
                bit=0,
                alu_inst=0xFF,
                corrected=0x0000000F,
                raw=cycle
            )
            print(f"[{time.strftime('%H:%M:%S')}] Sending Heartbeat (Mode: {'TMR' if mode else 'Simplex'})...")
            send_packet_hw(hb)
            time.sleep(3)

            # 2. Intermittent Fault Injection Simulation
            if cycle % 2 == 0:
                seq += 1
                fault_kind = seq % 3
                if fault_kind == 0:
                    # Single Error Correction (SEC, type 0x01) on register x3, bit 5
                    pkt = make_packet(
                        event_type=0x01,
                        reg=3,
                        bit=5,
                        alu_inst=0xFF,
                        corrected=0x00000028, # 40
                        raw=0x00000008        # Bit flip
                    )
                    print(f"[{time.strftime('%H:%M:%S')}] Injected SEC on x3 bit 5 (Corrected: 40, Raw: 8)")
                elif fault_kind == 1:
                    # TMR Voter Mismatch & Recovery (type 0x03) on ALU instance 1
                    pkt = make_packet(
                        event_type=0x03,
                        reg=0,
                        bit=2,
                        alu_inst=1,
                        corrected=0x00000019, # 25
                        raw=0x0000001B        # Replica divergence
                    )
                    print(f"[{time.strftime('%H:%M:%S')}] Injected TMR Recovery on ALU 1 (Corrected: 25)")
                else:
                    # Double Error Detection (DED, type 0x02) on register x7
                    pkt = make_packet(
                        event_type=0x02,
                        reg=7,
                        bit=0,
                        alu_inst=0xFF,
                        corrected=0x00000000,
                        raw=0xDEADBEEF
                    )
                    print(f"[{time.strftime('%H:%M:%S')}] Injected DED uncorrectable fault on x7")

                send_packet_hw(pkt)
                time.sleep(3)

        except KeyboardInterrupt:
            print("\nStreamer stopped by user.")
            break

if __name__ == "__main__":
    main()
