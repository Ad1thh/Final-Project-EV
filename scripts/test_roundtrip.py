import serial
import subprocess
import time

XSDB_PATH = r"C:\AMDDesignTools\2025.2.1\Vivado\bin\xsdb.bat"

# Open COM10
ser = serial.Serial("COM10", 115200, timeout=2)
ser.reset_input_buffer()

# Send 14-byte packet via AP0 UART1 FIFO
# Packet: [0xAA, 0x01 (SEC), 0x03 (x3), 0x05 (bit 5), 0xFF, 0x00, 0x00, 0x00, 0x28, 0x00, 0x00, 0x00, 0x08, 0x55]
pkt = [0xAA, 0x01, 0x03, 0x05, 0xFF, 0x00, 0x00, 0x00, 0x28, 0x00, 0x00, 0x00, 0x08, 0x55]
mwr_cmds = '; '.join([f'mwr -address-space AP0 0xE0001030 {b}' for b in pkt])
tcl_cmd = f'connect; target 1; {mwr_cmds}'

subprocess.run([XSDB_PATH, '-eval', tcl_cmd], capture_output=True, text=True)

# Read from COM10
received = ser.read(14)
ser.close()

print(f"SENT:     {[hex(b) for b in pkt]}")
print(f"RECEIVED: {[hex(b) for b in received]}")
if list(received) == pkt:
    print(">>> VERIFICATION SUCCESSFUL: COM10 RECEIVED EXACT PACKET! <<<")
else:
    print("MISMATCH")
