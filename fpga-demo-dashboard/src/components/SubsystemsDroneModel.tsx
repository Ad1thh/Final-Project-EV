"use client";

import React, { useRef, useMemo } from "react";
import { useFrame } from "@react-three/fiber";
import { useGLTF, Html } from "@react-three/drei";
import { useDashboard } from "@/lib/DashboardContext";
import * as THREE from "three";

const GRAPHITE_COLOR = new THREE.Color("#141416");
const NO_EMISSIVE    = new THREE.Color(0, 0, 0);

const LAYER_MAP: Record<string, string> = {
  Layer_CPU: "CPU",
  Layer_RegisterFile: "Register File",
  Layer_ECCDecoder: "ECC Decoder",
  Layer_ALUCluster: "ALU Cluster",
  Layer_MajorityVoter: "Majority Voter",
  Layer_InstructionMemory: "Instruction Memory",
  Layer_DataMemory: "Data Memory",
};

/** Top→bottom order of the internal stack in the exploded view. */
const LAYER_ORDER = [
  "Layer_CPU",
  "Layer_RegisterFile",
  "Layer_ECCDecoder",
  "Layer_ALUCluster",
  "Layer_MajorityVoter",
  "Layer_InstructionMemory",
  "Layer_DataMemory",
];

/** Accent per board — the GLB ships all seven in near-identical black otherwise. */
const LAYER_ACCENT: Record<string, string> = {
  Layer_CPU: "#fb923c",   // lighter than ORANGE — the deep orange tints to near-black
  Layer_RegisterFile: "#38bdf8",
  Layer_ECCDecoder: "#a78bfa",
  Layer_ALUCluster: "#fb7185",
  Layer_MajorityVoter: "#34d399",
  Layer_InstructionMemory: "#fbbf24",
  Layer_DataMemory: "#22d3ee",
};

/* ═══════════════════════════════════════════════════════════════════════════
   EXPLODE LAYOUT — all values are WORLD units in the rendered scene.
   The camera sits at radius 11.5 with a 50° fov, so it frames roughly
   ±5.3 units vertically. Keep the total spread inside that or parts leave
   the screen. Conversion into each node's own local space is derived from
   the GLB hierarchy at load time (see `basisInv` below) — never hardcoded.

   Tiers must not overlap in Y either — the boards are wafer-thin, so a prop
   parked at the same height slices straight through one.
═══════════════════════════════════════════════════════════════════════════ */
const LAYER_GAP     = 0.22;  // added to the gap the boards already have at rest
const LAYER_STACK_Y = 0.70;  // lifts the stack so it centres on the origin
const DUCT_RING_Y   = 2.05;  // any higher and the ring runs into the title card
const BODY_FRAME_Y  = 1.30;
const PROP_Y        = -3.40;
const PROP_RADIAL   = 0.5;
const LEG_Y         = -3.60;
const LEG_RADIAL    = 0.9;

/** How far out from a board its leader line runs, in world units. */
const LABEL_DIST = 1.95;

// Scratch objects reused every frame — allocating these in the loop would churn
// garbage 60 times a second.
const right     = new THREE.Vector3();
const boardAt   = new THREE.Vector3();
const anchorAt  = new THREE.Vector3();
const lineFrom  = new THREE.Vector3();
const worldQuat = new THREE.Quaternion();

// Pre-built so the per-frame emissive update never re-parses a colour string.
const LEADER_IDLE = new THREE.Color("#5a5a66");
const GLOW_WARN = new THREE.Color("#f59e0b");
const GLOW_ERR  = new THREE.Color("#ef4444");
const GLOW_OK   = new THREE.Color("#22c55e");

/**
 * Which board lights up for a given fault. An ALU fault lights the ALU cluster
 * and a TMR recovery lights the majority voter, rather than everything landing
 * on the CPU — that is the point the demo is making.
 */
