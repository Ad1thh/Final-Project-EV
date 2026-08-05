/**
 * Guard for the subsystems exploded view.
 *
 * The bug this exists to catch: explode offsets were written in the GLB's raw
 * local units against hand-derived scale factors, ignoring the normScale=4/maxDim
 * wrapper the model renders inside. Every part ended up 5-6x too far out
 * (shell at world Y +19, legs at -31) while the fixed camera frames about
 * +/-5.3, so the "exploded view" rendered an empty screen.
 *
 * This recomputes the final on-screen bounds straight from the .glb and fails if
 * anything leaves the frame. Run: npm run check:explode
 */
const assert = require("assert");
const fs = require("fs");
const path = require("path");

const GLB = path.join(__dirname, "..", "public", "rc_quadcopter_v3.glb");

// Keep in sync with src/components/SubsystemsDroneModel.tsx.
const LAYER_ORDER = [
  "Layer_CPU", "Layer_RegisterFile", "Layer_ECCDecoder", "Layer_ALUCluster",
  "Layer_MajorityVoter", "Layer_InstructionMemory", "Layer_DataMemory",
];
const LAYER_GAP = 0.22, LAYER_STACK_Y = 0.70, DUCT_RING_Y = 2.05, BODY_FRAME_Y = 1.30;
const PROP_Y = -3.40, PROP_RADIAL = 0.5, LEG_Y = -3.60, LEG_RADIAL = 0.9;

// Camera: DroneCameraController radius 11.5 (staticExploded), Canvas fov 50.
const CAM_RADIUS = 11.5, CAM_FOV = 50;
const FRAME_HALF_HEIGHT = CAM_RADIUS * Math.tan((CAM_FOV * Math.PI) / 360);

/* ── minimal glTF transform math ──────────────────────────────────────────── */
const mul = (a, b) => {
  const o = new Array(16);
  for (let c = 0; c < 4; c++) for (let r = 0; r < 4; r++) {
    let s = 0;
    for (let k = 0; k < 4; k++) s += a[k * 4 + r] * b[c * 4 + k];
    o[c * 4 + r] = s;
  }
  return o;
};
const compose = (t, q, s) => {
  const [x, y, z, w] = q;
  const x2 = x + x, y2 = y + y, z2 = z + z;
  const xx = x * x2, xy = x * y2, xz = x * z2, yy = y * y2, yz = y * z2, zz = z * z2;
  const wx = w * x2, wy = w * y2, wz = w * z2;
  return [
    (1 - (yy + zz)) * s[0], (xy + wz) * s[0], (xz - wy) * s[0], 0,
    (xy - wz) * s[1], (1 - (xx + zz)) * s[1], (yz + wx) * s[1], 0,
    (xz + wy) * s[2], (yz - wx) * s[2], (1 - (xx + yy)) * s[2], 0,
    t[0], t[1], t[2], 1,
  ];
};
const apply = (m, v) => [
  m[0] * v[0] + m[4] * v[1] + m[8] * v[2] + m[12],
  m[1] * v[0] + m[5] * v[1] + m[9] * v[2] + m[13],
  m[2] * v[0] + m[6] * v[1] + m[10] * v[2] + m[14],
];
// Invert the upper-left 3x3 (the parent world basis), matching Matrix3 in the component.
const invBasis = (m) => {
  const a = [m[0], m[1], m[2], m[4], m[5], m[6], m[8], m[9], m[10]];
  const [a0, a1, a2, a3, a4, a5, a6, a7, a8] = a;
  const c0 = a4 * a8 - a5 * a7, c1 = a5 * a6 - a3 * a8, c2 = a3 * a7 - a4 * a6;
  const det = a0 * c0 + a1 * c1 + a2 * c2;
  assert.ok(Math.abs(det) > 1e-30, "parent basis is singular");
  const d = 1 / det;
  return [
    c0 * d, (a2 * a7 - a1 * a8) * d, (a1 * a5 - a2 * a4) * d,
    c1 * d, (a0 * a8 - a2 * a6) * d, (a2 * a3 - a0 * a5) * d,
    c2 * d, (a1 * a6 - a0 * a7) * d, (a0 * a4 - a1 * a3) * d,
  ];
};
const applyM3 = (m, v) => [
  m[0] * v[0] + m[3] * v[1] + m[6] * v[2],
  m[1] * v[0] + m[4] * v[1] + m[7] * v[2],
  m[2] * v[0] + m[5] * v[1] + m[8] * v[2],
];

