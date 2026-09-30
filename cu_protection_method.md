# Optimized Protection Methodology for the Control Unit

*This document outlines the most area-efficient and safe method to protect the combinational Control Unit in the RV32E core, applying the rigorous principles from `method.md`.*

---

## 1. The Strategy: Dual Modular Redundancy (DMR) with Fail-Safe Clamping
**Why not TMR?** The Control Unit (CU) is a dense combinational decode tree. Triplicating it consumes excessive area and routing resources in Genus, and voting on 10+ control wires adds significant critical path delay. 
**The Solution:** We only need to *detect* a fault to prevent architectural corruption. We will use a **DMR Checker** pattern. If the primary CU and the checker CU disagree on critical signals, we immediately clamp (force to zero) the destructive wires (`mem_write`, `reg_write`) and issue a trap.

---

## 2. Implementation Steps (Applying `method.md`)

### Step 0: Know Your Denominator
Before writing any RTL, establish the baseline.
*   **Action:** Run Cadence Genus synthesis on the unmodified `control_unit.sv`.
*   **Record:** Document the exact Cell Area ($\mu m^2$) and critical path delay (ps). If you don't know the starting area, you cannot measure the cost of the protection.

### Step 1: Break it on purpose (Mutation Testing)
*A green test that cannot fail is not evidence.*
*   **Action:** In `tb_core_stress_adversarial.sv`, inject a transient fault (force a wire high) on `u_control_unit.mem_write` during a harmless `ADD` instruction.
*   **Result:** The simulation must fail. The corrupted `mem_write` should overwrite a random memory address, causing the final compliance test hash to fail. Keep this broken test case active.

### Step 2: Implement the Checker CU (Change one thing)
Do not change the internals of `control_unit.sv`. Keep it pure. Instead, modify the instantiation layer in `id_ex_stage.sv`:

1.  **Instantiate a Duplicate:** Add `control_unit u_control_unit_checker` receiving the exact same `opcode`, `funct3`, and `funct7` inputs.
2.  **Comparator Logic:** Create an XOR tree to compare *only the catastrophic outputs*:
    ```systemverilog
    logic cu_mismatch;
    assign cu_mismatch = (ctrl_mem_write != checker_mem_write) |
                         (ctrl_reg_write != checker_reg_write) |
                         (ctrl_is_branch != checker_is_branch);
    ```
3.  **Fail-Safe Clamping:** Override the critical signals sent to the rest of the pipeline:
    ```systemverilog
    assign safe_mem_write = ctrl_mem_write & ~cu_mismatch;
    assign safe_reg_write = ctrl_reg_write & ~cu_mismatch;
    ```
4.  **Trap:** Route `cu_mismatch` to the top-level trap/exception generator to halt the processor.

### Step 3: Verify the Fix
*   **Action:** Re-run the broken test from Step 1.
*   **Prediction:** The `cu_mismatch` flag will assert. `safe_mem_write` will clamp to `0`. The memory will not be corrupted, and the processor will safely trap. 
*   **Result:** The test must now safely catch the fault instead of silently corrupting memory.

---

## 3. The Digital Backend Trap: What the Compiler Did to Your Work
*Rule 6: Check what the framework was doing for you.*

This is the most critical step for ASIC implementation. Cadence Genus is designed to minimize area. If you feed it two identical Control Units with identical inputs, the Datapath Optimizer (`syn_map`) will realize they are algebraically equivalent. **Genus will delete the checker CU and merge the logic**, entirely destroying your fault tolerance!

**The Fix:**
You must explicitly command Genus to preserve the physical boundary between the two units in your TCL synthesis script.

```tcl
# Genus Synthesis Constraints to prevent Resource Sharing of the CUs
set_db /designs/riscv_core_top/instances/u_control_unit .preserve true
set_db /designs/riscv_core_top/instances/u_control_unit_checker .preserve true
```

In Innovus (Place and Route), you should define **Physical Fences** to place the main CU and the checker CU in different physical regions of the silicon floorplan. This guarantees that a single radiation strike (Single Event Multiple Upset - SEMU) cannot flip transistors in both units simultaneously.

---

## 4. Final Verification
*Two independent routes to the same answer beat one careful route.*
*   **Action:** Run formal equivalence checking (e.g., Cadence Conformal) between the netlist output of Genus and the original RTL to ensure the `.preserve` constraint worked and the XOR comparator was not optimized away.
*   **Report:** Compare the final Genus Cell Area to the Step 0 baseline. State the area cost cleanly (e.g., "DMR on the CU added 1.8x cell area to the decode stage, but prevented 100% of injected memory corruption faults").
