"use client";

import React, { useRef, useMemo, useEffect } from "react";
import { useFrame } from "@react-three/fiber";
import { useGLTF, Html } from "@react-three/drei";
import { useDashboard } from "@/lib/DashboardContext";
import * as THREE from "three";

/* ═══════════════════════════════════════════════════════════════════════════
   CONSTANTS — colour scheme matched to reference video
   • Background: near-black charcoal (page handles this via #0d0d10)
   • Floor grid: faint thin lines (page handles this via FloorGrid)
   • Model base: matte dark graphite/charcoal, NOT pure black
   • Accent: orange (#f97316) on mechanical joints, hinges, internal components
   • Rim lighting & ground shadow: handled in page.tsx Scene
═══════════════════════════════════════════════════════════════════════════ */

const ORANGE = "#f97316";
const GRAPHITE_COLOR = new THREE.Color("#141416");  // matte dark graphite/charcoal
const JOINT_ACCENT_COLOR = new THREE.Color(ORANGE); // orange accent for mechanical joints/hinges

/**
 * Explode displacement vectors in NORMALISED groupRef space.
 * (The normWrapper scales the model to ~4 units across, so these
 *  ~2-unit offsets feel proportionally correct.)
 */
const EXPLODE_OFF: Record<string, [number, number, number]> = {
  // Tier 2 - vertically up
  SHELL_TOP:    [0,  1.5, 0],
  // Tier 3 - CPU (focal point, extra clearance)
  CPU_BOARD:    [0,  0.75, 0],
  ROOT:         [0,  0,   0],
  // Tier 4 - vertically down
  SHELL_BOTTOM: [0, -2.2, 0],
  CAMERA:       [0, -2.2, 0],
};

/** Display info per part category. Only one part per tier gets a label to avoid clutter. */
interface LabelInfo { text: string; hero: boolean }
const LABELS: Record<string, LabelInfo> = {
  ARM_PP:       { text: "Rotor Assembly",       hero: false },
  SHELL_TOP:    { text: "Shell — Upper",        hero: false },
  CPU_BOARD:    { text: "Fault-Tolerant Processor", hero: true },
  SHELL_BOTTOM: { text: "Shell — Base",         hero: false },
};

/* ═══════════════════════════════════════════════════════════════════════════
   PART CATEGORISATION
   Classifies top-level GLB children by name patterns first, then by
   bounding-box centroid position relative to the model's overall centre.
═══════════════════════════════════════════════════════════════════════════ */

function categorize(
  obj: THREE.Object3D,
  centroid: THREE.Vector3,
  center: THREE.Vector3,
  size: THREE.Vector3,
): string {
  const n = obj.name;

  // Hard-mapped explicit Object_N identifiers to specific components based on centroid analysis
  switch (n) {
    case "Object_7":  return "CPU_BOARD";
    case "Object_8":  return "SHELL_TOP";
    case "Object_4":
    case "Object_6":  return "ARM_PP";
    case "Object_2":
    case "Object_3":  return "ARM_PN";
    case "Object_9":
    case "Object_10": return "ARM_NP";
    case "Object_5":
    case "Object_11": return "ARM_NN";
  }

  // Fallback for any other GLBs
  const nLower = n.toLowerCase();
  const rx = centroid.x - center.x;
  const rz = centroid.z - center.z;
  const ry = centroid.y - center.y;
  const dxz = Math.hypot(rx, rz);
  const quad = () => (rx >= 0 ? (rz >= 0 ? "ARM_PP" : "ARM_PN") : (rz >= 0 ? "ARM_NP" : "ARM_NN"));

  if (/cpu|processor|board|computer|logic|mainboard/.test(nLower)) return "CPU_BOARD";
  if (/camera|cam|gimbal|lens/.test(nLower)) return "CAMERA";
  if (/top|lid|upper|cover/.test(nLower)) return "SHELL_TOP";
  if (/bottom|base|lower|land|chassis/.test(nLower)) return "SHELL_BOTTOM";
  if (/arm|rotor|prop|motor|blade/.test(nLower)) return quad();

  const yT  = size.y * 0.18;
  const xzT = Math.max(size.x, size.z) * 0.28;
  if (dxz > xzT)        return quad();
  if (ry >  yT)         return "SHELL_TOP";
  if (ry < -yT * 1.8)   return "CAMERA";
  if (ry < -yT * 0.4)   return "SHELL_BOTTOM";
  return "CPU_BOARD";
}

