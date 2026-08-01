"use client";

import React, { useRef, useMemo } from "react";
import { useFrame } from "@react-three/fiber";
import { useDashboard } from "@/lib/DashboardContext";
import * as THREE from "three";
import { Box, Cylinder, Sphere } from "@react-three/drei";

export default function DroneModel() {
  const {
    isExploded,
    isHovering,
    isRotating,
    highlightedModules,
    activeFaultModule,
  } = useDashboard();

  const groupRef = useRef<THREE.Group>(null);
  const hoverTime = useRef(0);

  // Smoothly interpolate positions for explode effect
  useFrame((state, delta) => {
    if (groupRef.current) {
      if (isRotating) {
        groupRef.current.rotation.y += delta * 0.2;
      }

      if (isHovering) {
        hoverTime.current += delta;
        groupRef.current.position.y = Math.sin(hoverTime.current * 2) * 0.2;
      } else {
        groupRef.current.position.y = THREE.MathUtils.lerp(groupRef.current.position.y, 0, 0.1);
      }
    }
  });

  // Materials
  const baseMaterial = useMemo(() => new THREE.MeshStandardMaterial({
    color: "#2a2a2a",
    roughness: 0.2,
    metalness: 0.8,
  }), []);

  const getModuleMaterial = (moduleName: string) => {
    let glowColor = new THREE.Color(0, 0, 0);
    let isGlowing = false;
    let emissiveIntensity = 0;

    if (highlightedModules.includes(moduleName) || highlightedModules.includes("All")) {
      glowColor.setHex(0x3b82f6); // Blue outline highlight
      isGlowing = true;
      emissiveIntensity = 0.5;
    }

    // Override with fault colors
    if (activeFaultModule) {
      if (moduleName === "CPU" && activeFaultModule === "CPU_SEC") {
        glowColor.setHex(0xf59e0b); // Amber for SEC
        isGlowing = true;
        emissiveIntensity = 2;
      } else if (moduleName === "CPU" && activeFaultModule === "CPU_DED") {
        glowColor.setHex(0xef4444); // Red for DED
        isGlowing = true;
        emissiveIntensity = 2;
      } else if (moduleName === "CPU" && activeFaultModule.startsWith("ALU_")) {
        glowColor.setHex(0xef4444); // Red for ALU fail
        isGlowing = true;
        emissiveIntensity = 2;
      } else if (moduleName === "CPU" && activeFaultModule === "TMR_RECOVER") {
        glowColor.setHex(0x22c55e); // Green for Recover
        isGlowing = true;
        emissiveIntensity = 2;
      }
    }

    if (isGlowing) {
      return new THREE.MeshStandardMaterial({
        color: glowColor,
        emissive: glowColor,
        emissiveIntensity: emissiveIntensity,
        roughness: 0.2,
        metalness: 0.8,
      });
    }

    return baseMaterial;
  };

  const explodeOffset = isExploded ? 1.5 : 0;

  // Drone Parts
  const armLength = 2.5;
  const armThickness = 0.15;
  
  return (
    <group ref={groupRef}>
      {/* Center Body - CPU & FC */}
      <Box args={[1.5, 0.4, 1.5]} position={[0, isExploded ? 0.5 : 0, 0]} castShadow material={getModuleMaterial("CPU")}>
        <meshStandardMaterial attach="material" {...getModuleMaterial("CPU")} />
      </Box>

      {/* Top Cover - Battery */}
      <Box args={[1, 0.2, 1]} position={[0, (isExploded ? 1.5 : 0) + 0.3, 0]} castShadow material={getModuleMaterial("Battery")}>
        <meshStandardMaterial attach="material" {...getModuleMaterial("Battery")} />
      </Box>
      
      {/* Bottom Cover - Camera/Sensors */}
      <Cylinder args={[0.3, 0.4, 0.5, 16]} position={[0, (isExploded ? -1.5 : 0) - 0.4, 0]} castShadow material={getModuleMaterial("Camera")}>
        <meshStandardMaterial attach="material" {...getModuleMaterial("Camera")} />
      </Cylinder>

      {/* Arms & Motors */}
      {[
        [1, 1], [1, -1], [-1, 1], [-1, -1]
      ].map(([x, z], i) => (
        <group key={`arm-${i}`} position={[x * (isExploded ? explodeOffset : 0), 0, z * (isExploded ? explodeOffset : 0)]}>
          {/* Arm */}
          <Box
            args={[armThickness, armThickness, armLength]}
            position={[x * armLength / 2.5, 0, z * armLength / 2.5]}
            rotation={[0, x * z > 0 ? -Math.PI / 4 : Math.PI / 4, 0]}
            castShadow
            material={baseMaterial}
          />
          {/* Motor / ESC */}
          <Cylinder
            args={[0.3, 0.3, 0.4, 16]}
            position={[x * armLength * 0.7, 0.1, z * armLength * 0.7]}
            castShadow
            material={getModuleMaterial("ESC")}
          >
            <meshStandardMaterial attach="material" {...getModuleMaterial("ESC")} />
          </Cylinder>
          {/* Propeller Guide/Guard (Abstracted) */}
          <Cylinder
            args={[1, 1, 0.05, 32]}
            position={[x * armLength * 0.7, 0.3, z * armLength * 0.7]}
            material={new THREE.MeshStandardMaterial({ color: "#555", transparent: true, opacity: 0.3, side: THREE.DoubleSide })}
          />
        </group>
      ))}
    </group>
  );
}
