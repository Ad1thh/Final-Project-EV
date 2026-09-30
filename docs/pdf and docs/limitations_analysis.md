# Analysis of Omitted Fault-Tolerance Features

While this processor implements advanced fault-tolerance mechanisms like ALU Triple Modular Redundancy (TMR) and Register File ECC, a review of standard high-reliability literature reveals a few critical vulnerabilities in the current design. 

This document explains what was missed, in simple terms, and evaluates how crucial these omissions are to the actual reliability of the project.

---

## 1. Main Memory (Instruction & Data) Protection
**What is missing:**  
The processor has a 32 KB Unified Block RAM that holds all the instructions (the program itself) and the data. This memory block does not have ECC (Error Correction Code) protection in the RTL design. 

**Why it is crucial (High Impact):**  
This is the most significant vulnerability in the project. The Register File is protected, but if a radiation particle flips a bit in the Main Memory:
*   **Instruction Corruption:** The CPU might fetch a corrupted instruction (e.g., turning a harmless `ADD` into a fatal `JUMP` to nowhere).
*   **Data Corruption:** Variables stored in memory will be silently corrupted. 
Because main memory is physically much larger than the register file, it has a much higher probability of being hit by a transient fault.

## 2. Control Unit and Program Counter (PC) Protection
**What is missing:**  
The ALU (which does the math) is triplicated (TMR), but the Control Unit (the "brain" that decodes instructions and tells the processor what to do) and the Program Counter (which tracks what line of code is running) are completely unprotected.

**Why it is crucial (High Impact):**  
If the ALU makes a mistake, the voter catches it. But if a fault hits the Control Unit, it could tell the ALU to do the wrong operation entirely, or worse, tell the memory to overwrite critical data. If a fault hits the Program Counter, the processor will instantly crash by jumping to an invalid memory address. Protecting the data path without protecting the control path leaves a massive single point of failure.

## 3. Memory Scrubbing
**What is missing:**  
A "Memory Scrubber" is a background hardware process that constantly reads memory, checks it for single-bit errors using ECC, and writes back the corrected data. 

**Why it is crucial (Medium Impact):**  
ECC can correct a single bit flip. But if a register sits unused for a long time, a second radiation particle might hit that same register. Now you have two flipped bits, which ECC cannot fix, leading to a fatal crash. A scrubber prevents errors from accumulating. 
However, because this project uses a tiny 16-entry register file (RV32E), registers are constantly overwritten by the running program anyway. Therefore, the lack of a scrubber is a vulnerability, but statistically much less likely to cause a crash than the unprotected main memory.

## 4. Bus / Interconnect Protection
**What is missing:**  
There is no parity or error checking on the internal wires connecting the CPU to the memory.

**Why it is crucial (Low Impact):**  
In massive processors, data travels long distances across internal buses, meaning the data can be corrupted *in transit*. However, because this is a small embedded core with tightly coupled memory, the physical wires are extremely short. The chance of a fault hitting the data exactly while it is moving across the wire is incredibly low compared to a fault hitting the memory cells themselves.

---

## Summary
The current architecture successfully demonstrates how to protect the *execution* of data (ALU) and the *temporary storage* of data (Registers). However, to be considered a true aerospace-grade processor, **adding ECC to the Main Memory** and **adding redundancy to the Control Unit / PC** would be absolutely necessary, as a failure in either of those unprotected areas will immediately crash the entire system.
