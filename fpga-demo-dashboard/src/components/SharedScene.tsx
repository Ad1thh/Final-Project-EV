"use client";

import React, { useRef, useEffect, useMemo } from "react";
import { useFrame, useThree } from "@react-three/fiber";
import { Environment, ContactShadows } from "@react-three/drei";
import * as THREE from "three";
import { useDashboard } from "@/lib/DashboardContext";
import DroneModel from "@/components/DroneModel";

export function DroneCameraController({ staticExploded = false }: { staticExploded?: boolean }) {
  const { cameraResetTrigger } = useDashboard();
  const { camera, gl } = useThree();

  const theta      = useRef(Math.PI / 4);
  const phi        = useRef(0.93);
  const radius     = useRef(12.0);
  const tgtRadius  = useRef(8.5);

  const isDragging = useRef(false);
  const lastXY     = useRef({ x: 0, y: 0 });

  useEffect(() => {
    tgtRadius.current = staticExploded ? 11.5 : 8.5;
  }, [staticExploded]);

  useEffect(() => {
    theta.current     = Math.PI / 4;
    phi.current       = 0.93;
    tgtRadius.current = staticExploded ? 11.5 : 8.5;
  }, [cameraResetTrigger, staticExploded]);

  useEffect(() => {
    const el = gl.domElement;

    const onDown = (e: PointerEvent) => {
      isDragging.current = true;
      lastXY.current     = { x: e.clientX, y: e.clientY };
    };
    const onMove = (e: PointerEvent) => {
      if (!isDragging.current) return;
      const dx   = e.clientX - lastXY.current.x;
      const dy   = e.clientY - lastXY.current.y;
      theta.current -= dx * 0.008;
      phi.current    = THREE.MathUtils.clamp(phi.current + dy * 0.005, 0.15, Math.PI / 2.1);
      lastXY.current = { x: e.clientX, y: e.clientY };
    };
    const onUp = () => { isDragging.current = false; };
    const onWheel = (e: WheelEvent) => {
      tgtRadius.current = THREE.MathUtils.clamp(
        tgtRadius.current + e.deltaY * 0.01, 4.5, 16,
      );
      e.preventDefault();
    };

    el.addEventListener("pointerdown",  onDown);
    el.addEventListener("pointermove",  onMove);
    el.addEventListener("pointerup",    onUp);
    el.addEventListener("pointerleave", onUp);
    el.addEventListener("wheel",        onWheel, { passive: false });

    return () => {
      el.removeEventListener("pointerdown",  onDown);
      el.removeEventListener("pointermove",  onMove);
      el.removeEventListener("pointerup",    onUp);
      el.removeEventListener("pointerleave", onUp);
      el.removeEventListener("wheel",        onWheel);
    };
  }, [gl]);

  useFrame((state, rawDelta) => {
    // A tab switch or a shader-compile hitch hands us a multi-second delta, which
    // makes lerp alphas exceed 1 and the camera diverge instead of settling.
    const delta = Math.min(rawDelta, 1 / 30);

    if (!isDragging.current) {
      theta.current += delta * 0.04;
      if (!staticExploded && tgtRadius.current > 7.5) {
        tgtRadius.current = Math.max(7.5, tgtRadius.current - delta * 0.04);
      }
    }

    radius.current = THREE.MathUtils.lerp(radius.current, tgtRadius.current, delta * 1.2);

    const sinP = Math.sin(phi.current);
    const cosP = Math.cos(phi.current);
    const x    = radius.current * sinP * Math.sin(theta.current);
    const y    = radius.current * cosP;
    const z    = radius.current * sinP * Math.cos(theta.current);

    camera.position.set(x, y, z);
    camera.lookAt(0, 0, 0);
    camera.updateMatrixWorld();
  });

  return null;
}

export function FloorGrid() {
  const grid = useMemo(() => {
    const g = new THREE.GridHelper(40, 40, new THREE.Color("#181820"), new THREE.Color("#141419"));
    g.position.y = -2.8;
    return g;
  }, []);
  return <primitive object={grid} />;
}

export function SharedScene({ staticExploded = false }: { staticExploded?: boolean }) {
  return (
    <>
      {/* No <color attach="background">: THREE.Color has no "transparent" keyword,
          so it fell back to white and hid the page behind the canvas. Leaving the
          background unset keeps the canvas alpha and lets the page show through. */}
      <ambientLight intensity={0.14} />
      <directionalLight position={[10, 10, 5]} intensity={0.75} castShadow shadow-mapSize-width={2048} shadow-mapSize-height={2048} />
      <pointLight position={[4, 5, 3]} intensity={0.55} color="#ffe0c0" />
      <pointLight position={[-4, 3, -3]} intensity={0.18} color="#d0d8ff" />
      <pointLight position={[0, 1.5, -5]} intensity={0.28} color="#ff9955" />
      <Environment preset="city" />
      
      <React.Suspense fallback={null}>
        <DroneModel staticExploded={staticExploded} />
      </React.Suspense>

      <ContactShadows position={[0, -2.8, 0]} opacity={0.78} scale={15} blur={2.5} far={4.5} color="#000000" />
      <FloorGrid />
      <DroneCameraController staticExploded={staticExploded} />
    </>
  );
}
