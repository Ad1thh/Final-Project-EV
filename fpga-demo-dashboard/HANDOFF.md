# Subsystems Exploded View — Investigation & Fix Handoff

**Date:** 2026-08-05
**Branch:** merged to `main` at `ef42514` (working branch deleted)
**Live:** https://drone-dashboard-three.vercel.app

---

## 0. TL;DR

The subsystems exploded view was **not** a design failure that needed replacing. It was a
single arithmetic mistake that threw every part off-screen. It is fixed, along with four
other real bugs found on the way — one of which (a white scene background) was affecting
**both** the dashboard and the subsystems page.

**The previous handoff's plan to replace the exploded view with a static wireframe is no
longer necessary.** Its rejection of GSAP / Lenis / Vanta.js still stands, and is
reinforced below.

---

## 1. The original question: is the exploded view fixable?

Yes. Root cause, in one sentence:

> The explode offsets were written in the GLB's raw local units against hand-derived scale
> factors, ignoring the `normScale = 4/maxDim ≈ 1.82` wrapper the model actually renders
> inside — and the shipped constants were roughly 5× the values the file's own comment
> block had derived.

### Evidence

The camera sits at radius 11.5 with a 50° fov, so it frames about **±5.36 world units**
vertically. Computed directly from `rc_quadcopter_v3.glb` using the old constants:

| Part | Final world Y (before) |
|---|---|
| Shell_DuctRing | **+19.46** |
| Body_Frame | **+19.24** |
| Layer_CPU | +0.32 |
| Layer_RegisterFile | −0.77 |
| Layer_ECCDecoder | −1.86 |
| Layer_ALUCluster | −2.95 |
| Layer_MajorityVoter | −4.04 |
| Layer_InstructionMemory | −5.14 |
| Layer_DataMemory | −6.23 |
| Prop_1…4 | **−21.51** |
| Leg_1…4 | **−31.06** |

Total vertical extent: **51.41 units** inside a ~10.7-unit window. At full explosion the
viewport was **completely empty** — confirmed by screenshot before any code was changed.

The file's own comment block specified `+400` local Z for the duct ring; the code shipped
`2000`. Same for props (`−400` documented, `−2500` shipped) and legs (`−600` documented,
`−3500` shipped). `git log` shows the file had exactly one commit — it was born this way
and never worked. The likely story: the constants were raised repeatedly because nothing
appeared on screen, which made it worse each time.

### The fix

Offsets are now declared in **world units** and converted into each node's local space via
the inverse of its parent's world basis:

```ts
const basisInv = new THREE.Matrix3().setFromMatrix4(child.parent.matrixWorld).invert();
localTarget = worldTarget.clone().divideScalar(normScale).applyMatrix3(basisInv);
```

The `0.001` root scale and `5.0` Sketchfab scale are now **read from the file** rather than
assumed. This is the same pattern `DroneModel.tsx` already used correctly on the dashboard
page (`trajectory * (factor / normScale)` then `.divide(parentScale)`).

Because the displacement is linear in the explode factor, the per-frame work is now one
line per part:

```ts
p.obj.position.copy(p.restPos).addScaledVector(p.localTarget, f);
```

---

## 2. Every other bug found and fixed

### 2.1 The scene background was WHITE on both pages

```tsx
<color attach="background" args={["transparent"]} />   // in SharedScene AND SubsystemsSharedScene
```

`"transparent"` is not a THREE colour keyword. `THREE.Color` logs
`THREE.Color: Unknown color transparent`, keeps its default, and the default is **white**.
Verified directly:

```
new THREE.Color("transparent").getHexString()  →  "ffffff"
```

The entire dark UI was rendering behind a white canvas. Fixed by deleting the element —
the canvas then keeps its alpha and the page's `#0d0d10` shows through.

### 2.2 The camera diverges on any frame hitch

```ts
radius.current = THREE.MathUtils.lerp(radius.current, tgtRadius.current, delta * 1.2);
```

