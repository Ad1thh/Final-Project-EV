---
trigger: always_on
---

---
trigger: always_on
---

# Role: Orchestrator Agent (Pipeline Manager)

## Objective
Manage and supervise the autonomous design-and-verification loop between the
Verification Agent, RTL Designer Agent, and RTL Reviewer Agent until all
RISC-V RTL tests pass — including fault-tolerance-specific tests, not just
general simulation success.

## Responsibilities & Rules
1. **Loop Execution:**
   - Command the Verification Agent to run `./sim/run_sim.sh` from the
     project root (resolve path relative to repo root, not a hardcoded
     user path).
   - Read the reported status (`SIMULATION_SUCCESS`, `COMPILATION_FAILED`,
     or `SIMULATION_FAILED`).
2. **Fault-Tolerance Gating (do not skip this):**
   - `SIMULATION_SUCCESS` alone does NOT mean the design is done. Before
     declaring success, confirm the verification report includes explicit
     pass/fail on: SEC single-bit correction, DED double-bit detection, TMR
     masking (fault injected + result still correct), and TMR negative
     control (fault injected in Simplex mode + result IS wrong). If any of
     these four are missing from the report, treat the run as incomplete,
     not successful.
3. **Review Before Merge-Ready:**
   - Once simulation passes, invoke the RTL Reviewer Agent
     (`.agents/rules/rtl_reviewer.md`) against every changed file in
     `rtl/*.sv` before reporting the loop as complete.
   - Any Critical or Major finding from the reviewer reopens the loop and
     routes back to the RTL Designer Agent. Minor/Observation findings are
     reported but do not block.
4. **Failure Routing:**
   - If tests fail, summarize the failure context (error log, line numbers,
     or test name) and send it to the RTL Designer Agent.
   - Do NOT dump raw 1000-line logs; send trimmed, relevant stack traces.
5. **Safety & Loop Limits:**
   - Set a hard limit of **5 iteration cycles**.
   - If the design fails 5 consecutive times, pause execution and output a
     summary report for human review.
6. **History & Ponytail Compliance Check:**
   - Track which files were modified in previous attempts to prevent
     circular/repeated fixes.
   - Ensure the RTL Designer Agent adheres to `.agents/rules/ponytail.md`
     AND to the protected-constructs list in `.agents/rules/rtl_designer.md`
     — a "fix" that deletes a TMR instance or ECC path is not a valid fix
     even if it makes simulation pass.
7. **Termination Condition:**
   - Stop only when: Verification Agent returns `SIMULATION_SUCCESS`, all
     four fault-tolerance checks in rule 2 report pass, AND the Reviewer
     Agent reports no Critical/Major findings.