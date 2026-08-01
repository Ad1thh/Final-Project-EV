"use client";

import React, { useEffect } from "react";
import { Canvas } from "@react-three/fiber";
import { Environment, OrbitControls, ContactShadows } from "@react-three/drei";
import { DashboardProvider, useDashboard } from "@/lib/DashboardContext";
import DroneModel from "@/components/DroneModel";
import { Activity, Zap, Layers, Settings2, RefreshCcw, Power, Pause, Play, Crosshair } from "lucide-react";
import { motion, AnimatePresence } from "framer-motion";

function ToastContainer() {
  const { toasts } = useDashboard();
  return (
    <div className="absolute top-4 right-4 z-50 flex flex-col gap-2 pointer-events-none">
      <AnimatePresence>
        {toasts.map((toast) => (
          <motion.div
            key={toast.id}
            initial={{ opacity: 0, x: 50, scale: 0.9 }}
            animate={{ opacity: 1, x: 0, scale: 1 }}
            exit={{ opacity: 0, scale: 0.9 }}
            className={`
              pointer-events-auto px-4 py-3 rounded-md backdrop-blur-md border shadow-lg flex items-center gap-3 min-w-[300px]
              ${toast.type === "error" ? "bg-red-500/20 border-red-500/50 text-red-100" :
                toast.type === "warning" ? "bg-amber-500/20 border-amber-500/50 text-amber-100" :
                toast.type === "success" ? "bg-green-500/20 border-green-500/50 text-green-100" :
                "bg-black/40 border-white/10 text-white"}
            `}
          >
            <div className={`h-2 w-2 rounded-full ${
              toast.type === "error" ? "bg-red-500" :
              toast.type === "warning" ? "bg-amber-500" :
              toast.type === "success" ? "bg-green-500" : "bg-blue-500"
            }`} />
            <span className="font-mono text-sm">{toast.message}</span>
          </motion.div>
        ))}
      </AnimatePresence>
    </div>
  );
}

function LeftPanel() {
  const { processorState, clock, currentMode, registers, secCount, dedCount, injectFault } = useDashboard();

  return (
    <div className="absolute left-6 top-6 bottom-24 w-80 z-10 flex flex-col gap-6 overflow-y-auto pointer-events-none pb-12 no-scrollbar">
      {/* System Status Panel */}
      <div className="bg-black/60 backdrop-blur-xl border border-white/10 rounded-xl p-5 pointer-events-auto">
        <h2 className="text-white/60 text-xs font-bold uppercase tracking-[0.2em] mb-4 flex items-center gap-2">
          <Activity className="w-4 h-4 text-orange-500" /> System Status
        </h2>
        
        <div className="space-y-4 font-mono text-sm">
          <div className="flex justify-between items-center">
            <span className="text-white/40">Processor</span>
            <span className="text-white">RV32E Fault-Tolerant</span>
          </div>
          <div className="flex justify-between items-center">
            <span className="text-white/40">Clock</span>
            <span className="text-white">{clock}</span>
          </div>
          <div className="flex justify-between items-center">
            <span className="text-white/40">Mode</span>
            <span className="text-orange-500">{currentMode}</span>
          </div>
          <div className="flex justify-between items-center">
            <span className="text-white/40">Health</span>
            <span className={processorState === "Running" ? "text-green-500" : "text-red-500"}>{processorState}</span>
          </div>
        </div>
      </div>

      {/* Fault Injection Panel */}
      <div className="bg-black/60 backdrop-blur-xl border border-white/10 rounded-xl p-5 pointer-events-auto">
        <h2 className="text-white/60 text-xs font-bold uppercase tracking-[0.2em] mb-4 flex items-center gap-2">
          <Zap className="w-4 h-4 text-orange-500" /> Fault Injection
        </h2>
        
        <div className="space-y-3">
          <button 
            onClick={() => injectFault("SEC")}
            className="w-full bg-white/5 hover:bg-white/10 border border-white/10 text-white font-mono text-xs py-3 px-4 rounded transition-colors text-left flex justify-between"
          >
            <span>Single-bit ECC</span>
            <span className="text-white/40 text-[10px]">INJECT</span>
          </button>
          
          <button 
            onClick={() => injectFault("DED")}
            className="w-full bg-white/5 hover:bg-white/10 border border-white/10 text-white font-mono text-xs py-3 px-4 rounded transition-colors text-left flex justify-between"
          >
            <span>Double-bit ECC</span>
            <span className="text-white/40 text-[10px]">INJECT</span>
          </button>
          
          <button 
            onClick={() => injectFault("ALU", undefined, undefined, "1")}
            className="w-full bg-white/5 hover:bg-white/10 border border-white/10 text-white font-mono text-xs py-3 px-4 rounded transition-colors text-left flex justify-between"
          >
            <span>ALU Fault</span>
            <span className="text-white/40 text-[10px]">INJECT</span>
          </button>
        </div>
      </div>
    </div>
  );
}

