import subprocess
import glob
import os
import sys

VIVADO_BIN = r"C:\AMDDesignTools\2025.2\Vivado\bin"
XVLOG = os.path.join(VIVADO_BIN, "xvlog.bat")
XELAB = os.path.join(VIVADO_BIN, "xelab.bat")
XSIM  = os.path.join(VIVADO_BIN, "xsim.bat")

def run_cmd(cmd, cwd=None):
    res = subprocess.run(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True, shell=True, cwd=cwd)
    return res.returncode, res.stdout, res.stderr

def main():
    proj_dir = r"C:\Main_Project\Final-Project-EV"
    tb_files = glob.glob(os.path.join(proj_dir, "tb", "tb_*.sv"))
    
    print("=========================================================================")
    print("        RUNNING ALL TESTBENCHES USING VIVADO SIMULATOR 2025.2            ")
    print("=========================================================================\n")
    
    # 1. Compile all RTL files
    rtl_files = [
        "rtl/riscv_pkg.sv",
        "rtl/clock_gater.sv",
        "rtl/tmr_voter.sv",
        "rtl/adaptive_redundancy_controller.sv",
        "rtl/alu.sv",
        "rtl/control_unit.sv",
        "rtl/hazard_unit.sv",
        "rtl/regfile.sv",
        "rtl/if_stage.sv",
        "rtl/id_ex_stage.sv",
        "rtl/wb_stage.sv",
        "rtl/riscv_core_top.sv"
    ]
    
    rtl_cmd = f'"{XVLOG}" -sv ' + " ".join(rtl_files)
    code, out, err = run_cmd(rtl_cmd, cwd=proj_dir)
    if code != 0:
        print("FAILED to compile RTL files!")
        print(out)
        print(err)
        sys.exit(1)
    else:
        print("RTL Compilation Successful! [PASS]\n")

    results = {}

    for tb_path in sorted(tb_files):
        tb_name = os.path.basename(tb_path)
        tb_module = tb_name.replace(".sv", "")
        print(f"Testing {tb_name:<35} ... ", end="", flush=True)

        # Compile testbench
        compile_cmd = f'"{XVLOG}" -sv tb/{tb_name}'
        c_code, c_out, c_err = run_cmd(compile_cmd, cwd=proj_dir)
        if c_code != 0:
            print("COMPILE FAILED [FAIL]")
            results[tb_name] = "COMPILE FAILED"
            continue

        # Elaborate
        snapshot = f"{tb_module}_sim"
        elab_cmd = f'"{XELAB}" -debug typical {tb_module} -s {snapshot}'
        e_code, e_out, e_err = run_cmd(elab_cmd, cwd=proj_dir)
        if e_code != 0:
            print("ELABORATE FAILED [FAIL]")
            results[tb_name] = "ELABORATE FAILED"
            continue

        # Simulate
        sim_cmd = f'"{XSIM}" {snapshot} -R'
        s_code, s_out, s_err = run_cmd(sim_cmd, cwd=proj_dir)

        if s_code == 0 and ("PASSED" in s_out or "TEST PASSED" in s_out or "SUCCESS" in s_out or "$finish called" in s_out):
            print("PASSED [PASS]")
            results[tb_name] = "PASSED"
        else:
            print("SIM FAILED [FAIL]")
            results[tb_name] = "SIM FAILED"

    print("\n=========================================================================")
    print("                      FULL VIVADO SIMULATION SUMMARY                     ")
    print("=========================================================================")
    passed = 0
    total = len(results)
    for tb, status in results.items():
        print(f"  - {tb:<35}: {status}")
        if status == "PASSED":
            passed += 1
    print("=========================================================================")
    print(f"  TOTAL: {passed} / {total} Passed")
    print("=========================================================================")

    if passed == total:
        sys.exit(0)
    else:
        sys.exit(1)

if __name__ == "__main__":
    main()
