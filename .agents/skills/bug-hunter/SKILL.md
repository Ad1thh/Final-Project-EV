---
name: bug-hunter
description: "Adversarial bug hunting with a sequential-first pipeline (Recon, Hunter, Skeptic, Referee). Finds, verifies, and auto-fixes real bugs by default (with --scan-only opt-out). Use this skill whenever the user wants bug finding, security audits, regression checks, or code review focused on runtime behavior."
---

# Bug Hunter - Adversarial Bug Finding & Security Scanner

Run an adversarial bug hunt on your codebase using a multi-phase verification pipeline.

## Usage

```
/bug-hunter                              # Scan entire project
/bug-hunter rtl/                         # Scan specific directory
/bug-hunter --scan-only                  # Scan & report only, no code changes
/bug-hunter --fix                        # Find bugs AND auto-fix them
/bug-hunter --staged                    # Scan staged files
/bug-hunter --deps --threat-model        # Full security audit
```

## Pipeline Stages

1. **Recon** — Map tech stack, clock domains, interfaces, and hazard boundaries.
2. **Hunter** — Deep behavioral scan for logic errors, race conditions, bit-truncations, and unhandled traps.
3. **Skeptic** — Adversarial challenge stage that attempts to disprove findings with counter-evidence.
4. **Referee** — Independent judge delivering final CVSS-scored verdicts.
5. **Fixer (Auto-Fix)** — Applies verified fixes on a safe branch with automated verification checks.
