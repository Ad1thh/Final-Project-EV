"use client";

import React, { useRef, useEffect } from "react";
import { Canvas } from "@react-three/fiber";
import { DashboardProvider, useDashboard } from "@/lib/DashboardContext";
import { Layers, Crosshair } from "lucide-react";
import anime from "animejs";
import * as THREE from "three";
import Navigation from "@/components/Navigation";
import { SharedScene } from "@/components/SharedScene";
import { ErrorBoundary } from "@/components/ErrorBoundary";

import { SubsystemsSharedScene } from "@/components/SubsystemsSharedScene";

function SubsystemsPanel() {
  const { highlightedModules, toggleHighlightedModule } = useDashboard();
  const panelRef = useRef<HTMLDivElement>(null);

  useEffect(() => {
    anime({
      targets: panelRef.current,
      translateX: [50, 0],
      opacity: [0, 1],
      delay: 500,
      easing: "easeOutExpo",
      duration: 1200,
    });
  }, []);

  const subsystems = [
    "CPU", "Register File", "ECC Decoder",
    "ALU Cluster", "Majority Voter",
    "Instruction Memory", "Data Memory",
  ];

  return (
    <div ref={panelRef} className="absolute right-6 top-24 bottom-24 w-72 z-10 flex flex-col gap-6 pointer-events-none">
      <div className="bg-black/60 backdrop-blur-xl border border-white/10 rounded-xl p-5 pointer-events-auto shadow-2xl">
        <h2 className="text-white/60 text-xs font-bold uppercase tracking-[0.2em] mb-4 flex items-center gap-2">
          <Layers className="w-4 h-4 text-orange-500" /> Subsystems
        </h2>

        <div className="space-y-3">
          {subsystems.map((sub) => (
            <label key={sub} className="flex items-center gap-3 cursor-pointer group">
              <div className={`w-4 h-4 rounded border flex items-center justify-center transition-colors ${
                highlightedModules.includes(sub) ? "border-orange-500 bg-orange-500/20" : "border-white/20 group-hover:border-white/40"
              }`}>
                {highlightedModules.includes(sub) && <div className="w-2 h-2 bg-orange-500 rounded-sm" />}
              </div>
              <span className="text-white/80 font-mono text-xs group-hover:text-white transition-colors">{sub}</span>
              <input
                type="checkbox"
                className="hidden"
                checked={highlightedModules.includes(sub)}
                onChange={() => toggleHighlightedModule(sub)}
              />
            </label>
          ))}
        </div>
      </div>
    </div>
  );
}

function SubsystemsPageContent() {
  return (
    <div
      className="w-screen h-screen overflow-hidden bg-grid-pattern text-white relative font-sans"
      style={{ backgroundColor: "#0d0d10" }}
    >
      <div className="absolute inset-0 bg-radial-gradient from-transparent to-black/80 pointer-events-none" />

      {/* Title */}
      <div className="absolute top-6 left-1/2 -translate-x-1/2 z-10 pointer-events-none text-center flex flex-col items-center">
        <div className="bg-black/80 px-6 py-3 rounded-xl backdrop-blur-md border border-white/5 shadow-2xl">
          <h1 className="text-xl font-bold tracking-widest text-white/90 uppercase">Fault Tolerant Processor</h1>
          <p className="text-xs font-mono text-orange-500 mt-1 uppercase tracking-widest">Hardware Subsystems</p>
        </div>
      </div>

      <Navigation />
      <SubsystemsPanel />

      <div className="absolute inset-0 z-0">
        <ErrorBoundary fallbackMessage="Incomplete GLB: Shell geometry (canopy/propeller/arm) is missing, and/or file contains old duplicate nodes (Sketchfab_model/Object_N) from an incomplete cleanup.">
          <Canvas
            shadows={{ type: THREE.PCFShadowMap }}
            camera={{ position: [10, 0, 5], fov: 50 }}
          >
            <SubsystemsSharedScene staticExploded={true} />
          </Canvas>
        </ErrorBoundary>
      </div>
    </div>
  );
}

export default function SubsystemsPage() {
  return (
    <DashboardProvider>
      <SubsystemsPageContent />
    </DashboardProvider>
  );
}
