# Fault-Tolerant RISC-V Core — Research, Theoretical Foundations & Documentation

Welcome to the **`docs`** branch of the **Fault-Tolerant RV32E RISC-V Processor Project**.

This branch serves as the centralized repository for:
1. **Academic Literature & Research Papers:** Peer-reviewed IEEE/ACM publications establishing the theoretical foundation for radiation-hardening, selective modular redundancy, error-correcting codes (ECC), and fault-tolerant processor design.
2. **Project Documentation & Review Materials:** Review presentation slide decks, abstract submissions, comprehensive design specifications, and engineering handoff documentation.

---

## 📚 1. Research Papers & Theoretical Foundations (`Research_Papers/`)

The fault-tolerant features implemented across the RTL branches (`main`, `cadence`, `vitis-deployment`) directly originate from research into soft errors (Single Event Upsets - SEUs, and Multiple Bit Upsets - MBUs) caused by ionizing radiation, thermal noise, and electromagnetic interference in aerospace, automotive, and mission-critical edge environments.

| Document | Primary Focus & Theoretical Contribution | Application to this Project's RTL |
| :--- | :--- | :--- |
| **`A Low-Overhead Reconfigurable RISC-V.pdf`** | Explores dynamically reconfigurable redundancy for RISC-V soft cores, balancing power and fault coverage. | Inspired the core's **Dynamic Simplex / TMR Mode Control** via external pin `tmr_mode_pin` and MMIO control register `0xFFFF_FFF0`. |
| **`Effects of Workload on Radiation Vulnerability of RISC-V System-on-Chip.pdf`** | Quantifies architectural vulnerability factors (AVF) and demonstrates that ALU and register files experience the highest vulnerability during active computation. | Justified selective hardening: targeting the **ALU with Triplication** and **Register File with SEC-DED ECC** rather than triplicating the entire core (saving >45% silicon area). |
| **`Enhancing Fault Awareness and Reliability of a Fault-Tolerant RISC-V System-on-Chip.pdf`** | Proposes low-latency hardware diagnostic telemetry and error counters to report transient faults to supervisory systems. | Directly implemented as **Hardware Telemetry Flags**: `ecc_sec_1/2`, `ecc_ded_1/2`, `tmr_mismatch`, `tmr_fatal_mismatch`, and `dmr_error`. |
| **`I-COR Instruction-Level Fault Tolerance for Register File.pdf`** | Examines register file vulnerability to bit-flips and compares parity, Hamming codes, and instruction-level duplicate checking. | Led to the implementation of **Extended Hamming(38,32) SEC-DED** encoding for the 16x32-bit RV32E register file. |
| **`Implementation of FPGA based 32-bit RISC-V processor.pdf`** | Reference methodologies for mapping 3-stage and 5-stage RISC-V pipelines efficiently into FPGA Block RAM and distributed LUTs. | Guided the **3-Stage Pipeline (IF → ID/EX → WB)** and single-cycle unified BRAM memory interface. |
| **`Selective hardening of RISCV soft-processors for space applications.pdf`** | Investigates selective hardening of critical pipeline stages (program counter, instruction decoder, ALU) for cubesats and space avionics. | Direct blueprint for **TMR Program Counter Replicas (PC A/B/C)** and **Dual Modular Redundancy (DMR) Control Unit Checker**. |

---

## 📑 2. Project Review & Handoff Documentation (`pdf_and_docs/`)

This directory contains formal engineering documentation created throughout the design, verification, and evaluation lifecycle:

- **`Abstract - Zeroth Review.pdf`**: The foundational project abstract defining problem statement, motivation (aerospace/EV safety standards like ISO 26262 and DO-254), objectives, and preliminary methodology.
- **`Project_Final_v3.docx`**: Complete final project report detailing architectural specification, mathematical derivation of Hamming SEC-DED parity matrices, TMR voter logic, Cadence ASIC synthesis/PnR results, FPGA verification data, and fault injection analysis.
- **`Project_Handoff_v2.docx`**: Engineering handoff manual containing EDA tool setup instructions, script parameters, constraint file descriptions, and guidelines for extending the core with additional peripherals.
- **`RISC-V Project Review.pdf`**: Formal milestone presentation deck covering architectural block diagrams, verification waveforms, fault injection demos, and comparative area/power/timing metrics across baseline and fault-tolerant designs.

