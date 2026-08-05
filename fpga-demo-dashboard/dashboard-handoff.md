# FPGA Demo Dashboard: Project Handoff & Architectural Decisions

## Overview
The FPGA Demo Dashboard is the primary visual interface for demonstrating the fault-tolerant capabilities of the RISC-V processor. It provides real-time visualization of fault injections (Single Error Correction, Double Error Detection, ALU faults) and demonstrates how the processor handles them (e.g., TMR recovery, ECC correction, degraded states).

**Main Priority:** A stable, reliable dashboard that successfully communicates the fault-tolerance demo during interim reviews without crashing or dropping frames.

## Current Architecture & Stack
- **Framework:** Next.js (App Router)
- **Styling:** Tailwind CSS (with specific utilities for glassmorphism and custom animations like `bg-radial-gradient` and `bg-grid-pattern`)
- **3D Rendering:** React Three Fiber (`@react-three/fiber`), Drei (`@react-three/drei`), and Three.js.
- **Animations:** Anime.js (used for UI panel staggered entrances and offset tweening).
- **State Management:** React Context (`DashboardContext.tsx`) managing fault states, system modes, and analytics history.

## Core Pages
1. **Live Diagnostics (`/`)**
   - The primary demo page.
   - Features a 3D drone model representing the system.
   - Live monitor showing register/ALU states during fault injection.
   - Control panel to trigger SEC, DED, and ALU faults.
2. **Analytics (`/analytics`)**
   - Displays real-time charts (via `recharts`) tracking the history and frequency of SEC and ALU/DED events over time.
3. **Subsystems (`/subsystems`)**
   - *Currently:* A complex 3D exploded view of the drone's internal components.
   - *Target State (Pending):* A simplified, static top-down wireframe view.

---

## Architectural Decision Record (ADR)

Based on recent reviews and the need to prioritize stability for the interim review, the following decisions have been finalized regarding the dashboard's UI/UX and animation stack.

### 1. The Subsystems Page Redesign
**Decision: Replace the current physics-driven 3D exploded view with a static wireframe top-down view.**

**Rationale:**
- The previous approach (multi-node staggered mesh explosion) introduced significant failure surfaces: drilling-depth bugs, color regressions, partial-tier-mapping bugs, conflicting animation clips, and bounding-box scale-matching issues.
- The new approach is the least risky option: A fixed camera angle over a static wireframe using `@react-three/drei`'s `Html` component for positioned hotspots.
- It eliminates animation conflicts, node-name matching complexities, and complex explosion math, ensuring a reliable demo experience.

### 2. Animation & UX Libraries (The "Cinematic" Rewrite)
**Decision: REJECT the proposed GSAP, Lenis, and Vanta.js integration.**

**Rationale (De-risking Scope Creep):**
- **Anime.js vs. GSAP:** Anime.js is already integrated, working correctly, and handling the offset-tweening patterns perfectly. Adding GSAP introduces redundant weight and overlaps in capability for zero net new functionality. We will stick with **Anime.js** for all animations (including count-ups and badge-pops).
- **Vanta.js:** Adding a second WebGL context (Vanta) alongside React Three Fiber is a massive performance risk. Two independent WebGL renderers competing for the same GPU on a demo laptop during live fault-injection could tank the framerate when stability is most critical.
- **Lenis Smooth-Scroll:** The dashboard's strength is its immediacy—a single-viewport control panel where the user clicks a button and instantly sees a reaction. Converting this into a scroll-driven narrative adds unnecessary interaction complexity (syncing scroll states with the R3F render loop) and dilutes the impact of the live demo. 

**Verdict:** The dashboard must remain a focused, single-viewport, highly reliable live control panel.

---

## Next Steps for Development

1. **Execute the Subsystems Refactor:**
   - Remove the complex `SubsystemsDroneModel.tsx` explosion logic.
   - Implement the static, top-down wireframe camera angle.
   - Place fixed `<Html>` labels over the CPU, ALU, Registers, etc.

2. **Refine Existing Animations:**
   - Continue using `anime.js` for any UI panel transitions or number counters. Do not install GSAP.

3. **Focus on Core Project Priorities:**
   - With the dashboard stabilized and the cinematic rewrite deferred, engineering effort must shift back to the critical path: **RTL merge status, FPGA UART work, and the synthesis phase.**

## Running the Dashboard
```bash
# Install dependencies
npm install

# Run the development server
npm run dev
```
Open `http://localhost:3000` to view the application.
