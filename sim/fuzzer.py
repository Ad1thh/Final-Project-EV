#!/usr/bin/env python3
import sys
import random

NUM_REGS = 16
NUM_INSTRS = int(sys.argv[1]) if len(sys.argv) > 1 else 2000
OUTPUT_FILE = "tests/stress_test.s"

MASK32 = 0xFFFFFFFF

def to_u32(val):
    return val & MASK32

def to_s12(val):
    val = val & 0xFFF
    return val - 0x1000 if (val & 0x800) else val

def to_s32(val):
    val = val & MASK32
    return val - 0x100000000 if (val & 0x80000000) else val

def get_hi_lo(val):
    val = val & MASK32
    hi = ((val + 0x800) >> 12) & 0xFFFFF
    lo = to_s12(val & 0xFFF)
    return hi, lo

regs = [0] * NUM_REGS

def generate_fuzz_test():
    lines = [
        "_start:",
        "    li x1, 0"
    ]

    for r in range(2, NUM_REGS - 2):
        val = random.randint(0, 0xFFFFFFFF)
        regs[r] = val
        hi, lo = get_hi_lo(val)
        lines.append(f"    lui x{r}, {hi}")
        lines.append(f"    addi x{r}, x{r}, {lo}")

    lines.append("    # --- BEGIN CONSTRAINED RANDOM FUZZING ---")
    avail_regs = list(range(1, 14))

    for i in range(NUM_INSTRS):
        op = random.choice([
            "add", "sub", "and", "or", "xor", "sll", "srl", "sra",
            "slt", "sltu", "addi", "andi", "ori", "xori", "slli", "srli", "srai"
        ])

        rd = random.choice(avail_regs)
        rs1 = random.choice(avail_regs)
        rs2 = random.choice(avail_regs)
        imm = random.randint(-2048, 2047)
        shamt = random.randint(0, 31)

        val1 = regs[rs1]
        val2 = regs[rs2]

        if op == "add":
            regs[rd] = to_u32(val1 + val2)
            lines.append(f"    add x{rd}, x{rs1}, x{rs2}")
        elif op == "sub":
            regs[rd] = to_u32(val1 - val2)
            lines.append(f"    sub x{rd}, x{rs1}, x{rs2}")
        elif op == "and":
            regs[rd] = to_u32(val1 & val2)
            lines.append(f"    and x{rd}, x{rs1}, x{rs2}")
        elif op == "or":
            regs[rd] = to_u32(val1 | val2)
            lines.append(f"    or x{rd}, x{rs1}, x{rs2}")
        elif op == "xor":
            regs[rd] = to_u32(val1 ^ val2)
            lines.append(f"    xor x{rd}, x{rs1}, x{rs2}")
        elif op == "sll":
            shift = val2 & 0x1F
            regs[rd] = to_u32(val1 << shift)
            lines.append(f"    sll x{rd}, x{rs1}, x{rs2}")
        elif op == "srl":
            shift = val2 & 0x1F
            regs[rd] = to_u32(val1 >> shift)
            lines.append(f"    srl x{rd}, x{rs1}, x{rs2}")
        elif op == "sra":
            shift = val2 & 0x1F
            s_val1 = to_s32(val1)
            regs[rd] = to_u32(s_val1 >> shift)
            lines.append(f"    sra x{rd}, x{rs1}, x{rs2}")
        elif op == "slt":
            regs[rd] = 1 if to_s32(val1) < to_s32(val2) else 0
            lines.append(f"    slt x{rd}, x{rs1}, x{rs2}")
        elif op == "sltu":
            regs[rd] = 1 if val1 < val2 else 0
            lines.append(f"    sltu x{rd}, x{rs1}, x{rs2}")
        elif op == "addi":
            regs[rd] = to_u32(val1 + imm)
            lines.append(f"    addi x{rd}, x{rs1}, {imm}")
        elif op == "andi":
            imm_u = to_u32(imm)
            regs[rd] = to_u32(val1 & imm_u)
            lines.append(f"    andi x{rd}, x{rs1}, {imm}")
        elif op == "ori":
            imm_u = to_u32(imm)
            regs[rd] = to_u32(val1 | imm_u)
            lines.append(f"    ori x{rd}, x{rs1}, {imm}")
        elif op == "xori":
            imm_u = to_u32(imm)
            regs[rd] = to_u32(val1 ^ imm_u)
            lines.append(f"    xori x{rd}, x{rs1}, {imm}")
        elif op == "slli":
            regs[rd] = to_u32(val1 << shamt)
            lines.append(f"    slli x{rd}, x{rs1}, {shamt}")
        elif op == "srli":
            regs[rd] = to_u32(val1 >> shamt)
            lines.append(f"    srli x{rd}, x{rs1}, {shamt}")
        elif op == "srai":
            s_val1 = to_s32(val1)
            regs[rd] = to_u32(s_val1 >> shamt)
            lines.append(f"    srai x{rd}, x{rs1}, {shamt}")

        if (i + 1) % 15 == 0:
            target_r = random.choice(avail_regs)
            exp_val = regs[target_r]
            hi, lo = get_hi_lo(exp_val)
            lines.append(f"    # --- VERIFY x{target_r} ---")
            lines.append(f"    lui x14, {hi}")
            lines.append(f"    addi x14, x14, {lo}")
            lines.append(f"    bne x{target_r}, x14, test_fail")

    lines.extend([
        "test_pass:",
        "    li x1, 1",
        "    ebreak",
        "test_fail:",
        "    li x1, 2",
        "    ebreak"
    ])

    with open(OUTPUT_FILE, "w") as f:
        f.write("\n".join(lines) + "\n")

    print(f"[FUZZER] Successfully generated {NUM_INSTRS} instructions in {OUTPUT_FILE}")

if __name__ == "__main__":
    if len(sys.argv) > 2:
        random.seed(int(sys.argv[2]))
    generate_fuzz_test()
