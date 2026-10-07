# ============================================================================
# File: vitis_build_app.py
# Description: Modern Vitis Unified Python Script to Build Application from XSA
# Usage: vitis -s scripts/vitis_build_app.py
# ============================================================================

import os
import sys

try:
    import vitis
except ImportError:
    print("[ERROR] vitis python module not found. Run with: vitis -s scripts/vitis_build_app.py")
    sys.exit(1)

script_dir = os.path.dirname(os.path.abspath(__file__))
base_dir = os.path.abspath(os.path.join(script_dir, ".."))
ws_dir = os.path.join(base_dir, "vitis_ws")
xsa_path = os.path.join(base_dir, "output", "system_wrapper.xsa")
c_src = os.path.join(base_dir, "vitis_app", "main.c")

print("==========================================================================")
print("  STARTING VITIS UNIFIED EMBEDDED BUILD")
print("==========================================================================")
print(f" Workspace : {ws_dir}")
print(f" XSA Path  : {xsa_path}")

client = vitis.create_client()
client.set_workspace(path=ws_dir)

# 1. Create Platform Component
platform_name = "zybo_platform"
print(f" === [1/3] Creating Platform Component: {platform_name}...")
platform = client.create_platform_component(
    name=platform_name,
    hw=xsa_path,
    os="standalone",
    cpu="ps7_cortexa9_0"
)
platform.build()

# 2. Create Application Component
app_name = "zynq_uart_bridge"
print(f" === [2/3] Creating Application Component: {app_name}...")
app = client.create_app_component(
    name=app_name,
    platform=os.path.join(ws_dir, platform_name, "export", platform_name, f"{platform_name}.xpfm"),
    domain="standalone_ps7_cortexa9_0"
)

# 3. Add Source and Build
print(f" === [3/3] Importing Source and Building Application...")
app.import_files(from_loc=c_src, dest_dir_in_cmp="src")
app.build()

print("==========================================================================")
print("  VITIS APPLICATION BUILD COMPLETED SUCCESSFULLY!")
print("==========================================================================")
