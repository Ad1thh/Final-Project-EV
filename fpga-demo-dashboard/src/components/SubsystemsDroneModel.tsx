"use client";

import React, { useRef, useMemo, useEffect } from "react";
import { useFrame } from "@react-three/fiber";
import { useGLTF } from "@react-three/drei";
import { useDashboard } from "@/lib/DashboardContext";
import * as THREE from "three";

const ORANGE = "#f97316";
const GRAPHITE_COLOR = new THREE.Color("#141416");

const PROC_SUBS = [
  "CPU", "Register File", "ECC Decoder",
  "ALU Cluster", "Majority Voter",
  "Instruction Memory", "Data Memory",
];

const LAYER_MAP: Record<string, string> = {
  Layer_DataMemory: "Data Memory",
  Layer_InstructionMemory: "Instruction Memory",
  Layer_MajorityVoter: "Majority Voter",
  Layer_ALUCluster: "ALU Cluster",
  Layer_ECCDecoder: "ECC Decoder",
  Layer_RegisterFile: "Register File",
  Layer_CPU: "CPU",
};

// Layer order top→bottom in exploded view (matching reference video)
const LAYER_ORDER = [
  "Layer_CPU",              // highest (closest to shell)
  "Layer_RegisterFile",
  "Layer_ECCDecoder",
  "Layer_ALUCluster",
  "Layer_MajorityVoter",
  "Layer_InstructionMemory",
  "Layer_DataMemory",       // lowest
];

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

