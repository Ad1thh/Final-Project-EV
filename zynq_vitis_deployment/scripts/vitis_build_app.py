# ============================================================================
# File: vitis_build_app.py
# Description: Modern Vitis Unified Python Script to Build Application from XSA
# Usage: vitis -s scripts/vitis_build_app.py
# ============================================================================

import os
import sys
import shutil

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
out_elf = os.path.join(base_dir, "output", "zynq_uart_bridge.elf")

print("==========================================================================")
print("  STARTING VITIS UNIFIED EMBEDDED BUILD")
print("==========================================================================")
print(f" Workspace : {ws_dir}")
print(f" XSA Path  : {xsa_path}")

client = vitis.create_client()
client.set_workspace(path=ws_dir)

# 1. Platform Component
platform_name = "zybo_platform"
try:
    platform = client.get_component(name=platform_name)
    print(f" === [1/3] Using existing Platform Component: {platform_name}...")
except Exception:
    print(f" === [1/3] Creating Platform Component: {platform_name}...")
    platform = client.create_platform_component(
        name=platform_name,
        hw_design=xsa_path,
        os="standalone",
        cpu="ps7_cortexa9_0"
    )
    platform.build()

# 2. Application Component
app_name = "zynq_uart_bridge"
try:
    app = client.get_component(name=app_name)
    print(f" === [2/3] Using existing Application Component: {app_name}...")
except Exception:
    print(f" === [2/3] Creating Application Component: {app_name}...")
    xpfm_path = os.path.join(ws_dir, platform_name, "export", platform_name, f"{platform_name}.xpfm")
    try:
        domains = platform.get_domains()
        target_domain = domains[0] if domains else "standalone_ps7_cortexa9_0"
    except Exception:
        target_domain = "standalone_ps7_cortexa9_0"

    app = client.create_app_component(
        name=app_name,
        platform=xpfm_path,
        domain=target_domain
    )

# 3. Add Source, Build, and Copy Output
print(f" === [3/3] Importing Updated Source and Building Application...")
app.import_files(from_loc=c_src, dest_dir_in_cmp="src")
app.clean()
app.build()

# Locate generated ELF
candidates = [
    os.path.join(ws_dir, app_name, "build", f"{app_name}.elf"),
    os.path.join(ws_dir, app_name, "Debug", f"{app_name}.elf"),
    os.path.join(ws_dir, app_name, "Release", f"{app_name}.elf"),
]

copied = False
for cand in candidates:
    if os.path.exists(cand):
        os.makedirs(os.path.dirname(out_elf), exist_ok=True)
        shutil.copyfile(cand, out_elf)
        print(f" [SUCCESS] Copied {cand} -> {out_elf} ({os.path.getsize(out_elf)} bytes)")
        copied = True
        break

if not copied:
    print(f" [WARNING] Could not locate built ELF in expected candidates: {candidates}")

print("==========================================================================")
print("  VITIS APPLICATION BUILD COMPLETED SUCCESSFULLY!")
print("==========================================================================")