/* ── scene graph ──────────────────────────────────────────────────────────── */
const buf = fs.readFileSync(GLB);
const gltf = JSON.parse(buf.slice(20, 20 + buf.readUInt32LE(12)).toString("utf8"));
const parentOf = {};
gltf.nodes.forEach((n, i) => (n.children || []).forEach((c) => (parentOf[c] = i)));
const byName = {};
gltf.nodes.forEach((n, i) => (byName[n.name] = i));

const local = (n, dLocal) => {
  const t = (n.translation || [0, 0, 0]).slice();
  if (dLocal) for (let k = 0; k < 3; k++) t[k] += dLocal[k];
  return compose(t, n.rotation || [0, 0, 0, 1], n.scale || [1, 1, 1]);
};
const chainOf = (i) => { const c = []; for (let k = i; k !== undefined; k = parentOf[k]) c.unshift(k); return c; };
const worldMat = (i, offsets) => {
  let M = [1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1];
  for (const idx of chainOf(i)) M = mul(M, local(gltf.nodes[idx], offsets[gltf.nodes[idx].name]));
  return M;
};
const parentWorld = (i) => {
  let M = [1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1];
  for (const idx of chainOf(i).slice(0, -1)) M = mul(M, local(gltf.nodes[idx]));
  return M;
};
const nodeBox = (i, offsets) => {
  const n = gltf.nodes[i];
  if (n.mesh === undefined) return null;
  const M = worldMat(i, offsets);
  const bb = { min: [Infinity, Infinity, Infinity], max: [-Infinity, -Infinity, -Infinity] };
  for (const p of gltf.meshes[n.mesh].primitives) {
    const a = gltf.accessors[p.attributes.POSITION];
    for (const x of [a.min[0], a.max[0]]) for (const y of [a.min[1], a.max[1]]) for (const z of [a.min[2], a.max[2]]) {
      const w = apply(M, [x, y, z]);
      for (let k = 0; k < 3; k++) { bb.min[k] = Math.min(bb.min[k], w[k]); bb.max[k] = Math.max(bb.max[k], w[k]); }
    }
  }
  return bb;
};
const sceneBox = (offsets) => {
  const bb = { min: [Infinity, Infinity, Infinity], max: [-Infinity, -Infinity, -Infinity] };
  gltf.nodes.forEach((n, i) => {
    const b = nodeBox(i, offsets);
    if (!b) return;
    for (let k = 0; k < 3; k++) { bb.min[k] = Math.min(bb.min[k], b.min[k]); bb.max[k] = Math.max(bb.max[k], b.max[k]); }
  });
  return bb;
};

/* ── reproduce the component's layout ─────────────────────────────────────── */
const rest = sceneBox({});
const size = rest.max.map((v, k) => v - rest.min[k]);
const center = rest.max.map((v, k) => (v + rest.min[k]) / 2);
const normScale = 4.0 / Math.max(...size, 0.001);
const normOffset = center.map((v) => -v * normScale);
const rendered = (v) => v.map((x, k) => x * normScale + normOffset[k]);

const worldTarget = (name, restCenter) => {
  const li = LAYER_ORDER.indexOf(name);
  if (li >= 0) return [0, ((LAYER_ORDER.length - 1) / 2 - li) * LAYER_GAP + LAYER_STACK_Y, 0];
  if (name === "Shell_DuctRing") return [0, DUCT_RING_Y, 0];
  if (name === "Body_Frame") return [0, BODY_FRAME_Y, 0];
  const radial = (r, y) => {
    const len = Math.hypot(restCenter[0], restCenter[2]);
    return len > 1e-3 ? [(restCenter[0] / len) * r, y, (restCenter[2] / len) * r] : [0, y, 0];
  };
  if (name.startsWith("Prop_")) return radial(PROP_RADIAL, PROP_Y);
  if (name.startsWith("Leg_")) return radial(LEG_RADIAL, LEG_Y);
  return null;
};