`useFrame` hands you the raw clock delta. A tab switch, a GC pause, or a shader compile
yields a multi-second delta; `delta * 1.2` then exceeds 1 and the lerp **overshoots and
diverges** instead of settling. This is the "camera flew away mid-demo" failure mode, and
it directly threatens the stated priority of not dropping frames during the review.

Fixed in all three loops (`DroneCameraController`, `DroneModel`, `SubsystemsDroneModel`):

```ts
const delta = Math.min(rawDelta, 1 / 30);
```

### 2.3 Every fault injection allocated a fresh material

`makeCPUMat()` built a new `MeshStandardMaterial` on every change to `activeFaultModule`.
The auto-injector fires roughly every 6 seconds, so a 20-minute review meant ~200 new
materials and ~200 shader-program compiles — each a visible stutter, at exactly the moment
the demo needs to look smooth.

Materials are now built once and only their `emissive` is mutated. `emissiveIntensity` is
pinned at `1` for the material's lifetime and the glow strength is folded into the emissive
colour, so the frame loop performs no property assignments on memoised objects.

### 2.4 The seven boards were indistinguishable

All internal layers were painted `#1a1a1e` — seven identical near-black slabs, in a view
whose entire purpose is to tell seven subsystems apart. (The GLB actually ships each layer
with its own vivid material, `Bubble 2` … `Bubble 8`, which the code was overwriting.)

Each board now carries its own accent tint, and the deep orange originally used for the CPU
was lightened to `#fb923c` because `#f97316 × 0.22` renders as near-black against charcoal.

### 2.5 Tiers were intersecting each other

Caught by the check script, not by eye: `Layer_CPU` (2.17…2.20) sat **inside** `Body_Frame`
(2.00…2.48), and the props and legs cut straight through the middle of the board stack. The
boards are ~0.03 units thick, so anything sharing their height renders as a part skewered
through a board.

Retuned so every tier occupies a disjoint band of Y, and added an assertion so it cannot
regress.

### 2.6 Labels read against the wrong board

The labels were anchored 1.75 units off to the side of each board. That places them at a
**different depth**, and perspective then slid them down the screen far enough to sit
against the neighbouring board.

Fixed structurally rather than by nudging: each board now draws a **leader line**, and the
label is anchored to the far end of that line in 3D. The leaders swing to stay on the
camera's right as the model turns, and light up in the board's accent colour when selected.

### 2.7 The page title was clipped on all three pages

"FAULT TOLERANT PROCESSO**R**" — the title was centred on the full viewport and ran
underneath the nav pill. Each page now insets the title by that page's own chrome
(the dashboard also has a left panel, so its inset differs).

---

## 3. Claims from the previous handoff that did NOT hold up

The earlier ADR listed five failure surfaces to justify scrapping the exploded view. Four
of them do not exist:

| Claim | Finding |
|---|---|
| "drilling-depth bugs" | **Not real.** All 17 meshes are single-primitive, so three.js creates a `Mesh` named exactly `Layer_CPU` etc. No group traversal needed. |
| "partial-tier-mapping bugs" | **Not real.** `LAYER_MAP` covers all seven layers and the names match the GLB exactly. |
| "conflicting animation clips" | **Not real.** The GLB does contain two clips, but they are Sketchfab import artifacts (parts translating from the origin to their rest pose). Nothing calls `useAnimations`, so they never play. |
| "colour regressions" | **Real, but self-inflicted** — see 2.4. The code was overwriting the GLB's own per-layer colours with near-black. |
| "bounding-box scale-matching issues" | **Real — this was the actual bug.** See section 1. |

---

## 4. GLB reference (`public/rc_quadcopter_v3.glb`)

Worth recording, because the coordinate rig is not obvious and cost real time to work out.

- 22 nodes, 17 meshes, 2 animation clips (unused), 0 skins.
- Root node `Group`: **scale 0.001**, rotation −90° about X, so **local +Z maps to world +Y**.
- The seven `Layer_*` nodes are **direct children of `Group`** → 1 local Z unit = 0.001 world Y.
- `Prop_*`, `Leg_*`, `Body_Frame`, `Shell_DuctRing` sit under
  `Sketchfab_model` (**scale 5.0**) → `currentmodel…` → 1 local Z unit = 0.005 world Y.