function faultGlow(fault: string | null): { node: string; color: THREE.Color; intensity: number } | null {
  if (fault === "CPU_SEC")       return { node: "Layer_CPU",           color: GLOW_WARN, intensity: 2.0 };
  if (fault === "CPU_DED")       return { node: "Layer_CPU",           color: GLOW_ERR,  intensity: 2.0 };
  if (fault?.startsWith("ALU_")) return { node: "Layer_ALUCluster",    color: GLOW_ERR,  intensity: 1.8 };
  if (fault === "TMR_RECOVER")   return { node: "Layer_MajorityVoter", color: GLOW_OK,   intensity: 2.0 };
  return null;
}

interface Label {
  name: string;
  text: string;
  accent: THREE.Color;
  /** Board centre at rest, in rendered world units. */
  rest: THREE.Vector3;
  /** Displacement applied at full explosion. */
  target: THREE.Vector3;
  /** Distance from the board centre at which its leader line starts. */
  startAt: number;
}

interface Part {
  obj: THREE.Object3D;
  restPos: THREE.Vector3;
  /** Local-space displacement at full explosion (f = 1). */
  localTarget: THREE.Vector3;
  /** Set for the seven boards only; null for shell, props and legs. */
  layer: string | null;
  accent: THREE.Color | null;
  mat: THREE.MeshStandardMaterial;
}