const offsets = {};
const placed = [];
for (const [name, i] of Object.entries(byName)) {
  const b = nodeBox(i, {});
  if (!b) continue;
  const restCenter = rendered(b.max.map((v, k) => (v + b.min[k]) / 2));
  const target = worldTarget(name, restCenter);
  if (!target) continue;
  // localTarget = basisInv * (target / normScale)  — the component's conversion.
  offsets[name] = applyM3(invBasis(parentWorld(i)), target.map((v) => v / normScale));
  placed.push({ name, targetY: target[1] });
}

/* ── assertions ───────────────────────────────────────────────────────────── */
assert.strictEqual(placed.length, 17, `expected all 17 meshes placed, got ${placed.length}`);

const ex = sceneBox(offsets);
const yMin = ex.min[1] * normScale + normOffset[1];
const yMax = ex.max[1] * normScale + normOffset[1];
const xHalf = Math.max(Math.abs(ex.min[0] * normScale + normOffset[0]), Math.abs(ex.max[0] * normScale + normOffset[0]));

console.log(`frame half-height  ${FRAME_HALF_HEIGHT.toFixed(2)}`);
console.log(`exploded Y range   ${yMin.toFixed(2)} .. ${yMax.toFixed(2)}`);
console.log(`exploded X half    ${xHalf.toFixed(2)}`);

assert.ok(yMax <= FRAME_HALF_HEIGHT, `top of exploded view (${yMax.toFixed(2)}) is off-screen`);
assert.ok(yMin >= -FRAME_HALF_HEIGHT, `bottom of exploded view (${yMin.toFixed(2)}) is off-screen`);
assert.ok(xHalf <= FRAME_HALF_HEIGHT, `exploded view too wide (${xHalf.toFixed(2)})`);

// The stack must actually separate, and stay in CPU-on-top order.
const layerY = LAYER_ORDER.map((name) => {
  const b = nodeBox(byName[name], offsets);
  return (b.max[1] + b.min[1]) / 2 * normScale + normOffset[1];
});
for (let i = 1; i < layerY.length; i++) {
  const gap = layerY[i - 1] - layerY[i];
  assert.ok(gap > 0.3, `${LAYER_ORDER[i - 1]} -> ${LAYER_ORDER[i]} gap ${gap.toFixed(2)} too small / out of order`);
}
console.log(`layer gaps         ${layerY.slice(1).map((y, i) => (layerY[i] - y).toFixed(2)).join(", ")}`);

console.log("\nfinal on-screen Y span per part (top to bottom):");
placed
  .map(({ name }) => {
    const b = nodeBox(byName[name], offsets);
    return { name, lo: b.min[1] * normScale + normOffset[1], hi: b.max[1] * normScale + normOffset[1] };
  })
  .sort((a, b) => b.hi - a.hi)
  .forEach((p) => console.log(`  ${p.name.padEnd(24)} ${p.lo.toFixed(2).padStart(6)} .. ${p.hi.toFixed(2).padStart(6)}`));

// Tiers must occupy disjoint bands of Y. The boards are ~0.03 units thick, so a
// prop or leg sharing their height renders as a part skewered through a board.
const spanOf = (names) => {
  const b = { lo: Infinity, hi: -Infinity };
  for (const n of names) {
    const nb = nodeBox(byName[n], offsets);
    b.lo = Math.min(b.lo, nb.min[1] * normScale + normOffset[1]);
    b.hi = Math.max(b.hi, nb.max[1] * normScale + normOffset[1]);
  }
  return b;
};
const tiers = [
  ["duct ring", spanOf(["Shell_DuctRing"])],
  ["body frame", spanOf(["Body_Frame"])],
  ["boards", spanOf(LAYER_ORDER)],
  ["props", spanOf(["Prop_1", "Prop_2", "Prop_3", "Prop_4"])],
  ["legs", spanOf(["Leg_1", "Leg_2", "Leg_3", "Leg_4"])],
];
for (let i = 0; i < tiers.length; i++) {
  for (let k = i + 1; k < tiers.length; k++) {
    const [an, a] = tiers[i], [bn, b] = tiers[k];
    assert.ok(
      a.lo > b.hi || b.lo > a.hi,
      `tiers "${an}" (${a.lo.toFixed(2)}..${a.hi.toFixed(2)}) and "${bn}" (${b.lo.toFixed(2)}..${b.hi.toFixed(2)}) overlap`,
    );
  }
}

console.log("\nOK");