- **All ten shell parts share the identical local translation** `[0.000026, 214.68, 301.198]`.
  Their geometry is baked at different offsets, so you cannot infer a part's position from
  its node translation — use its bounding box.
- Layers ship distinct materials (`Bubble 2` … `Bubble 8`); shell parts use `material_*`.

⚠️ **The two pages use different models.** The dashboard (`/`) loads
`rc_quadcopter.glb` (the old one, with `Object_N` node names hard-mapped in
`DroneModel.tsx`). Subsystems loads `rc_quadcopter_v3.glb`. Do not assume a change to one
affects the other.

---

## 5. The regression check

```bash
npm run check:explode        # scripts/check-explode-layout.js
```

Recomputes the final on-screen geometry **straight from the .glb** — it re-implements the
component's transform maths rather than trusting it — and asserts:

1. All 17 meshes get placed.
2. Nothing leaves the camera frame (compares against the fov/radius-derived half-height).
3. The seven boards stay in CPU-on-top order with a real gap between each.
4. No two tiers (duct ring / body frame / boards / props / legs) overlap in Y.

Current output:

```
frame half-height  5.36
exploded Y range   -3.17 .. 3.84
exploded X half    2.12
layer gaps         0.58, 0.54, 0.57, 0.64, 0.57, 0.52
```

It runs in well under a second with no dependencies. **Run it after touching any explode
constant** — it is what caught the tier-overlap bug (2.5).

### Tuning knobs

All in `src/components/SubsystemsDroneModel.tsx`, all in **world units**. Mirror any change
into `scripts/check-explode-layout.js` (the constants are duplicated there deliberately, so
the check independently verifies the intended values) and re-run the check.

| Constant | Value | Meaning |
|---|---|---|
| `LAYER_GAP` | 0.22 | Extra gap between adjacent boards (they already have ~0.35 at rest) |
| `LAYER_STACK_Y` | 0.70 | Lifts the board stack so it centres on the origin |
| `DUCT_RING_Y` | 2.05 | Any higher and the ring collides with the title card |
| `BODY_FRAME_Y` | 1.30 | |
| `PROP_Y` / `PROP_RADIAL` | −3.40 / 0.5 | Vertical drop and radial fan-out |
| `LEG_Y` / `LEG_RADIAL` | −3.60 / 0.9 | |
| `LABEL_DIST` | 1.95 | How far the leader line runs from the board |

---

## 6. Fault → board mapping

Previously every fault lit the CPU board. Now the glow lands on the subsystem that is
actually doing the work, which is the point the demo is making:

| `activeFaultModule` | Board lit | Colour |
|---|---|---|
| `CPU_SEC` | Layer_CPU | amber `#f59e0b` |
| `CPU_DED` | Layer_CPU | red `#ef4444` |
| `ALU_*` | **Layer_ALUCluster** | red `#ef4444` |
| `TMR_RECOVER` | **Layer_MajorityVoter** | green `#22c55e` |

---

## 7. Deployment

**Live:** https://drone-dashboard-three.vercel.app
(`/` dashboard, `/subsystems`, `/analytics`)

- Deployed with `npx vercel deploy --prod --yes` from the local working tree.
- **Not linked to GitHub** — pushing to `main` does **not** redeploy. Re-run the command
  above after changes, or connect the repo in the Vercel dashboard for automatic deploys.
- Verified publicly reachable with no login wall (all three routes return 200
  unauthenticated).
- `.vercelignore` keeps `public/video.mp4`, `public/video.html`, `public/inspect.html` and
  the root `*.mp4` screen recordings **out of the deploy** — anything in `public/` is served
  at a public URL, and those are local scratch files. Nothing in `src/` references them.

---

## 8. Known remaining issues (NOT fixed)

### 8.1 `/analytics` cannot be screenshotted headlessly — but is fine in a real browser

