"use client";

import React from "react";
import { Environment, ContactShadows } from "@react-three/drei";
import { DroneCameraController, FloorGrid } from "@/components/SharedScene";
import SubsystemsDroneModel from "@/components/SubsystemsDroneModel";

export function SubsystemsSharedScene({ staticExploded = false }: { staticExploded?: boolean }) {
  return (
    <>
      <color attach="background" args={["transparent"]} />
      <ambientLight intensity={0.14} />
      <directionalLight position={[10, 10, 5]} intensity={0.75} castShadow shadow-mapSize-width={2048} shadow-mapSize-height={2048} />
      <pointLight position={[4, 5, 3]} intensity={0.55} color="#ffe0c0" />
      <pointLight position={[-4, 3, -3]} intensity={0.18} color="#d0d8ff" />
      <pointLight position={[0, 1.5, -5]} intensity={0.28} color="#ff9955" />
      <Environment preset="city" />
      
      <React.Suspense fallback={null}>
        <SubsystemsDroneModel staticExploded={staticExploded} />
      </React.Suspense>

      <ContactShadows position={[0, -2.8, 0]} opacity={0.78} scale={15} blur={2.5} far={4.5} color="#000000" />
      <FloorGrid />
      <DroneCameraController staticExploded={staticExploded} />
    </>
  );
}