---

## 🗺️ 3. Cross-Branch Architecture Mapping

To see how the theoretical concepts in these papers are transformed into working hardware and software, navigate to the relevant project branches:

| Project Subsystem | Theoretical Source | Dedicated Branch | Implementation Highlights |
| :--- | :--- | :--- | :--- |
| **Baseline RV32E Core** | *Implementation of FPGA based 32-bit RISC-V* | [`RISC-V-Core`](https://github.com/Ad1thh/Final-Project-EV/tree/RISC-V-Core) | Golden 3-stage RV32E processor (no redundancy overhead), verified on Nexys-4 FPGA at 25 MHz with compliance suite. |
| **Cadence 90nm ASIC Flow** | *Selective hardening of RISCV soft-processors* | [`cadence`](https://github.com/Ad1thh/Final-Project-EV/tree/cadence) | Pure digital ASIC package: Genus synthesis, Innovus P&R layout, anti-pruning redundancy preservation rules, 100 MHz timing signoff, DRC/LVS clean netlists. |
| **Zynq SoC & Vitis Firmware** | *Enhancing Fault Awareness and Reliability* | [`vitis-deployment`](https://github.com/Ad1thh/Final-Project-EV/tree/vitis-deployment) | Digilent Zybo Zynq-7000 SoC co-design: ARM Cortex-A9 PS + RV32E PL, AXI GPIO bridge, Hardware-in-the-Loop (HIL) telemetry engine, and automated build scripts. |
| **3D Telemetry Dashboard** | *Enhancing Fault Awareness and Reliability* | [`arpith/corrections`](https://github.com/Ad1thh/Final-Project-EV/tree/arpith/corrections) | Next.js 15 + Three.js 3D web dashboard connecting to the hardware via Web Serial API to visualize real-time drone subsystems and fault injection. |
| **Continuous Auto-Sync** | *Project DevOps & Integration* | [`navaneeth/corrections`](https://github.com/Ad1thh/Final-Project-EV/tree/navaneeth/corrections) | Branch auto-synchronization infrastructure (GitHub Action + PowerShell daemon) and automated PDF utilization report generator. |
| **Full Master Integration** | *All Literature & Specifications* | [`main`](https://github.com/Ad1thh/Final-Project-EV/tree/main) | Complete unified codebase integrating RTL, ASIC, FPGA, SoC, Dashboard, and Verification suites. |

---

## 📖 4. Summary of Key Fault-Tolerant Mechanisms

### A. Extended Hamming(38,32) SEC-DED ECC (Register File)
- **Codeword Width:** 32 data bits + 6 parity bits + 1 overall parity bit = 39 bits per register entry.
- **Single-Bit Flip (SEC):** Corrected in combinational logic with zero pipeline stall cycles.
- **Double-Bit Flip (DED):** Non-correctable error flagged immediately; asserts `ecc_ded` trap and halts critical writes.

### B. Selective Triple Modular Redundancy (TMR ALU)
- **Instances:** Three parallel execution ALUs (`u_alu_0`, `u_alu_1`, `u_alu_2`).
- **Majority Voter:** Bitwise 2-of-3 majority logic with discrepancy detection (`tmr_mismatch`) and fatal failure detection (`tmr_fatal_mismatch`).
- **Power Optimization:** In Simplex Mode, operands to redundant ALUs are isolated to eliminate unnecessary dynamic switching power.

### C. Dual Modular Redundancy (DMR) Control Unit
- **Primary & Checker Decoders:** Run in lockstep decoding opcodes in parallel.
- **Fail-Safe Clamping:** In case of discrepancy (`dmr_error`), `mem_write` and `reg_write` are forcibly deasserted to prevent corrupted architectural state.

### D. TMR Program Counter
- **Replicas:** Triplicated PC registers (`pc_reg_a`, `pc_reg_b`, `pc_reg_c`) with 2-of-3 voting before instruction memory fetch.
