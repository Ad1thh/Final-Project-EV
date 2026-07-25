#!/usr/bin/env python3
import sys
import re

REG_MAP = {
    'zero': 0, 'ra': 1, 'sp': 2, 'gp': 3, 'tp': 4, 't0': 5, 't1': 6, 't2': 7,
    's0': 8, 'fp': 8, 's1': 9, 'a0': 10, 'a1': 11, 'a2': 12, 'a3': 13, 'a4': 14, 'a5': 15,
    'x0': 0, 'x1': 1, 'x2': 2, 'x3': 3, 'x4': 4, 'x5': 5, 'x6': 6, 'x7': 7,
    'x8': 8, 'x9': 9, 'x10': 10, 'x11': 11, 'x12': 12, 'x13': 13, 'x14': 14, 'x15': 15
}

def parse_reg(r):
    r = r.strip()
    if r in REG_MAP:
        return REG_MAP[r]
    if r.startswith('x'):
        val = int(r[1:])
        if 0 <= val <= 15:
            return val
    raise ValueError(f"Unknown register {r}")

def parse_imm(s):
    s = s.strip()
    return int(s, 0)

def assemble_file(in_path, out_path):
    with open(in_path, 'r') as f:
        raw_lines = f.readlines()

    # First pass: collect labels and clean lines
    cleaned = []
    labels = {}
    current_addr = 0

    for line in raw_lines:
        # Strip comments
        line = re.sub(r'#.*', '', line).strip()
        if not line:
            continue
        if ':' in line:
            parts = line.split(':', 1)
            label = parts[0].strip()
            labels[label] = current_addr
            line = parts[1].strip()
            if not line:
                continue
        
        # Handle pseudo-instructions expansion
        tokens = re.split(r'[\s,]+', line)
        op = tokens[0].lower()

        if op == 'nop':
            insts = [('addi', ['x0', 'x0', '0'])]
        elif op == 'mv':
            insts = [('addi', [tokens[1], tokens[2], '0'])]
        elif op == 'li':
            val = parse_imm(tokens[2])
            if -2048 <= val <= 2047:
                insts = [('addi', [tokens[1], 'x0', str(val)])]
            else:
                hi = (val + 0x800) >> 12
                lo = val - (hi << 12)
                insts = [
                    ('lui', [tokens[1], str(hi)]),
                    ('addi', [tokens[1], tokens[1], str(lo)])
                ]
        elif op == 'j':
            insts = [('jal', ['x0', tokens[1]])]
        else:
            insts = [(op, tokens[1:])]

        for inst_op, args in insts:
            cleaned.append((current_addr, inst_op, args))
            current_addr += 4

    # Second pass: encode instructions
    words = []
    for addr, op, args in cleaned:
        word = 0
        if op == 'ebreak':
            word = 0x00100073
        elif op == 'ecall':
            word = 0x00000073
        elif op in ['add', 'sub', 'sll', 'slt', 'sltu', 'xor', 'srl', 'sra', 'or', 'and']:
            rd = parse_reg(args[0])
            rs1 = parse_reg(args[1])
            rs2 = parse_reg(args[2])
            funct7_map = {'sub': 0x20, 'sra': 0x20}
            funct7 = funct7_map.get(op, 0x00)
            funct3_map = {
                'add': 0, 'sub': 0, 'sll': 1, 'slt': 2, 'sltu': 3,
                'xor': 4, 'srl': 5, 'sra': 5, 'or': 6, 'and': 7
            }
            funct3 = funct3_map[op]
            word = (funct7 << 25) | (rs2 << 20) | (rs1 << 15) | (funct3 << 12) | (rd << 7) | 0x33
        elif op in ['addi', 'slli', 'slti', 'sltiu', 'xori', 'srli', 'srai', 'ori', 'andi']:
            rd = parse_reg(args[0])
            rs1 = parse_reg(args[1])
            imm = parse_imm(args[2])
            funct3_map = {
                'addi': 0, 'slli': 1, 'slti': 2, 'sltiu': 3,
                'xori': 4, 'srli': 5, 'srai': 5, 'ori': 6, 'andi': 7
            }
            funct3 = funct3_map[op]
            if op == 'srai':
                imm = 0x400 | (imm & 0x1F)
            elif op in ['slli', 'srli']:
                imm = imm & 0x1F
            word = ((imm & 0xFFF) << 20) | (rs1 << 15) | (funct3 << 12) | (rd << 7) | 0x13
        elif op in ['lw', 'lh', 'lhu', 'lb', 'lbu']:
            rd = parse_reg(args[0])
            m = re.match(r'(-?\w+)\s*\(\s*(\w+)\s*\)', args[1])
            if not m:
                raise ValueError(f"Invalid memory operand {args[1]}")
            imm = parse_imm(m.group(1))
            rs1 = parse_reg(m.group(2))
            funct3_map = {'lb': 0, 'lh': 1, 'lw': 2, 'lbu': 4, 'lhu': 5}
            word = ((imm & 0xFFF) << 20) | (rs1 << 15) | (funct3_map[op] << 12) | (rd << 7) | 0x03
        elif op in ['sw', 'sh', 'sb']:
            rs2 = parse_reg(args[0])
            m = re.match(r'(-?\w+)\s*\(\s*(\w+)\s*\)', args[1])
            if not m:
                raise ValueError(f"Invalid memory operand {args[1]}")
            imm = parse_imm(m.group(1))
            rs1 = parse_reg(m.group(2))
            funct3_map = {'sb': 0, 'sh': 1, 'sw': 2}
            imm_hi = (imm >> 5) & 0x7F
            imm_lo = imm & 0x1F
            word = (imm_hi << 25) | (rs2 << 20) | (rs1 << 15) | (funct3_map[op] << 12) | (imm_lo << 7) | 0x23
        elif op in ['beq', 'bne', 'blt', 'bge', 'bltu', 'bgeu']:
            rs1 = parse_reg(args[0])
            rs2 = parse_reg(args[1])
            target = args[2]
            if target in labels:
                offset = labels[target] - addr
            else:
                offset = parse_imm(target)
            funct3_map = {'beq': 0, 'bne': 1, 'blt': 4, 'bge': 5, 'bltu': 6, 'bgeu': 7}
            imm12 = (offset >> 12) & 1
            imm10_5 = (offset >> 5) & 0x3F
            imm4_1 = (offset >> 1) & 0xF
            imm11 = (offset >> 11) & 1
            word = (imm12 << 31) | (imm10_5 << 25) | (rs2 << 20) | (rs1 << 15) | (funct3_map[op] << 12) | (imm4_1 << 8) | (imm11 << 7) | 0x63
        elif op == 'lui':
            rd = parse_reg(args[0])
            imm = parse_imm(args[1]) & 0xFFFFF
            word = (imm << 12) | (rd << 7) | 0x37
        elif op == 'auipc':
            rd = parse_reg(args[0])
            imm = parse_imm(args[1]) & 0xFFFFF
            word = (imm << 12) | (rd << 7) | 0x17
        elif op == 'jal':
            rd = parse_reg(args[0])
            target = args[1]
            if target in labels:
                offset = labels[target] - addr
            else:
                offset = parse_imm(target)
            imm20 = (offset >> 20) & 1
            imm10_1 = (offset >> 1) & 0x3FF
            imm11 = (offset >> 11) & 1
            imm19_12 = (offset >> 12) & 0xFF
            word = (imm20 << 31) | (imm10_1 << 21) | (imm11 << 20) | (imm19_12 << 12) | (rd << 7) | 0x6F
        elif op == 'jalr':
            rd = parse_reg(args[0])
            m = re.match(r'(-?\w+)\s*\(\s*(\w+)\s*\)', args[1])
            if m:
                imm = parse_imm(m.group(1))
                rs1 = parse_reg(m.group(2))
            else:
                rs1 = parse_reg(args[1])
                imm = parse_imm(args[2]) if len(args) > 2 else 0
            word = ((imm & 0xFFF) << 20) | (rs1 << 15) | (0 << 12) | (rd << 7) | 0x67
        else:
            raise ValueError(f"Unsupported instruction {op}")
        
        words.append(f"{word:08x}")

    with open(out_path, 'w') as f:
        for w in words:
            f.write(w + '\n')
    print(f"Assembled {len(words)} instructions -> {out_path}")

if __name__ == '__main__':
    if len(sys.argv) < 3:
        print("Usage: asm.py <in.s> <out.hex>")
        sys.exit(1)
    assemble_file(sys.argv[1], sys.argv[2])
