---
name: operational-rigor
description: "Disciplined execution for work where being wrong is expensive: multi-step tasks that modify files or systems, anything destructive or externally visible (deletes, deploys, sends, payments), production or shared state, and results that will be relied on. Not for trivial, read-only, or single-edit tasks — rigor there is just slowness. MANDATORY TRIGGERS: 'operational rigor', 'rigor mode', 'do this carefully'. STRONG TRIGGERS: tasks touching live data, money, credentials, mass file operations, or anything hard to undo. For debugging, defer to the bug-hunter skill; this skill governs execution, not diagnosis."
---

# Operational Rigor

Hard constraints on how risky work is planned, executed, verified, and declared complete. When a rule conflicts with finishing sooner, the rule wins.

## The contract

Before acting, restate the deliverable in one sentence: what will exist at the end, and how success will be observed. That sentence is the scope boundary. If a material ambiguity remains and the task mutates anything, resolve it first — by observation if observable, by one question if high-stakes, by a declared assumption if low-stakes.

Anything the user referenced but you haven't observed (a file, a setting, a fact) is unverified until you look.

## Plan cheap-first, gate the one-way doors

- Order steps so reversible, information-gathering actions come first. Read before write, write before delete.
- Any step that can't be undone (delete, overwrite without backup, push, deploy, send) is a one-way door. It needs either the user's explicit yes for that specific step, or a checkpoint that makes it recoverable (backup, branch, dry-run reviewed first). The user asking for the overall task is not consent to a destructive step they never named.
- Destructive operations run one at a time, each verified before the next. Never batch deletions, force-pushes, mass renames, or bulk sends unverified.
- Prefer dry-run / --diff / plan / list-before-act modes when the tooling has them, and read that output before the real run.
- Two consecutive failures of the same step: stop and replan. A repeated failure means your model of the system is wrong, not that you were unlucky. Never retry a third time with cosmetic variations.

## Observe, never guess

- Read a file immediately before editing it; re-read it before editing it again.
- Confirm tools, versions, paths, and permissions before relying on them.
- Facts that can change after training (API behavior, versions, prices, live data) get checked against a live source, not memory.
- Verify by execution wherever execution is possible. "The code looks right" is not verification. If you can't execute, say the work is unexecuted and what the user must run.
- A mutating command's effect is confirmed from the system's response, not from having issued it.
- Never fabricate an observation. No invented tool output, test results, or file contents. A skipped verification step is reported as skipped.

## Attack your own work before declaring done

- Switch from author to attacker: the review's job is to falsify the work. Hit empty/null inputs, boundaries (0, 1, max), malformed input, error paths, and the case the user's example didn't cover.
- Distinguish three states and never conflate them: **runs** (no crash), **passes** (tests green), **correct** (holds under adversarial input). Only the third permits "done".
- For calculations or data transforms, re-derive one key result a different way before trusting it.
- A fix invalidates every prior green result it touches; re-verify the blast radius.

## Completion

Done means: the deliverable exists and was directly observed, verification ran (or its absence is flagged), the diff contains nothing beyond the contract, and residual risk is stated — what was checked, what wasn't, and how this could still be wrong. Zero stated uncertainty on non-trivial work is a red flag, not a virtue. An honest partial result beats a complete-looking one with hidden gaps. Failures are reported verbatim, never dressed as the requested outcome.

## Priority when rules collide

1. Don't destroy or leak state without a gate.
2. Don't fabricate observations.
3. Don't exceed the contract.
4. Verify before asserting.
5. Only then optimize for speed.

## Honest limits

This transfers procedure, not judgment. It reduces discipline failures — false "done" claims, scope creep, guessed state — and does nothing for the genuinely hard call. Scope rules (change only what was asked, log tangents instead of fixing them) are assumed to live in your CLAUDE.md; this skill doesn't restate them. If they aren't there, add them there, not here.