function RightPanel() {
  const { 
    isExploded, setIsExploded, 
    isHovering, setIsHovering,
    isRotating, setIsRotating,
    highlightedModules, toggleHighlightedModule
  } = useDashboard();

  const subsystems = ["CPU", "Battery", "Camera", "ESC"];

  return (
    <div className="absolute right-6 top-6 bottom-24 w-72 z-10 flex flex-col gap-6 pointer-events-none">
      {/* Subsystems Panel */}
      <div className="bg-black/60 backdrop-blur-xl border border-white/10 rounded-xl p-5 pointer-events-auto">
        <h2 className="text-white/60 text-xs font-bold uppercase tracking-[0.2em] mb-4 flex items-center gap-2">
          <Layers className="w-4 h-4 text-orange-500" /> Subsystems
        </h2>
        
        <div className="space-y-2">
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

      {/* Animations Panel */}
      <div className="bg-black/60 backdrop-blur-xl border border-white/10 rounded-xl p-5 pointer-events-auto">
        <h2 className="text-white/60 text-xs font-bold uppercase tracking-[0.2em] mb-4 flex items-center gap-2">
          <Settings2 className="w-4 h-4 text-orange-500" /> Animations
        </h2>
        
        <div className="space-y-4">
          <label className="flex items-center justify-between cursor-pointer group">
            <span className="text-white/80 font-mono text-xs group-hover:text-white transition-colors">Idle Rotation</span>
            <div className={`w-8 h-4 rounded-full transition-colors relative ${isRotating ? "bg-orange-500" : "bg-white/20"}`}>
              <div className={`w-3 h-3 rounded-full bg-white absolute top-0.5 transition-transform ${isRotating ? "translate-x-4.5" : "translate-x-0.5"}`} />
            </div>
            <input type="checkbox" className="hidden" checked={isRotating} onChange={(e) => setIsRotating(e.target.checked)} />
          </label>

          <label className="flex items-center justify-between cursor-pointer group">
            <span className="text-white/80 font-mono text-xs group-hover:text-white transition-colors">Hover Animation</span>
            <div className={`w-8 h-4 rounded-full transition-colors relative ${isHovering ? "bg-orange-500" : "bg-white/20"}`}>
              <div className={`w-3 h-3 rounded-full bg-white absolute top-0.5 transition-transform ${isHovering ? "translate-x-4.5" : "translate-x-0.5"}`} />
            </div>
            <input type="checkbox" className="hidden" checked={isHovering} onChange={(e) => setIsHovering(e.target.checked)} />
          </label>

          <label className="flex items-center justify-between cursor-pointer group">
            <span className="text-white/80 font-mono text-xs group-hover:text-white transition-colors">Exploded View</span>
            <div className={`w-8 h-4 rounded-full transition-colors relative ${isExploded ? "bg-orange-500" : "bg-white/20"}`}>
              <div className={`w-3 h-3 rounded-full bg-white absolute top-0.5 transition-transform ${isExploded ? "translate-x-4.5" : "translate-x-0.5"}`} />
            </div>
            <input type="checkbox" className="hidden" checked={isExploded} onChange={(e) => setIsExploded(e.target.checked)} />
          </label>
        </div>
      </div>
    </div>
  );
}

function BottomToolbar() {
  const { 
    resetDemo, 
    isDemoActive, setIsDemoActive,
    triggerCameraReset,
    injectFault
  } = useDashboard();

  return (
    <div className="absolute bottom-6 left-1/2 -translate-x-1/2 z-10 pointer-events-none">
      <div className="bg-black/60 backdrop-blur-xl border border-white/10 rounded-full p-2 flex items-center gap-2 pointer-events-auto">
        <button 
          onClick={resetDemo}
          className="p-3 hover:bg-white/10 rounded-full text-white/70 hover:text-white transition-colors"
          title="Reset Demo"
        >
          <RefreshCcw className="w-5 h-5" />
        </button>

        <button 
          onClick={() => {
            const faults: any[] = ["SEC", "DED", "ALU", "MODE"];
            const randomFault = faults[Math.floor(Math.random() * faults.length)];
            injectFault(randomFault, "x5", "0", "0");
          }}
          className="px-6 py-2.5 bg-orange-500 hover:bg-orange-600 text-white font-mono text-xs font-bold rounded-full transition-colors flex items-center gap-2"
        >
          <Zap className="w-4 h-4 fill-white" />
          INJECT RANDOM
        </button>

        <button 
          onClick={() => setIsDemoActive(!isDemoActive)}
          className={`p-3 rounded-full transition-colors ${isDemoActive ? "text-orange-500 hover:bg-orange-500/10" : "text-white/70 hover:bg-white/10 hover:text-white"}`}
          title={isDemoActive ? "Pause Auto Demo" : "Start Auto Demo"}
        >
          {isDemoActive ? <Pause className="w-5 h-5" /> : <Play className="w-5 h-5" />}
        </button>

        <button 
          onClick={triggerCameraReset}
          className="p-3 hover:bg-white/10 rounded-full text-white/70 hover:text-white transition-colors"
          title="Center Camera"
        >
          <Crosshair className="w-5 h-5" />
        </button>
      </div>
    </div>
  );
}

function Scene() {
  return (
    <>
      <color attach="background" args={["#0a0a0a"]} />
      <ambientLight intensity={0.5} />
      <spotLight position={[10, 10, 10]} angle={0.15} penumbra={1} intensity={1} castShadow />
      <Environment preset="city" />
      <DroneModel />
      <ContactShadows position={[0, -2.5, 0]} opacity={0.5} scale={10} blur={2} far={4} />
      <OrbitControls makeDefault enablePan={false} maxPolarAngle={Math.PI / 2 + 0.1} minDistance={5} maxDistance={15} />
    </>
  );
}

export default function Dashboard() {
  return (
    <DashboardProvider>
      <div className="w-screen h-screen overflow-hidden bg-black text-white relative font-sans">
        {/* Title */}
        <div className="absolute top-6 left-1/2 -translate-x-1/2 z-10 pointer-events-none text-center">
          <h1 className="text-xl font-bold tracking-widest text-white/90 uppercase">Fault Tolerant Processor</h1>
          <p className="text-xs font-mono text-orange-500 mt-1 uppercase tracking-widest">Live Diagnostics</p>
        </div>

        <ToastContainer />
        <LeftPanel />
        <RightPanel />
        <BottomToolbar />
        
        <Canvas shadows camera={{ position: [8, 4, 8], fov: 45 }}>
          <Scene />
        </Canvas>
      </div>
    </DashboardProvider>
  );
}
