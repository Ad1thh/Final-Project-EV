import subprocess
import glob
import os
import sys

def run_cmd(cmd):
    res = subprocess.run(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True, shell=True)
    return res.returncode, res.stdout, res.stderr

def main():
    proj_dir = r"C:\Main_Project\Final-Project-EV"
    tb_files = glob.glob(os.path.join(proj_dir, "tb", "tb_*.sv"))
    rtl_files = glob.glob(os.path.join(proj_dir, "rtl", "*.sv"))
    
    print("=========================================================================")
    print("              RUNNING ALL PROCESSOR CORE TESTBENCHES                     ")
    print("=========================================================================\n")
    
    results = {}
    
    for tb in sorted(tb_files):
        tb_name = os.path.basename(tb)
        print(f"Testing {tb_name} ...", end=" ", flush=True)
        
        other_rtl = [f"rtl/{os.path.basename(r)}" for r in sorted(rtl_files) if "riscv_pkg.sv" not in r]
        rtl_str = "rtl/riscv_pkg.sv " + " ".join(other_rtl)
        vvp_out = f"sim/{tb_name.replace('.sv', '.vvp')}"
        
        cmd = f"wsl bash -c \"cd /mnt/c/Main_Project/Final-Project-EV && iverilog -g2012 -o {vvp_out} {rtl_str} tb/{tb_name} && vvp {vvp_out}\""
        
        code, out, err = run_cmd(cmd)
        
        if code == 0 and ("PASSED" in out or "TEST PASSED" in out or "SUCCESS" in out or "$finish called" in out):
            print("PASSED [PASS]")
            results[tb_name] = "PASSED"
        else:
            print("FAILED [FAIL]")
            print("--- STDOUT ---")
            print(out[-1000:])
            print("--- STDERR ---")
            print(err[-1000:])
            results[tb_name] = "FAILED"
            
    print("\n=========================================================================")
    print("                      FULL SIMULATION SUMMARY                            ")
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