/* ═══════════════════════════════════════════════════════════════════════════
   CPU FAULT GLOW MATERIAL
   Reacts to activeFaultModule exactly as the original procedural version.
═══════════════════════════════════════════════════════════════════════════ */

function makeCPUMat(fault: string | null, highlighted: boolean): THREE.MeshStandardMaterial {
  const mat = new THREE.MeshStandardMaterial({
    color:            new THREE.Color("#1c2030"),
    roughness:        0.25,
    metalness:        0.7,
    emissive:         new THREE.Color(0, 0, 0),
    emissiveIntensity: 0,
  });
  if (fault === "CPU_SEC")             { mat.emissive.set("#f59e0b"); mat.emissiveIntensity = 2.0; }
  else if (fault === "CPU_DED")        { mat.emissive.set("#ef4444"); mat.emissiveIntensity = 2.0; }
  else if (fault?.startsWith("ALU_"))  { mat.emissive.set("#ef4444"); mat.emissiveIntensity = 1.8; }
  else if (fault === "TMR_RECOVER")    { mat.emissive.set("#22c55e"); mat.emissiveIntensity = 2.0; }
  else if (highlighted)                { mat.emissive.set(ORANGE);    mat.emissiveIntensity = 0.35; }
  return mat;
}

/* ═══════════════════════════════════════════════════════════════════════════
   TYPES
═══════════════════════════════════════════════════════════════════════════ */

interface Part {
  category:      string;
  object:        THREE.Object3D;
  origPos:       THREE.Vector3;
  parentScale:   THREE.Vector3;
  trajectory:    THREE.Vector3;
  isPropeller:   boolean;
  isCore:        boolean;
}

const PROC_SUBS = [
  "CPU", "Register File", "ECC Decoder",
  "ALU Cluster", "Majority Voter",
  "Instruction Memory", "Data Memory",
];

/* ═══════════════════════════════════════════════════════════════════════════
   COMPONENT
═══════════════════════════════════════════════════════════════════════════ */