export default function SubsystemsDroneModel({ staticExploded = true }: { staticExploded?: boolean }) {
  const {
    isHovering, isRotating,
    highlightedModules, activeFaultModule,
    explosionFactor,
  } = useDashboard();

  const groupRef = useRef<THREE.Group>(null);
  const hoverTime = useRef(0);
  const currentExplodeFactor = useRef(0);

  const { scene: rawScene } = useGLTF("/rc_quadcopter_v3.glb");
  
  const nodeData = useRef<Map<string, { obj: THREE.Object3D; restPos: THREE.Vector3 }>>(new Map());
  
  const { cloned, normScale, normOffset } = useMemo(() => {
    const cloned = rawScene.clone(true);
    cloned.position.set(0, 0, 0);
    cloned.rotation.set(0, 0, 0);
    cloned.scale.set(1, 1, 1);
    cloned.updateMatrixWorld(true);

    const box = new THREE.Box3().setFromObject(cloned);
    const sz = box.getSize(new THREE.Vector3());
    const ct = box.getCenter(new THREE.Vector3());
    const maxDim = Math.max(sz.x, sz.y, sz.z, 0.001);
    
    const normScale = 4.0 / maxDim;
    const normOffset = ct.clone().negate().multiplyScalar(normScale);

    const refs = new Map<string, { obj: THREE.Object3D; restPos: THREE.Vector3 }>();
    cloned.traverse((child) => {
      const name = child.name;
      if (name.startsWith("Layer_") || 
          name.startsWith("Prop_") || 
          name.startsWith("Leg_") ||
          name === "Body_Frame" ||
          name === "Shell_DuctRing") {
        refs.set(name, { obj: child, restPos: child.position.clone() });
      }
      
      if (child instanceof THREE.Mesh) {
        const isInternal = /layer/i.test(child.name);
        
        child.material = new THREE.MeshStandardMaterial({
          color:           isInternal ? new THREE.Color("#1a1a1e") : GRAPHITE_COLOR,
          roughness:       0.72,
          metalness:       0.35,
          emissive:        new THREE.Color(0, 0, 0),
          emissiveIntensity: 0,
          envMapIntensity: 0.5,
        });
        child.castShadow = true;
        child.receiveShadow = true;
      }
    });
    nodeData.current = refs;

    return { cloned, normScale, normOffset };
  }, [rawScene]);

  // Highlight logic
  useEffect(() => {
    cloned.traverse((c) => {
      if (c instanceof THREE.Mesh && c.name.startsWith("Layer_")) {
        const layerName = LAYER_MAP[c.name];
        if (c.name === "Layer_CPU") {
          c.material = makeCPUMat(activeFaultModule, highlightedModules.includes("CPU"));
        } else if (layerName) {
          const isHL = highlightedModules.includes(layerName);
          const baseMat = c.material as THREE.MeshStandardMaterial;
          baseMat.emissive = isHL ? new THREE.Color(ORANGE) : new THREE.Color(0, 0, 0);
          baseMat.emissiveIntensity = isHL ? 0.35 : 0;
        }
      }
    });
  }, [cloned, activeFaultModule, highlightedModules]);

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

    const f = currentExplodeFactor.current;
    const refs = nodeData.current;
    
    // ========================================================
    // CODE-DRIVEN EXPLODED VIEW
    //
    // Coordinate math from hierarchy:
    //   Layers: children of Group(scale=0.001). 
    //     1 unit local Z offset → 0.001 world Y offset
    //     To move 1 world unit in Y, need 1000 local Z offset.
    //
    //   Shell pieces: children of Sketchfab_model(scale=5) > currentmodel(scale=1)
    //     within Group(scale=0.001).
    //     1 unit local Z offset → 0.001 * 5.0 = 0.005 world Y offset  
    //     To move 1 world unit in Y, need 200 local Z offset.
    //
    // Reference video layout (fully exploded):
    //   TOP:    Shell_DuctRing (floating above everything)
    //   UPPER:  Body_Frame (below duct ring, above layers)
    //   MIDDLE: 7 subsystem layers cascading vertically (CPU at top, DataMem at bottom)
    //   LOWER:  Props (below layers)  
    //   BOTTOM: Legs (at the very bottom)
    //
    // Target world Y offsets at f=1 (approximate from reference video):
    //   DuctRing:  +2.0 world Y  → +400 local Z
    //   BodyFrame: +1.0 world Y  → +200 local Z
    //   Layers:    spread from -0.5 to -3.5 world Y → spread of ~3.0 world Y total
    //   Props:     -2.0 world Y  → -400 local Z
    //   Legs:      -3.0 world Y  → -600 local Z
    // ========================================================
    
    // Shell_DuctRing + Body_Frame: rise UP together as one shell unit
    const shellUpOffset = f * 2000;  // ~10 world Y up
    for (const shellName of ["Shell_DuctRing", "Body_Frame"]) {
      const shell = refs.get(shellName);
      if (shell) {
        const r = shell.restPos;
        shell.obj.position.set(r.x, r.y, r.z + shellUpOffset);
      }
    }
    
    // Props: move DOWN well below the layers  
    for (const propName of ["Prop_1", "Prop_2", "Prop_3", "Prop_4"]) {
      const prop = refs.get(propName);
      if (prop) {
        const r = prop.restPos;
        prop.obj.position.set(r.x, r.y, r.z - f * 2500);
      }
    }
    
    // Legs: move DOWN to very bottom
    for (const legName of ["Leg_1", "Leg_2", "Leg_3", "Leg_4"]) {
      const leg = refs.get(legName);
      if (leg) {
        const r = leg.restPos;
        leg.obj.position.set(r.x, r.y, r.z - f * 3500);
      }
    }
    
    // Layers: spread evenly downward in a vertical cascade
    const layerTopZ = -8002.9;
    const layerSpacing = 600;      // ~3 world Y between each layer
    for (let i = 0; i < LAYER_ORDER.length; i++) {
      const layer = refs.get(LAYER_ORDER[i]);
      if (layer) {
        const r = layer.restPos;
        const targetZ = layerTopZ - (i * layerSpacing);
        layer.obj.position.set(
          r.x,
          r.y,
          THREE.MathUtils.lerp(r.z, targetZ, f)
        );
      }
    }
  });

  return (
    <group ref={groupRef}>
      <group position={[normOffset.x, normOffset.y, normOffset.z]} scale={normScale}>
        <primitive object={cloned} />
      </group>
    </group>
  );
}

useGLTF.preload("/rc_quadcopter_v3.glb");