The analytics panel renders blank under headless Chrome. Investigated fully:

- anime.js only advances its animations on `requestAnimationFrame`.
- Headless Chrome does not fire rAF on a page with no WebGL canvas driving frames.
- The dashboard and subsystems pages have an R3F canvas, so their anime entrances complete.
  Analytics has no canvas, so its entrance freezes at `opacity: 0`.
- Reproduced identically on the **pre-fix `main`**, and in a standalone HTML file with no
  React involved. **Not caused by this work, and not an app bug.**

⚠️ It was therefore never visually verified. Open it in a real browser before the review.

There is a latent fragility worth knowing about: the whole analytics page's visibility
depends on an anime.js entrance completing. If anime ever fails to run, the page is blank.
Deliberately left alone rather than "fixing" working code — but if you want it bulletproof,
move the opacity fade to a CSS keyframe so it cannot leave content hidden.

### 8.2 Pre-existing issues in `src/lib/DashboardContext.tsx`

Untouched by this work; they account for all remaining lint findings.

- `Math.random()` and `Date.now()` called during render (`addToast`, line ~118) — 2 lint
  errors under `react-hooks/purity`.
- `setProcessorState("Healthy" as any)` (line ~198) — `"Healthy"` is **not** in the
  `processorState` union. Cosmetic, since it is overwritten 2 s later, but it is a real
  type hole.
- `useEffect` missing `injectFault` in its dependency array (line ~235).

### 8.3 Cosmetic

- Label positions can drift a few pixels from their leader lines at very steep camera
  angles. Add a per-label Y trim if it shows on the projector.
- The title insets (`right-[30rem]`, `left-[23rem]`) are tied to the nav/panel widths. If
  you change the nav's contents, re-check the title at 1366×768.

---

## 9. Files changed

| File | Change |
|---|---|
| `src/components/SubsystemsDroneModel.tsx` | Rewritten — the core fix, plus tints, leader lines, labels, fault mapping |
| `src/components/SharedScene.tsx` | Removed white background; clamped camera delta |
| `src/components/SubsystemsSharedScene.tsx` | Removed white background |
| `src/components/DroneModel.tsx` | Clamped delta; two `prefer-const` fixes |
| `src/app/page.tsx` | Title inset; unused imports |
| `src/app/subsystems/page.tsx` | Title inset; unused imports |
| `src/app/analytics/page.tsx` | Title inset; unused imports |
| `scripts/check-explode-layout.js` | **New** — the regression check |
| `package.json` | Added `check:explode` script |
| `.vercelignore` | **New** — keeps scratch files out of the deploy |

Commits: `474bdfa` (the fix) → `e99e098` (polish) → `ef42514` (deploy ignore).

---

## 10. Revised recommendation on the ADR

**The subsystems rewrite is no longer necessary.** The exploded view works, is covered by an
automated check, and now carries labelled leader lines — which delivers the previous
handoff's `<Html>`-hotspot goal without discarding the 3D view. Simplifying to a static
wireframe remains an option, but it would now mean trading a working feature for a simpler
one, not replacing a broken one.

**Keep rejecting GSAP / Lenis / Vanta.js.** The original reasoning holds, and this
investigation adds a concrete data point: **none of the seven bugs found here were animation
problems.** They were coordinate-space arithmetic, an invalid colour keyword, an unclamped
timestep, and material lifecycle. A different animation library would have flown the parts
off-screen just as accurately. Vanta in particular would add a second WebGL context
competing with React Three Fiber for the GPU on the demo laptop — the exact opposite of the
stability the review needs.

**Engineering effort should now return to the critical path: RTL merge, FPGA UART, and
synthesis.**

---

## 11. Running it

```bash
npm install          # required — node_modules was absent from this checkout
npm run dev          # http://localhost:3000

npm run check:explode   # verify the exploded-view geometry
npm run build           # full production build
npx tsc --noEmit        # typecheck
```

`npm run build`, `tsc`, and `check:explode` were all clean at `ef42514`.
