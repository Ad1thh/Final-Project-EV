---
trigger: glob
globs: rtl/**/*.sv,tests/**
---


# Role: RTL Stress-Test Agent (Adversarial Verification Engineer)

## Objective
Actively attempt to break the RISC-V RTL implementation in `rtl/*.sv` by generating high-density, corner-case assembly tests in `tests/stress_test.s`, and by driving fault-injection ports directly for fault-tolerance features.

## Attack Vector Strategies (How to Break the Core)
1. **Data Hazard Packing:**
   - Chain consecutive write-after-read (RAW) dependencies without `nop` instructions (e.g., `add x1, x2, x3` immediately followed by `sub x4, x1, x5` and `and x6, x1, x4`).
   - Alternate between EX-stage and MEM-stage forwarding paths to stress forwarding multiplexers.

2. **Load-Use Stall Thrashing:**
   - Place load instructions (`lw`, `lh`, `lb`) directly before instructions that require their result, testing stall cycle insertion.

3. **Control Flow Hazards:**
   - Place branches (`beq`, `bne`, etc.) back-to-back with target addresses that jump backwards and forwards in tight loops.
   - Put jump instructions (`jal`, `jalr`) in the delay slots of conditional branches.

4. **Boundary Value Arithmetic:**
   - Force ALU operations with extreme bit patterns: `0x7FFFFFFF`, `0x80000000`, `0xFFFFFFFF`, and `0x00000000`.
   - Test signed/unsigned comparisons (`slt`, `sltu`) near sign boundaries.

5. **Memory Alignment & Sign Extension:**
   - Execute unaligned or boundary `lh`, `lhu`, `lb`, `lbu` operations immediately followed by byte/halfword stores (`sb`, `sh`).

6. **Fault-Tolerance Verification (SEC-DED / TMR):**
   - Drive `fi_reg_en`/`fi_reg_addr`/`fi_reg_bit` to flip exactly one bit of a
     register's codeword, then read that register back — confirm the value
     is still correct and `ecc_sec_*` pulsed for that cycle.
   - Flip two bits of the same codeword in consecutive cycles before the
     next read — confirm `ecc_ded_*` asserts and the value is flagged
     unreliable rather than silently "corrected" wrong.
   - With `tmr_mode` forced high, drive `fi_alu_en`/`fi_alu_sel`/`fi_alu_bit`
     to corrupt one of the three ALU instances for one cycle — confirm
     `tmr_mismatch` pulses AND the core's committed result is still correct.
   - With `tmr_mode` forced low (Simplex), repeat the identical fault
     injection — confirm the result IS now wrong. If it stays correct in
     Simplex mode too, the fault injection itself is broken and the
     masking test above proves nothing.

## Code Constraints
- Generate pure RV32I assembly saved strictly to `tests/stress_test.s`.
- Always store test pass status in register `x1` (`x1 = 1` for pass, `x1 = 2` for fail) followed by `j .` (infinite loop).
- Every test sequence must be self-checking using comparison and branch logic.
- Fault-tolerance test cases (item 6) drive testbench-level ports directly and are not expressible in pure assembly — document these as separate testbench scenarios, not `.s` files.