export default function DroneModel({ staticExploded = false }: { staticExploded?: boolean }) {
  const {
    isHovering, isRotating,
    highlightedModules, activeFaultModule,
    explosionFactor,
  } = useDashboard();

  const { scene: rawScene } = useGLTF("/rc_quadcopter.glb");

  /* ── 1. Clone, reset root transform, normalise, apply graphite ─────────── */
  const { cloned, normScale, normOffset, modelCenter } = useMemo(() => {
    const cloned = rawScene.clone(true);

    // Reset root transform so all child positions use a consistent coordinate space
    cloned.position.set(0, 0, 0);
    cloned.rotation.set(0, 0, 0);
    cloned.scale.set(1, 1, 1);
    cloned.updateMatrixWorld(true);

    // Compute bounding box of the reset clone
    const box    = new THREE.Box3().setFromObject(cloned);
    const sz     = box.getSize(new THREE.Vector3());
    const ct     = box.getCenter(new THREE.Vector3());
    const maxDim = Math.max(sz.x, sz.y, sz.z, 0.001);

    // normScale: brings model to ~4 screen units wide
    const normScale = 4.0 / maxDim;

    // normOffset: applied to normWrapper so model's bounding centre sits at world origin
    const normOffset = ct.clone().negate().multiplyScalar(normScale);

    // Apply matte graphite to all meshes — machined metal/plastic with subtle specular
    cloned.traverse((child) => {
      if (child instanceof THREE.Mesh) {
        const isJoint = /joint|hinge|pin|bolt|screw|rivet|bearing|shaft|rotor|prop|motor/i.test(child.name);
        const isInternal = /cpu|board|processor|memory|alu|register|decoder|voter|ecc|logic|chip|die/i.test(child.name);
        
        child.material = new THREE.MeshStandardMaterial({
          color:           isJoint ? JOINT_ACCENT_COLOR : (isInternal ? new THREE.Color("#1a1a1e") : GRAPHITE_COLOR),
          roughness:       isJoint ? 0.3 : 0.72,
          metalness:       isJoint ? 0.85 : 0.35,
          emissive:        isJoint ? JOINT_ACCENT_COLOR : new THREE.Color(0, 0, 0),
          emissiveIntensity: isJoint ? 0.15 : 0,
          envMapIntensity: 0.5,
        });
        child.castShadow    = true;
        child.receiveShadow = true;
      }
    });

    return { cloned, normScale, normOffset, modelCenter: ct };
  }, [rawScene]);

  /* ── 3. Extract separable parts ────────────────────────────────────────── */
  const parts: Part[] = useMemo(() => {
    let cands = cloned.children;
    while (cands.length === 1 && cands[0].children.length > 0) {
      cands = cands[0].children;
    }

    if (cands.length <= 1) {
      return [{
        category: "ROOT",
        object:   cloned,
        origPos:  new THREE.Vector3(),
        parentScale: new THREE.Vector3(1, 1, 1),
        trajectory: new THREE.Vector3(),
        isPropeller: false,
        isCore: true,
      }];
    }

    const box    = new THREE.Box3().setFromObject(cloned);
    const center = box.getCenter(new THREE.Vector3());
    const size   = box.getSize(new THREE.Vector3());

    const rawParts = cands.map((obj) => {
      const b       = new THREE.Box3().setFromObject(obj);
      const centroid = b.getCenter(new THREE.Vector3());
      
      let cumulativeScale = new THREE.Vector3(1, 1, 1);
      let curr = obj.parent;
      while (curr && curr !== cloned.parent) {
         cumulativeScale.multiply(curr.scale);
         curr = curr.parent;
      }
      
      return {
        category:      categorize(obj, centroid, center, size),
        object:        obj,
        origPos:       obj.position.clone(),
        parentScale:   cumulativeScale,
        centroid:      centroid,
      };
    });

    // Compute arm group centroids for perfectly radial trajectories
    const armCentroids: Record<string, THREE.Vector3> = {};
    const armCounts: Record<string, number> = {};
    
    rawParts.forEach(rp => {
      if (rp.category.startsWith("ARM_")) {
        if (!armCentroids[rp.category]) {
          armCentroids[rp.category] = new THREE.Vector3();
          armCounts[rp.category] = 0;
        }
        armCentroids[rp.category].add(rp.origPos);
        armCounts[rp.category]++;
      }
    });
    
    for (const key in armCentroids) {
      armCentroids[key].divideScalar(armCounts[key]);
    }

    return rawParts.map((rp): Part => {
      const nLower = rp.object.name.toLowerCase();
      const isPropeller = /propeller|prop|rotor|blade/.test(nLower);
      const isCore = /canopy|frame_spine|electronics|fc|board|cpu|shell|camera/.test(nLower) || 
                     ["CPU_BOARD", "SHELL_TOP", "SHELL_BOTTOM", "CAMERA", "ROOT"].includes(rp.category);
      
      let trajectory = new THREE.Vector3();
      
      if (!isCore && rp.category.startsWith("ARM_")) {
        // Procedural radial direction from core to arm centroid
        const groupCentroid = armCentroids[rp.category];
        trajectory.copy(groupCentroid).setY(0).normalize().multiplyScalar(2.0);
      } else {
        // Core components only move strictly up/down using predefined offsets
        const off = EXPLODE_OFF[rp.category];
        if (off) {
          trajectory.set(0, off[1], 0);
        }
      }

      return {
        category:      rp.category,
        object:        rp.object,
        origPos:       rp.origPos,
        parentScale:   rp.parentScale,
        trajectory:    trajectory,
        isPropeller:   isPropeller,
        isCore:        isCore,
      };
    });
  }, [cloned]);

  /* ── 4. Guide-line geometry ────────────────────────────────────────────── */
  const guideGroup = useMemo(() => {
    const g = new THREE.Group();
    parts.forEach((part, i) => {
      if (!LABELS[part.category] || part.category === "CPU_BOARD" || part.category === "ROOT") return;
      const geom = new THREE.BufferGeometry();
      geom.setAttribute("position", new THREE.BufferAttribute(new Float32Array(6), 3));
      const mat  = new THREE.LineBasicMaterial({ color: "#1a1a1f", opacity: 0, transparent: true });
      const line = new THREE.Line(geom, mat);
      (line as unknown as { __pi: number }).__pi = i;
      g.add(line);
    });
    return g;
  }, [parts]);

  /* ── 5. CPU fault glow ──────────────────────────────────────────────────── */
  const hasHL  = highlightedModules.some((m) => PROC_SUBS.includes(m));
  const cpuMat = useMemo(
    () => makeCPUMat(activeFaultModule, hasHL),
    [activeFaultModule, hasHL],
  );

  useEffect(() => {
    parts.forEach((p) => {
      if (p.category === "CPU_BOARD") {
        p.object.traverse((c) => {
          if (c instanceof THREE.Mesh) c.material = cpuMat;
        });
      }
    });
  }, [cpuMat, parts]);

  /* ── 6. Animation refs ──────────────────────────────────────────────────── */
  const groupRef  = useRef<THREE.Group>(null);
  const hoverTime = useRef(0);
  const currentExplodeFactor = useRef(0);

  useFrame((state, delta) => {
    const targetExplode = staticExploded ? 1.0 : explosionFactor;
    currentExplodeFactor.current = THREE.MathUtils.lerp(
      currentExplodeFactor.current,
      targetExplode,
      delta * 4.0
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

    const factor = currentExplodeFactor.current;

    parts.forEach((part) => {
      const targetOff = part.trajectory.clone().multiplyScalar(factor / normScale);
      
      if (part.isPropeller && factor > 0.5) {
        const propLiftFactor = (factor - 0.5) * 2.0; 
        targetOff.y += (1.5 * propLiftFactor) / normScale;
      }
      
      const adjustedOffset = targetOff.clone().divide(part.parentScale);
      part.object.position.copy(part.origPos).add(adjustedOffset);
      part.object.updateMatrixWorld(true);
    });

    guideGroup.children.forEach((child) => {
      const line = child as unknown as THREE.Line & { __pi: number };
      const part = parts[line.__pi];
      if (!part) return;

      const mat        = line.material as THREE.LineBasicMaterial;
      const targetOff  = part.trajectory.clone().multiplyScalar(factor / normScale);
      
      if (part.isPropeller && factor > 0.5) {
        const propLiftFactor = (factor - 0.5) * 2.0; 
        targetOff.y += (1.5 * propLiftFactor) / normScale;
      }
      
      const displaced  = targetOff.length();
      
      mat.opacity      = displaced > 0.04 ? factor * 0.28 : 0;
      line.visible     = mat.opacity > 0.005;

      if (line.visible) {
        const attr = (line.geometry as THREE.BufferGeometry).attributes.position as THREE.BufferAttribute;
        attr.setXYZ(0, part.origPos.x, part.origPos.y, part.origPos.z);
        const end = part.origPos.clone().add(targetOff);
        attr.setXYZ(1, end.x, end.y, end.z);
        attr.needsUpdate = true;
      }
    });
  });

  const labelPosns = useMemo((): [number, number, number][] =>
    parts.map((p) => {
      const info = LABELS[p.category];
      const yX   = info?.hero ? 0.65 : 0.32;
      const t = p.trajectory;
      const propLift = p.isPropeller ? 1.5 : 0;
      return [
        (p.origPos.x - modelCenter.x) * normScale + t.x,
        (p.origPos.y - modelCenter.y) * normScale + t.y + propLift + yX,
        (p.origPos.z - modelCenter.z) * normScale + t.z,
      ];
    }),
  [parts, normScale, modelCenter]);

  return (
    <group ref={groupRef}>
      <group
        position={[normOffset.x, normOffset.y, normOffset.z]}
        scale={normScale}
      >
        <primitive object={cloned}      />
        <primitive object={guideGroup}  />
      </group>

      {staticExploded &&
        parts.map((part, i) => {
          const info = LABELS[part.category];
          if (!info) return null;
          return (
            <Html
              key={`label-${i}`}
              position={labelPosns[i]}
              center
              distanceFactor={9}
              style={{ pointerEvents: "none" }}
            >
              <span
                style={{
                  fontFamily:    "monospace",
                  fontSize:      info.hero ? "10px" : "8px",
                  textTransform: "uppercase",
                  letterSpacing: info.hero ? "0.18em" : "0.11em",
                  color:         info.hero ? ORANGE : "rgba(255,255,255,0.30)",
                  whiteSpace:    "nowrap",
                  fontWeight:    info.hero ? 700 : 400,
                  userSelect:    "none",
                  textShadow:    info.hero
                    ? "0 0 10px rgba(249,115,22,0.95), 0 0 22px rgba(249,115,22,0.55)"
                    : "none",
                  // Very gentle fade-in on mount
                  animation:     `fadeInLabel 0.8s ease forwards 0.2s`,
                  opacity:       0,
                }}
              >
                {info.text}
              </span>
            </Html>
          );
        })}
    </group>
  );
}

useGLTF.preload("/rc_quadcopter.glb");
