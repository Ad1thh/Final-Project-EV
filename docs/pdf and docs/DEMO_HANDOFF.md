# Demo Handoff — Fault-Injection & Recovery Live Demonstrator

## Purpose of this document
This describes a **separate, additive deliverable**: a live, physical (and
optionally browser-mirrored) demonstration of the fault-tolerance mechanisms
already implemented and verified in the core RTL (SEC-DED register file,
selective TMR execute stage). It exists for exhibition/review presentation
purposes (Srishti, final review) — it is NOT part of the core project thesis,
does not affect the Genus/Innovus synthesis deliverable, and should not
consume time budgeted for that phase.

**Explicit non-goal:** this is not a UAV, drone, or sensor-fusion project.
Do not let scope drift toward building application-layer mission logic
(altitude/battery/GPS decision trees, etc.) — that is a different project
with a different thesis and was deliberately rejected in favor of the
narrower demo described below. See "Why this scope, and not the alternative"
at the end of this document if that decision needs to be re-justified later.

---

## The core idea, in one sentence
Make the invisible visible: a person watches a switch trigger a specific,
named fault, and watches an LED / display confirm the core detected or
corrected it — in real time, repeatably, with no explanation required to
understand that *something broke and the system caught it*.

---

## What this demo is (and is not)

**Is:**
- A Nexys 4 FPGA board running the existing core (or the isolated
  regfile/TMR modules — decide based on how much of the full pipeline you
  want visibly running vs. just the fault-tolerance blocks).
- Switches/buttons that trigger specific, pre-defined faults using the
  fault-injection ports that already exist in the RTL.
- LEDs (and optionally a small display) that show the resulting status
  flags changing live.
- Optionally, a laptop running a browser dashboard that mirrors the same
  events over UART for people who want more visual depth than switches/LEDs.

**Is not:**
- A UAV/drone simulation or mission-decision system.
- Dependent on real sensors (a potentiometer as a toy "sensor value" input
  is fine and optional — see Phase 3 below — but not required for the core
  demo to work).
- A hardware-in-the-loop telemetry system with a UAV simulator on a laptop.

---

## Signals involved (already exist in the RTL — confirm exact names against
the current branch before wiring, this list reflects the state at time of
writing)

**Fault injection inputs (drive these from switches/buttons):**
- `fi_reg_en`, `fi_reg_addr[3:0]`, `fi_reg_bit[5:0]` — register file fault
  injection (single-cycle pulse).
- `fi_alu_en`, `fi_alu_sel`, `fi_alu_bit` — ALU-instance fault injection
  (single-cycle pulse).
- Mode-control register / `tmr_mode_pin` — toggles Simplex vs. TMR mode.

**Status outputs (drive these to LEDs):**
- `ecc_sec_1` / `ecc_sec_2` — "SEC corrected" (single-bit error corrected).
- `ecc_ded_1` / `ecc_ded_2` — "DED detected" (double-bit error detected,
  uncorrectable).
- `tmr_mismatch` — TMR voter detected disagreement between ALU instances.
- Whatever "operation result correct / incorrect" signal is cheapest to
  expose for a live pass/fail LED — confirm against current wb_stage.sv or
  id_ex_stage.sv output naming.

---

## Phased build plan

### Phase 1 — Minimal switch/LED demo (do this first, smallest scope)
- Map 3-4 switches to: select target register, select target bit, select
  ALU instance, select TMR mode on/off.
- Map 1 button to: pulse the fault-injection enable signal.
- Map 3-4 LEDs to: SEC corrected, DED detected, TMR mismatch, pass/fail of
  the current operation.
- No UART, no display, no sensors. Confirm this works reliably and
  repeatably at a table before adding anything else.
- Reuses the `.xdc` constraints file already present in the repo as the
  starting point for pin mapping — confirm switch/LED/button pin
  assignments match the actual Nexys 4 pinout, don't assume the existing
  `.xdc` already covers this (it was created for a different purpose;
  audit it before relying on it).

### Phase 2 — Seven-segment / small display for live value
- Show the actual register value (or ALU result) on the seven-segment
  display, so a viewer watches the number visibly corrupt and then snap
  back to correct when SEC-DED fires, or watches the TMR-masked result
  stay stable while the mismatch LED blinks.
- This is the single highest-impact addition for a non-technical viewer —
  prioritize this over Phase 3.

### Phase 3 — Optional: one toy "sensor" input
- A single potentiometer feeding an ADC value into a register, purely as
  a visually interesting "real-world value" for the display in Phase 2.
- Explicitly optional — the demo is complete and effective without this.
  Do not expand this into multiple sensors or a sensor-fusion narrative.

### Phase 4 — Optional: browser dashboard mirror over UART
- A simple browser page showing register file state, ECC status, ALU
  triple + voter output, updated live from UART messages sent whenever a
  fault-injection event occurs on the board.
- Useful for a laptop sitting next to the board at an exhibition so people
  can see "under the hood" without needing to understand raw LEDs.
- This can also exist as a **standalone software-only artifact** (no FPGA
  connection at all) for early demonstration purposes before the physical
  board is ready — worth building this first if a demo is needed sooner
  than the FPGA bring-up timeline allows.

---

## Timeline guidance — do not let this compete with synthesis time

This entire demo (Phases 1-2) should be scoped as **a few days of effort**,
not weeks, and should be scheduled either:
- In parallel with early Genus/Innovus learning/setup by a teammate who
  isn't the bottleneck on synthesis, or
- After synthesis/floorplan is far enough along that time can be safely
  diverted.

Do NOT let demo-building eat into the month already (correctly) budgeted
for the Cadence flow. If forced to choose between finishing the demo and
finishing synthesis, synthesis wins — the demo does not exist without a
core to demonstrate, and the synthesis deliverable is the one your guide
is actually grading against the original architecture spec.

---

## Why this scope, and not the alternative (UAV/sensor-suite demo)

An earlier idea explored building this as a full UAV mission-safety
demonstrator (altitude/battery/GPS inputs, a mission-decision state
machine, sensor telemetry over UART, a full hardware-in-the-loop
simulator). This was deliberately rejected:
- It introduces an entire application-logic layer (the mission-decision
  state machine) that has no connection to the actual thesis of this
  project (fault-tolerant computation), meaning new code, new bugs, and
  new verification surface in service of a demo narrative rather than the
  core research claim.
- If asked "why is a fault-tolerant RV32E core specifically suited to UAV
  mission logic," there isn't a real answer — the connection is narrative,
  not technical.
- The effort cost (sensors, wiring reliability at an exhibition, a second
  simulator, UAV state-machine logic) is disproportionate to what it adds
  over the simpler causal demo above, which already achieves the actual
  goal: making the fault-tolerance mechanism visibly provable to a
  non-technical viewer in real time.

If this decision needs to be revisited, it should be re-justified against
these specific points, not re-adopted by default because it sounds more
impressive on paper.
