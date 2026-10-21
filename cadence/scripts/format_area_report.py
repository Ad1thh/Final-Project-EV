#!/usr/bin/env python3
"""
Script: format_area_report.py
Description: Parse Cadence Innovus hierarchical area report (innovus_area.rpt)
             and generate clean markdown tables for documentation.
"""
import sys
import re

def parse_area_report(report_path):
    with open(report_path, 'r') as f:
        lines = f.readlines()

    header_found = False
    modules = []

    for line in lines:
        line_str = line.strip()
        if not line_str or line_str.startswith('---'):
            continue
        if line_str.startswith('Hinst Name'):
            header_found = True
            continue
        if not header_found:
            continue

        parts = line.split()
        if len(parts) >= 4:
            # First part is Hinst Name
            hinst = parts[0]
            # Next parts may have module name
            # Let's check numerical fields from the end
            try:
                phys = float(parts[-1])
                macro = float(parts[-2])
                cg = float(parts[-3])
                latch = float(parts[-4])
                flop = float(parts[-5])
                comb = float(parts[-6])
                inv = float(parts[-7])
                buf = float(parts[-8])
                total_area = float(parts[-9])
                inst_count = int(parts[-10])
                mod_name = " ".join(parts[1:-10]) if len(parts) > 11 else ""
                modules.append({
                    'hinst': hinst,
                    'module': mod_name,
                    'inst_count': inst_count,
                    'total_area': total_area,
                    'buf': buf,
                    'inv': inv,
                    'comb': comb,
                    'flop': flop,
                    'latch': latch,
                    'cg': cg,
                })
            except (ValueError, IndexError):
                continue

    return modules

def format_markdown_table(modules):
    md = []
    md.append("| Hierarchy / Subsystem | Module | Cell Count | Total Area (µm²) | Area Share (%) |")
    md.append("| :--- | :--- | :---: | :---: | :---: |")

    top_area = modules[0]['total_area'] if modules else 1.0

    for m in modules:
        h = m['hinst']
        # Determine indentation level
        depth = h.count('/')
        prefix = "&nbsp;&nbsp;" * depth + ("└── " if depth > 0 else "")
        short_name = h.split('/')[-1] if depth > 0 else h
        pct = (m['total_area'] / top_area) * 100.0
        mod_label = f"`{m['module']}`" if m['module'] else "-"
        md.append(f"| {prefix}**{short_name}** | {mod_label} | {m['inst_count']:,} | {m['total_area']:.2f} | {pct:.1f}% |")

    return "\n".join(md)

if __name__ == '__main__':
    path = sys.argv[1] if len(sys.argv) > 1 else 'cadence/reports/innovus_area.rpt'
    mods = parse_area_report(path)
    print(format_markdown_table(mods))