export default function SubsystemsDroneModel({ staticExploded = true }: { staticExploded?: boolean }) {
  const {
    isHovering, isRotating,
    highlightedModules, activeFaultModule,
    explosionFactor,
  } = useDashboard();

  const groupRef = useRef<THREE.Group>(null);
  const hoverTime = useRef(0);
  const currentExplodeFactor = useRef(0);
  const labelAnchors = useRef<(THREE.Group | null)[]>([]);
  const leadersRef = useRef<THREE.LineSegments>(null);

  const { scene: rawScene } = useGLTF("/rc_quadcopter_v3.glb");

  const { cloned, normScale, normOffset, parts, labels } = useMemo(() => {
    const cloned = rawScene.clone(true);
    cloned.position.set(0, 0, 0);
    cloned.rotation.set(0, 0, 0);
    cloned.scale.set(1, 1, 1);
    cloned.updateMatrixWorld(true);

    const box    = new THREE.Box3().setFromObject(cloned);
    const sz     = box.getSize(new THREE.Vector3());
    const ct     = box.getCenter(new THREE.Vector3());
    const maxDim = Math.max(sz.x, sz.y, sz.z, 0.001);

    const normScale  = 4.0 / maxDim;
    const normOffset = ct.clone().negate().multiplyScalar(normScale);

    // A node's on-screen position is normScale * itsWorldPos + normOffset,
    // because <primitive> is rendered inside a wrapper carrying both.
    const rendered = (v: THREE.Vector3) => v.clone().multiplyScalar(normScale).add(normOffset);

    const parts:  Part[] = [];
    const labels: Label[] = [];

    cloned.traverse((child) => {
      if (!(child instanceof THREE.Mesh)) return;

      const accent = LAYER_ACCENT[child.name];
      const mat = new THREE.MeshStandardMaterial({
        // Tint boards from their accent so the stack reads as seven distinct
        // subsystems; everything else stays matte graphite.
        color:             accent ? new THREE.Color(accent).multiplyScalar(0.22) : GRAPHITE_COLOR,
        roughness:         accent ? 0.45 : 0.72,
        metalness:         accent ? 0.55 : 0.35,
        emissive:          new THREE.Color(0, 0, 0),
        // Held at 1 for the life of the material; glow strength is baked into the
        // emissive colour instead, so the frame loop only ever mutates that.
        emissiveIntensity: 1,
        envMapIntensity:   0.5,
      });
      child.material = mat;
      child.castShadow = true;
      child.receiveShadow = true;

      const restCenter = rendered(
        new THREE.Box3().setFromObject(child).getCenter(new THREE.Vector3()),
      );

      // Radial spread for the four-fold parts, so they fan out instead of stacking.
      const radial = (r: number, y: number) => {
        const dir = new THREE.Vector3(restCenter.x, 0, restCenter.z);
        if (dir.lengthSq() > 1e-6) dir.normalize().multiplyScalar(r);
        else dir.set(0, 0, 0);
        return dir.setY(y);
      };

      const layerIdx = LAYER_ORDER.indexOf(child.name);
      let target: THREE.Vector3 | null = null;

      if (layerIdx >= 0) {
        const mid = (LAYER_ORDER.length - 1) / 2;
        target = new THREE.Vector3(0, (mid - layerIdx) * LAYER_GAP + LAYER_STACK_Y, 0);
      } else if (child.name === "Shell_DuctRing") {
        target = new THREE.Vector3(0, DUCT_RING_Y, 0);
      } else if (child.name === "Body_Frame") {
        target = new THREE.Vector3(0, BODY_FRAME_Y, 0);
      } else if (child.name.startsWith("Prop_")) {
        target = radial(PROP_RADIAL, PROP_Y);
      } else if (child.name.startsWith("Leg_")) {
        target = radial(LEG_RADIAL, LEG_Y);
      }
      if (!target || !child.parent) return;

      // World offset -> this node's local space. The parent's world basis carries
      // every scale and rotation in the GLB hierarchy (0.001 on the root Group,
      // 5.0 on Sketchfab_model, ...), so nothing about the rig is assumed here.
      const basisInv = new THREE.Matrix3()
        .setFromMatrix4(child.parent.matrixWorld)
        .invert();

      parts.push({
        obj:         child,
        restPos:     child.position.clone(),
        localTarget: target.clone().divideScalar(normScale).applyMatrix3(basisInv),
        layer:       LAYER_MAP[child.name] ?? null,
        accent:      accent ? new THREE.Color(accent) : null,
        mat,
      });

      const text = LAYER_MAP[child.name];
      if (text) {
        const bs = new THREE.Box3().setFromObject(child).getSize(new THREE.Vector3());
        labels.push({
          name:   child.name,
          text,
          accent: new THREE.Color(LAYER_ACCENT[child.name]),
          rest:   restCenter.clone(),
          target: target.clone(),
          // Where the leader line leaves the board, just clear of its edge.
          startAt: (Math.max(bs.x, bs.z) * normScale) / 2 + 0.1,
        });
      }
    });

    labels.sort((a, b) => LAYER_ORDER.indexOf(a.name) - LAYER_ORDER.indexOf(b.name));

    return { cloned, normScale, normOffset, parts, labels };
  }, [rawScene]);

  // Backing arrays for the leader lines; the endpoints themselves are rewritten
  // each frame, since the leaders swing to stay on the camera's right as the
  // model turns.
  const leaderBuffers = useMemo(() => ({
    position: new Float32Array(labels.length * 6),
    color:    new Float32Array(labels.length * 6),
  }), [labels]);

  useFrame((state, rawDelta) => {
    // See DroneCameraController: unclamped deltas push lerp alphas past 1.
    const delta = Math.min(rawDelta, 1 / 30);
    const targetExplode = staticExploded ? 1.0 : explosionFactor;
    currentExplodeFactor.current = THREE.MathUtils.lerp(
      currentExplodeFactor.current,
      targetExplode,
      delta * 4.0,
    );

    if (groupRef.current) {
      if (isRotating) groupRef.current.rotation.y += delta * 0.04;
      if (isHovering) {
        hoverTime.current += delta;
        groupRef.current.position.y = Math.sin(hoverTime.current * 1.5) * 0.1;
      } else {
        groupRef.current.position.y = THREE.MathUtils.lerp(groupRef.current.position.y, 0, delta * 2);
      }
    }

    const f = currentExplodeFactor.current;
    const glow = faultGlow(activeFaultModule);

    for (const p of parts) {
      p.obj.position.copy(p.restPos).addScaledVector(p.localTarget, f);

      // Emissive is driven here rather than from an effect: the materials are
      // built once above and only mutated, so repeated fault injections never
      // churn shader programs mid-demo.
      if (!p.layer) continue;
      if (glow && glow.node === p.obj.name) {
        p.mat.emissive.copy(glow.color).multiplyScalar(glow.intensity);
      } else if (p.accent && highlightedModules.includes(p.layer)) {
        p.mat.emissive.copy(p.accent).multiplyScalar(0.5);
      } else {
        p.mat.emissive.copy(NO_EMISSIVE);
      }
    }

    if (!groupRef.current) return;

    // Leaders and labels ride the camera's right-hand side, so they never end up
    // pointing into or behind the stack as the model turns.
    right.setFromMatrixColumn(state.camera.matrixWorld, 0)
      .applyQuaternion(groupRef.current.getWorldQuaternion(worldQuat).invert())
      .setY(0);
    if (right.lengthSq() < 1e-6) right.set(1, 0, 0);
    else right.normalize();

    const geom = leadersRef.current?.geometry;
    if (!geom) return;
    const pos = geom.attributes.position as THREE.BufferAttribute;
    const col = geom.attributes.color as THREE.BufferAttribute;

    labels.forEach((l, i) => {
      boardAt.copy(l.rest).addScaledVector(l.target, f);

      anchorAt.copy(boardAt).addScaledVector(right, LABEL_DIST);
      labelAnchors.current[i]?.position.copy(anchorAt);

      lineFrom.copy(boardAt).addScaledVector(right, l.startAt);
      pos.setXYZ(i * 2,     lineFrom.x, lineFrom.y, lineFrom.z);
      pos.setXYZ(i * 2 + 1, anchorAt.x, anchorAt.y, anchorAt.z);

      const lit = highlightedModules.includes(LAYER_MAP[l.name]);
      const c = lit ? l.accent : LEADER_IDLE;
      col.setXYZ(i * 2,     c.r, c.g, c.b);
      col.setXYZ(i * 2 + 1, c.r, c.g, c.b);
    });

    pos.needsUpdate = true;
    col.needsUpdate = true;
  });

  return (
    <group ref={groupRef}>
      <group position={[normOffset.x, normOffset.y, normOffset.z]} scale={normScale}>
        <primitive object={cloned} />
      </group>

      {/* frustumCulled off: the bounding sphere is built from the initial
          all-zero endpoints, so the lines would be culled once they move. */}
      {staticExploded && (
        <lineSegments ref={leadersRef} frustumCulled={false}>
          <bufferGeometry>
            <bufferAttribute attach="attributes-position" args={[leaderBuffers.position, 3]} />
            <bufferAttribute attach="attributes-color" args={[leaderBuffers.color, 3]} />
          </bufferGeometry>
          <lineBasicMaterial vertexColors transparent opacity={0.55} />
        </lineSegments>
      )}

      {staticExploded && labels.map((l, i) => {
        const lit = highlightedModules.includes(LAYER_MAP[l.name]);
        const accent = `#${l.accent.getHexString()}`;
        return (
          // The group is moved to the leader's far end each frame; Html reads its
          // parent's world matrix, so the text lands exactly on the line end
          // rather than being nudged into place in screen space.
          <group key={l.name} ref={(g) => { labelAnchors.current[i] = g; }}>
            <Html distanceFactor={13} style={{ pointerEvents: "none" }}>
              <span
                style={{
                  display:       "block",
                  transform:     "translateY(-50%)",   // centre the text on the line end
                  paddingLeft:   "7px",
                  fontFamily:    "monospace",
                  fontSize:      "9px",
                  textTransform: "uppercase",
                  letterSpacing: "0.14em",
                  whiteSpace:    "nowrap",
                  userSelect:    "none",
                  transition:    "color 200ms ease",
                  color:         lit ? accent : "rgba(255,255,255,0.5)",
                  textShadow:    lit ? `0 0 10px ${accent}` : "none",
                }}
              >
                {l.text}
              </span>
            </Html>
          </group>
        );
      })}
    </group>
  );
}

useGLTF.preload("/rc_quadcopter_v3.glb");
