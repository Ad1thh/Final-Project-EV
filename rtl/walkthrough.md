# Walkthrough - 3-Stage Pipelined RV32E Synthesizable Processor Core

The synthesizable 3-stage pipelined RV32E processor core has been fully generated and placed under `c:\Users\hp\Downloads\Final_Project\rtl\`.

## 📁 Generated Deliverables

| File | Path | Description |
| :--- | :--- | :--- |
| **`riscv_pkg.sv`** | [rtl/riscv_pkg.sv](file:///c:/Users/hp/Downloads/Final_Project/rtl/riscv_pkg.sv) | SystemVerilog package with Opcodes, Funct3/7, ALU control, and WB selection enums |
| **`regfile.sv`** | [rtl/regfile.sv](file:///c:/Users/hp/Downloads/Final_Project/rtl/regfile.sv) | 16 x 32-bit RV32E Register File (2 async read ports, 1 sync write port, x0 hardwired to 0) |
| **`alu.sv`** | [rtl/alu.sv](file:///c:/Users/hp/Downloads/Final_Project/rtl/alu.sv) | 32-bit ALU supporting ADD, SUB, AND, OR, XOR, SLL, SRL, SRA, SLT, SLTU |
| **`control_unit.sv`** | [rtl/control_unit.sv](file:///c:/Users/hp/Downloads/Final_Project/rtl/control_unit.sv) | Instruction decoder generating execution, memory, writeback, and branch/trap control |
| **`hazard_unit.sv`** | [rtl/hazard_unit.sv](file:///c:/Users/hp/Downloads/Final_Project/rtl/hazard_unit.sv) | WB-to-ID/EX forwarding, 1-cycle load-use stall detector, and branch mispredict flusher |
| **`if_stage.sv`** | [rtl/if_stage.sv](file:///c:/Users/hp/Downloads/Final_Project/rtl/if_stage.sv) | Stage 1: PC register, PC+4 increment, branch/jump target mux, IF/ID pipeline register |
| **`id_ex_stage.sv`** | [rtl/id_ex_stage.sv](file:///c:/Users/hp/Downloads/Final_Project/rtl/id_ex_stage.sv) | Stage 2: Instruction decode, immediate generator, branch condition evaluation, ALU muxes, EX/WB pipeline register |
| **`wb_stage.sv`** | [rtl/wb_stage.sv](file:///c:/Users/hp/Downloads/Final_Project/rtl/wb_stage.sv) | Stage 3: Load alignment (LB, LBU, LH, LHU, LW), Writeback selection mux |
| **`riscv_core_top.sv`** | [rtl/riscv_core_top.sv](file:///c:/Users/hp/Downloads/Final_Project/rtl/riscv_core_top.sv) | Top-level integration of all 3 stages, memory interfaces, and debug signals |

---

## 🛠 Hardware Verification & Features

1. **ASIC Synthesizability (Cadence Genus 180nm)**:
   - 100% latch-free design: Every `case` statement includes a `default` arm; every `if` path is fully specified.
   - Clean clocking: All sequential elements are driven by `always_ff @(posedge clk or negedge rst_n)`.
   - Strict types: Uses SystemVerilog `logic` and `enum` types exclusively.
2. **Hazard Handling**:
   - **WB-to-ID/EX Data Forwarding**: Zero-cycle delay forwarding for RAW dependencies between Writeback and Decode/Execute.
   - **Load-Use Stall**: Automatically inserts a 1-cycle NOP bubble into ID/EX while freezing the PC and IF/ID pipeline register when a load target is consumed in the immediately following cycle.
   - **Branch / Jump Redirection**: Predict-not-taken microarchitecture. When a branch or jump is evaluated as taken in ID/EX, `flush_if_id` clears the fetched instruction to a NOP (`ADDI x0, x0, 0`) and redirects the PC.
