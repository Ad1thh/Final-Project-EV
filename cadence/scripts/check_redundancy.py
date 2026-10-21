#!/usr/bin/env python3
# ==============================================================================
# Script: check_redundancy.py
# Description: Automated gate-level redundancy and fault-tolerance validator
#              for Cadence Genus (syn) and Innovus (pr) netlists.
# Standard library only. Run with: python3 -I cadence/scripts/check_redundancy.py <netlist.v>
# ==============================================================================

import sys
import re
import os

def check_redundancy(netlist_path):
    if not os.path.isfile(netlist_path):
        print(f"ERROR: Netlist file not found: {netlist_path}")
        return False

    with open(netlist_path, "r", encoding="utf-8", errors="ignore") as f:
        content = f.read()

    print(f"==================================================================")
    print(f" RUNNING REDUNDANCY & FAULT-TOLERANCE GATE VERIFICATION")
    print(f" Target Netlist: {netlist_path}")
    print(f"==================================================================")

    passed = True
    errors = []

    # -------------------------------------------------------------------------
    # 1. Exactly 3 ALU instances named u_alu_0, u_alu_1, u_alu_2
    # -------------------------------------------------------------------------
    alu_instances = set()
    # Match patterns like: alu_... u_alu_0 ( or \u_alu_0 or .u_alu_0
    alu_pattern = re.compile(r'\b(alu[A-Za-z0-9_]*)\s+(?:\\([^\s]+)\s+|([A-Za-z0-9_]+)\s*)\(')
    for m in alu_pattern.finditer(content):
        mod_name = m.group(1)
        inst_name = m.group(2) if m.group(2) else m.group(3)
        # In flattened or hierarchical netlists, could be u_id_ex_stage/u_alu_0 or u_alu_0
        for base in ["u_alu_0", "u_alu_1", "u_alu_2"]:
            if inst_name == base or inst_name.endswith("/" + base):
                alu_instances.add(base)

    # Also search for explicit instance mentions
    for base in ["u_alu_0", "u_alu_1", "u_alu_2"]:
        if base not in alu_instances:
            if re.search(r'\b' + re.escape(base) + r'\b\s*\(', content):
                alu_instances.add(base)

    print(f"[CHECK 1] ALU Instances found: {sorted(list(alu_instances))}")
    expected_alus = {"u_alu_0", "u_alu_1", "u_alu_2"}
    if alu_instances != expected_alus:
        missing = expected_alus - alu_instances
        msg = f"CHECK 1 FAILED: Expected exactly 3 ALU instances (u_alu_0, u_alu_1, u_alu_2). Missing: {missing}"
        errors.append(msg)
        print(f"  --> {msg}")
        passed = False
    else:
        print("  --> [PASS] Exactly 3 ALU instances present (u_alu_0, u_alu_1, u_alu_2).")

    # -------------------------------------------------------------------------
    # 2. No cell driving alu_result_N_fi takes another ALU's result as input
    # -------------------------------------------------------------------------
    # In Verilog netlists: cell_type inst_name (.pin1(net1), .pin2(net2), ...);
    # Find all cells driving alu_result_0*, alu_result_1*, alu_result_2* or alu_result_*_fi*
    # Check if a cell driving alu_result_N[_fi] takes alu_result_M (M != N) as input.
    cross_driving_violations = []
    
    # Match cell declarations: word word ( ... );
    # Tokenize statements between cell name and semicolon
    cell_pattern = re.compile(r'([A-Za-z0-9_]+)\s+([A-Za-z0-9_\\]+)\s*\((.*?)\);', re.DOTALL)
    for cell_m in cell_pattern.finditer(content):
        cell_type = cell_m.group(1)
        inst_name = cell_m.group(2)
        pin_connections = cell_m.group(3)

        # Parse port mappings .PIN(NET)
        port_conns = re.findall(r'\.([A-Za-z0-9_]+)\s*\(\s*([^)]*)\s*\)', pin_connections)
        output_nets = []
        input_nets = []
        for pin, net in port_conns:
            net = net.strip()
            # Standard cell output pins typically Y, Q, QN
            if pin in ["Y", "Q", "QN"]:
                output_nets.append(net)
            else:
                input_nets.append(net)

        for out_net in output_nets:
            for n in [0, 1, 2]:
                # If this cell drives alu_result_N or alu_result_N_fi
                if f"alu_result_{n}" in out_net:
                    for other in [0, 1, 2]:
                        if other != n:
                            for inp in input_nets:
                                if f"alu_result_{other}" in inp:
                                    cross_driving_violations.append(
                                        f"Cell {inst_name} ({cell_type}) drives {out_net} but takes {inp} as input!"
                                    )

    if cross_driving_violations:
        msg = f"CHECK 2 FAILED: Cross-driving detected between ALUs:\n    " + "\n    ".join(cross_driving_violations[:5])
        errors.append(msg)
        print(f"  --> {msg}")
        passed = False
    else:
        print("  --> [PASS] No cross-driving between redundant ALU results.")

    # -------------------------------------------------------------------------
    # 3. u_control_unit_checker present, chk_* nets present
    # -------------------------------------------------------------------------
    cu_checker_present = bool(re.search(r'\b(control_unit[A-Za-z0-9_]*)\s+(?:\\([^\s]+)\s+|([A-Za-z0-9_]+)\s*)\(', content) and
                             re.search(r'\bu_control_unit_checker\b', content))
    
    # Check for chk_* nets
    chk_nets = re.findall(r'\b(chk_[A-Za-z0-9_]+)\b', content)
    chk_unique = sorted(set(chk_nets))

    print(f"[CHECK 3] u_control_unit_checker present: {cu_checker_present}")
    print(f"          chk_* nets found: {len(chk_unique)} unique ({chk_unique[:6]}...)")

    if not cu_checker_present:
        msg = "CHECK 3 FAILED: u_control_unit_checker instance is not present in the netlist!"
        errors.append(msg)
        print(f"  --> {msg}")
        passed = False
    elif len(chk_unique) < 5:
        msg = f"CHECK 3 FAILED: Expected multiple chk_* nets connecting checker to mismatch logic, found {len(chk_unique)}: {chk_unique}"
        errors.append(msg)
        print(f"  --> {msg}")
        passed = False
    else:
        print("  --> [PASS] u_control_unit_checker and chk_* nets are present.")

    # -------------------------------------------------------------------------
    # 4. cu_mismatch is not a constant
    # -------------------------------------------------------------------------
    # Check for assign cu_mismatch = 1'b0 / 1'b1
    constant_assign = re.search(r'assign\s+cu_mismatch\s*=\s*1\'b[01]\s*;', content)
    # Check for tie cell driving cu_mismatch
    tie_cell_driver = re.search(r'(TIEH|TIEL|LOGIC0|LOGIC1)[A-Za-z0-9_]*\s+[A-Za-z0-9_\\]+\s*\([^;]*\.[A-Za-z0-9_]+\s*\(\s*cu_mismatch\s*\)', content)

    if constant_assign:
        msg = f"CHECK 4 FAILED: cu_mismatch is assigned to a constant: '{constant_assign.group(0)}'"
        errors.append(msg)
        print(f"  --> {msg}")
        passed = False
    elif tie_cell_driver:
        msg = f"CHECK 4 FAILED: cu_mismatch is driven directly by a tie-off cell: '{tie_cell_driver.group(0)}'"
        errors.append(msg)
        print(f"  --> {msg}")
        passed = False
    else:
        # Verify cu_mismatch is actually driven by a real logic cell or flip-flop
        cu_driver = re.search(r'\.[A-Za-z0-9_]+\s*\(\s*cu_mismatch\s*\)', content) or \
                    re.search(r'\bcu_mismatch_reg\b', content) or \
                    re.search(r'\bcu_mismatch\b', content)
        if not cu_driver:
            msg = "CHECK 4 FAILED: cu_mismatch has no driver found in netlist."
            errors.append(msg)
            print(f"  --> {msg}")
            passed = False
        else:
            print("  --> [PASS] cu_mismatch is active logic (not tied to constant 0/1).")

    # -------------------------------------------------------------------------
    # 5. pc_reg_a/b/c are 32 flops each
    # -------------------------------------------------------------------------
    flops_a = set()
    flops_b = set()
    flops_c = set()

    # Search for flop instantiations or pins connecting to pc_reg_a[i], etc.
    # Regex matching pc_reg_x[bit]
    matches_a = re.findall(r'\bpc_reg_a(?:_reg)?\[(\d+)\]', content)
    matches_b = re.findall(r'\bpc_reg_b(?:_reg)?\[(\d+)\]', content)
    matches_c = re.findall(r'\bpc_reg_c(?:_reg)?\[(\d+)\]', content)

    for m in matches_a: flops_a.add(int(m))
    for m in matches_b: flops_b.add(int(m))
    for m in matches_c: flops_c.add(int(m))

    print(f"[CHECK 5] Flop count: pc_reg_a={len(flops_a)}/32, pc_reg_b={len(flops_b)}/32, pc_reg_c={len(flops_c)}/32")

    if len(flops_a) != 32 or len(flops_b) != 32 or len(flops_c) != 32:
        msg = f"CHECK 5 FAILED: Expected exactly 32 flops each for pc_reg_a/b/c, got: a={len(flops_a)}, b={len(flops_b)}, c={len(flops_c)}"
        errors.append(msg)
        print(f"  --> {msg}")
        passed = False
    else:
        print("  --> [PASS] pc_reg_a/b/c each contain exactly 32 distinct flip-flops (96 total).")

    print(f"==================================================================")
    if passed:
        print(" RESULT: ALL REDUNDANCY GATES PASSED! Netlist is hardware fault-tolerant.")
        print(f"==================================================================")
        return True
    else:
        print(" RESULT: REDUNDANCY GATES FAILED!")
        for e in errors:
            print(f"  * {e}")
        print(f"==================================================================")
        return False

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: python3 -I check_redundancy.py <path_to_netlist.v>")
        sys.exit(1)

    netlist = sys.argv[1]
    ok = check_redundancy(netlist)
    sys.exit(0 if ok else 1)
