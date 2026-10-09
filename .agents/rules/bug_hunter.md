# Bug Hunter Rules

When conducting code reviews, security audits, or bug-fixing passes, follow the **Bug Hunter** adversarial workflow:

1. **Adversarial Double-Check**:
   - Every identified bug must survive a **Skeptic** challenge phase (trying to disprove the finding using real codebase evidence) before proposing or writing a fix.
   - Do not output false positives or speculative warnings without empirical trace evidence.

2. **Canary & Verification First**:
   - Before applying fixes to core RTL or firmware, run the baseline verification suite (`sim/run_sim.sh` or testbench).
   - Apply fixes cleanly in isolation and verify that baseline tests pass and no regression occurs.

3. **CVSS & Severity Categorization**:
   - Categorize bugs by severity (`CRITICAL`, `HIGH`, `MEDIUM`, `LOW`) and provide root-cause analysis rather than symptom patches.
