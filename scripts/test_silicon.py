import subprocess
import time

XSDB_PATH = r"C:\AMDDesignTools\2025.2.1\Vivado\bin\xsdb.bat"

tcl_script = """
connect
jtag targets 3
set seq [jtag sequence]
$seq state RESET
$seq state IDLE
$seq irshift -state IDLE -hex 6 02
$seq drshift -state IDLE -capture -hex 64 0000000000000000
set res [$seq run -hex]
puts "RES:$res"
$seq delete
"""

with open("scripts/read_pins.tcl", "w") as f:
    f.write(tcl_script)

res = subprocess.run([XSDB_PATH, "scripts/read_pins.tcl"], capture_output=True, text=True)
for line in res.stdout.splitlines():
    if line.startswith("RES:"):
        hex_str = line.split("RES:")[1].strip()
        print(f"RAW HEX FROM SILICON: {hex_str}")
