"use client";

import React, { useRef, useEffect } from "react";
import { Canvas } from "@react-three/fiber";
import { useDashboard } from "@/lib/DashboardContext";
import { Activity, Zap, Settings2, RefreshCcw, Pause, Play, Crosshair, Cpu, X, TerminalSquare, Trash2 } from "lucide-react";
import { motion, AnimatePresence } from "framer-motion";
import * as THREE from "three";
import anime from "animejs";
import Navigation from "@/components/Navigation";
import { SharedScene } from "@/components/SharedScene";

/* ═══════════════════════════════════════════════════════════════════════════
   UI PANELS  (unchanged from original — fault logic untouched)
═══════════════════════════════════════════════════════════════════════════ */

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
              ${toast.type === "error"   ? "bg-red-500/20 border-red-500/50 text-red-100"     :
                toast.type === "warning" ? "bg-amber-500/20 border-amber-500/50 text-amber-100" :
                toast.type === "success" ? "bg-green-500/20 border-green-500/50 text-green-100" :
                "bg-black/40 border-white/10 text-white"}
            `}
          >
            <div className={`h-2 w-2 rounded-full ${
              toast.type === "error"   ? "bg-red-500"   :
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

function LiveMonitor() {
  const { liveMonitor } = useDashboard();

  return (
    <div className="bg-black/60 backdrop-blur-xl border border-white/10 rounded-xl p-5 pointer-events-auto mb-6">
      <h2 className="text-white/60 text-xs font-bold uppercase tracking-[0.2em] mb-4 flex items-center gap-2">
        <Cpu className="w-4 h-4 text-orange-500" /> Live Register / ALU Monitor
      </h2>

      <div className="h-24 flex items-center justify-center border border-white/5 bg-black/40 rounded-lg relative overflow-hidden">
        <div className="absolute inset-0 bg-grid-pattern opacity-30" />

        <AnimatePresence mode="wait">
          {liveMonitor.type === "IDLE" && (
            <motion.div key="idle" initial={{opacity:0}} animate={{opacity:1}} exit={{opacity:0}} className="relative z-10">
              <span className="text-3xl font-mono text-white/90">{liveMonitor.value}</span>
            </motion.div>
          )}

          {liveMonitor.type === "SEC_INJECTED" && (
            <motion.div key="sec_inj" initial={{scale:0.9,opacity:0}} animate={{scale:1,opacity:1}} exit={{scale:0.9,opacity:0}} className="relative z-10 flex flex-col items-center">
              <span className="text-sm font-mono text-amber-500 mb-1">{liveMonitor.register} [Bit {liveMonitor.bit}]</span>
              <span className="text-3xl font-mono text-amber-500">{liveMonitor.badValue}</span>
            </motion.div>
          )}

          {liveMonitor.type === "SEC_CORRECTED" && (
            <motion.div key="sec_corr" initial={{scale:1.1,opacity:0}} animate={{scale:1,opacity:1}} exit={{opacity:0}} className="relative z-10 flex flex-col items-center">
              <span className="text-xs font-bold uppercase tracking-widest text-amber-500 mb-1 px-2 py-0.5 bg-amber-500/20 rounded border border-amber-500/30">ECC Corrected</span>
              <span className="text-3xl font-mono text-green-400">{liveMonitor.goodValue}</span>
            </motion.div>
          )}

          {liveMonitor.type === "DED_DETECTED" && (
            <motion.div key="ded" initial={{opacity:0,x:-5}} animate={{opacity:1,x:0}} exit={{opacity:0}} className="relative z-10 flex flex-col items-center">
              <span className="text-xs font-bold uppercase tracking-widest text-red-500 mb-1 px-2 py-0.5 bg-red-500/20 rounded border border-red-500/30 animate-pulse">DED Detected</span>
              <span className="text-3xl font-mono text-red-500 line-through decoration-red-500/50 decoration-2">UNRELIABLE</span>
            </motion.div>
          )}

          {liveMonitor.type === "ALU_INJECTED" && (
            <motion.div key="alu_inj" initial={{opacity:0,y:10}} animate={{opacity:1,y:0}} exit={{opacity:0,y:-10}} className="relative z-10 flex gap-4">
              {[0,1,2].map(id => (
                <div key={id} className={`flex flex-col items-center p-2 rounded border ${id === liveMonitor.aluId ? 'border-red-500/50 bg-red-500/10' : 'border-green-500/30 bg-green-500/5'}`}>
                  <span className="text-[10px] text-white/50 mb-1">ALU{id}</span>
                  <span className={`text-sm font-mono ${id === liveMonitor.aluId ? 'text-red-400' : 'text-green-400'}`}>
                    {id === liveMonitor.aluId ? liveMonitor.badValue : liveMonitor.goodValue}
                  </span>
                </div>
              ))}
            </motion.div>
          )}

          {liveMonitor.type === "ALU_RECOVERED" && (
            <motion.div key="alu_rec" initial={{scale:0.8,opacity:0}} animate={{scale:1,opacity:1}} exit={{opacity:0}} className="relative z-10 flex flex-col items-center">
              <span className="text-xs font-bold uppercase tracking-widest text-green-500 mb-1 px-2 py-0.5 bg-green-500/20 rounded border border-green-500/30">TMR Recovered</span>
              <span className="text-3xl font-mono text-green-400">{liveMonitor.goodValue}</span>
            </motion.div>
          )}
        </AnimatePresence>
      </div>
    </div>
  );
}

function LeftPanel() {
  const { processorState, currentMode, injectFault } = useDashboard();
  const panelRef = useRef<HTMLDivElement>(null);

  useEffect(() => {
    anime({
      targets: panelRef.current?.children,
      translateX: [-50, 0],
      opacity: [0, 1],
      delay: anime.stagger(100, { start: 500 }),
      easing: "easeOutExpo",
      duration: 1200,
    });
  }, []);

  return (
    <div ref={panelRef} className="absolute left-6 top-6 bottom-24 w-[340px] z-10 flex flex-col overflow-y-auto pointer-events-none pb-12 no-scrollbar">
      <LiveMonitor />

      {/* System Status Panel */}
      <div className="bg-black/60 backdrop-blur-xl border border-white/10 rounded-xl p-5 pointer-events-auto mb-6">
        <h2 className="text-white/60 text-xs font-bold uppercase tracking-[0.2em] mb-4 flex items-center gap-2">
          <Activity className="w-4 h-4 text-orange-500" /> System Status
        </h2>

        <div className="space-y-4 font-mono text-sm">
          <div className="flex justify-between items-center">
            <span className="text-white/40">Processor</span>
            <span className="text-white text-xs truncate ml-2">RV32E Fault-Tolerant</span>
          </div>
          <div className="flex justify-between items-center">
            <span className="text-white/40">Clock</span>
            <span className="text-white text-xs">100 MHz</span>
          </div>
          <div className="flex justify-between items-center">
            <span className="text-white/40">Mode</span>
            <span className="text-orange-500 text-xs">{currentMode}</span>
          </div>
          <div className="flex justify-between items-center">
            <span className="text-white/40">Health</span>
            <span className={`text-xs ${
              processorState === "Running"    ? "text-green-500"  :
              processorState === "Recovering" ? "text-amber-500"  : "text-red-500"
            }`}>
              {processorState}
            </span>
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
            className="w-full bg-white/5 hover:bg-white/10 border border-white/10 text-white font-mono text-xs py-3 px-4 rounded transition-colors text-left flex justify-between group"
          >
            <span>Single-bit ECC</span>
            <span className="text-orange-500/50 group-hover:text-orange-500 text-[10px] font-bold tracking-widest transition-colors">INJECT</span>
          </button>

          <button
            onClick={() => injectFault("DED")}
            className="w-full bg-white/5 hover:bg-white/10 border border-white/10 text-white font-mono text-xs py-3 px-4 rounded transition-colors text-left flex justify-between group"
          >
            <span>Double-bit ECC</span>
            <span className="text-orange-500/50 group-hover:text-orange-500 text-[10px] font-bold tracking-widest transition-colors">INJECT</span>
          </button>

          <button
            onClick={() => injectFault("ALU", undefined, undefined, "1")}
            className="w-full bg-white/5 hover:bg-white/10 border border-white/10 text-white font-mono text-xs py-3 px-4 rounded transition-colors text-left flex justify-between group"
          >
            <span>ALU Fault</span>
            <span className="text-orange-500/50 group-hover:text-orange-500 text-[10px] font-bold tracking-widest transition-colors">INJECT</span>
          </button>
        </div>
      </div>
    </div>
  );
}

function RightPanel() {
  const {
    isHovering, setIsHovering,
    isRotating, setIsRotating,
  } = useDashboard();

  const panelRef = useRef<HTMLDivElement>(null);

  useEffect(() => {
    anime({
      targets: panelRef.current?.children,
      translateX: [50, 0],
      opacity: [0, 1],
      delay: anime.stagger(100, { start: 500 }),
      easing: "easeOutExpo",
      duration: 1200,
    });
  }, []);

  return (
    <div ref={panelRef} className="absolute right-6 top-6 bottom-24 w-72 z-10 flex flex-col gap-6 pointer-events-none">
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

        </div>
      </div>
    </div>
  );
}

function TerminalPanel() {
  const { isTerminalOpen, setIsTerminalOpen, uartLogs, clearTerminal } = useDashboard();
  const logsEndRef = useRef<HTMLDivElement>(null);

  useEffect(() => {
    if (logsEndRef.current) {
      logsEndRef.current.scrollIntoView({ behavior: "smooth" });
    }
  }, [uartLogs, isTerminalOpen]);

  return (
    <AnimatePresence>
      {isTerminalOpen && (
        <motion.div
          initial={{ x: 400, opacity: 0 }}
          animate={{ x: 0, opacity: 1 }}
          exit={{ x: 400, opacity: 0 }}
          transition={{ type: "spring", damping: 25, stiffness: 200 }}
          className="absolute right-0 top-0 bottom-0 w-96 bg-black/90 backdrop-blur-3xl border-l border-white/10 shadow-2xl z-50 flex flex-col pointer-events-auto"
        >
          <div className="flex items-center justify-between p-4 border-b border-white/10 bg-black/50">
            <h2 className="text-white/80 text-sm font-bold uppercase tracking-widest flex items-center gap-2">
              <TerminalSquare className="w-4 h-4 text-green-500" /> Serial Console
            </h2>
            <div className="flex items-center gap-2">
              <button onClick={clearTerminal} className="text-white/40 hover:text-red-400 transition-colors p-1" title="Clear Logs">
                <Trash2 className="w-4 h-4" />
              </button>
              <button onClick={() => setIsTerminalOpen(false)} className="text-white/40 hover:text-white transition-colors p-1">
                <X className="w-5 h-5" />
              </button>
            </div>
          </div>
          
          <div className="flex-1 overflow-y-auto p-4 font-mono text-[11px] leading-relaxed no-scrollbar bg-[#050505]">
            {uartLogs.length === 0 ? (
              <div className="text-white/30 h-full flex items-center justify-center italic">No UART activity yet...</div>
            ) : (
              uartLogs.map((log, i) => (
                <div key={i} className={`mb-1 ${log.includes("TX") ? "text-blue-400" : log.includes("Error") ? "text-red-400" : "text-green-400"}`}>
                  {log}
                </div>
              ))
            )}
            <div ref={logsEndRef} />
          </div>
        </motion.div>
      )}
    </AnimatePresence>
  );
}

function BottomToolbar() {
  const {
    resetDemo,
    isDemoActive, setIsDemoActive,
    triggerCameraReset,
    injectFault,
  } = useDashboard();

  const toolbarRef = useRef<HTMLDivElement>(null);

  useEffect(() => {
    anime({
      targets: toolbarRef.current,
      translateY: [50, 0],
      opacity: [0, 1],
      delay: 800,
      easing: "easeOutExpo",
      duration: 1200,
    });
  }, []);

  return (
    <div ref={toolbarRef} className="absolute bottom-6 left-1/2 -translate-x-1/2 z-10 pointer-events-none">
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
            const faults: ("SEC" | "DED" | "ALU")[] = ["SEC", "DED", "ALU"];
            const randomFault = faults[Math.floor(Math.random() * faults.length)];
            injectFault(randomFault, "x5", "0", "0");
          }}
          className="px-6 py-2.5 bg-orange-500 hover:bg-orange-600 text-white font-mono text-xs font-bold tracking-widest rounded-full transition-colors flex items-center gap-2"
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

/* ═══════════════════════════════════════════════════════════════════════════
   DASHBOARD ROOT
═══════════════════════════════════════════════════════════════════════════ */

export default function Dashboard() {
  const { dashboardType, setDashboardType, dataSourceInfo, connectFPGA, isTerminalOpen, setIsTerminalOpen } = useDashboard();
  
  // No longer forcing software on mount, rely on context defaults.

  return (
      <div
        className="w-screen h-screen overflow-hidden bg-grid-pattern text-white relative font-sans"
        style={{ backgroundColor: "#0d0d10" }}
      >
        {/* Warm near-black charcoal background (#0d0d10) — not pure black */}

        {/* Radial vignette to focus the eye on the 3-D subject */}
        <div className="absolute inset-0 bg-radial-gradient from-transparent to-black/80 pointer-events-none" />

        {/* Title and Toggle */}
        <div className="absolute top-6 left-[23rem] right-[30rem] z-10 pointer-events-none flex flex-col items-center gap-3">
          <div className={`pointer-events-auto px-6 py-3 rounded-xl backdrop-blur-md border shadow-2xl transition-colors duration-500 flex flex-col items-center ${
            dashboardType === "hardware" ? "bg-green-900/40 border-green-500/30" : "bg-black/80 border-white/5"
          }`}>
            <h1 className={`text-xl font-bold tracking-widest uppercase transition-colors duration-500 ${
              dashboardType === "hardware" ? "text-green-100" : "text-white/90"
            }`}>
              {dashboardType === "hardware" ? "Hardware-in-the-Loop" : "Fault Tolerant Processor"}
            </h1>
            <p className={`text-xs font-mono mt-1 uppercase tracking-widest transition-colors duration-500 flex items-center justify-center gap-2 ${
              dashboardType === "hardware" ? "text-green-400" : "text-orange-500"
            }`}>
              {dashboardType === "hardware" && <span className="w-2 h-2 rounded-full bg-green-500 animate-pulse"></span>}
              Live Diagnostics
            </p>
          </div>
          
          {/* Hardware/Software Toggle */}
          <div className="pointer-events-auto bg-black/60 backdrop-blur-xl border border-white/10 p-1.5 rounded-full flex items-center shadow-lg">
            <button
              onClick={() => setDashboardType("software")}
              className={`px-4 py-1.5 rounded-full text-xs font-bold uppercase tracking-widest transition-colors ${
                dashboardType === "software" ? "bg-orange-500 text-white" : "text-white/60 hover:text-white"
              }`}
            >
              Software
            </button>
            <button
              onClick={() => setDashboardType("hardware")}
              className={`px-4 py-1.5 rounded-full text-xs font-bold uppercase tracking-widest transition-colors ${
                dashboardType === "hardware" ? "bg-green-500 text-white" : "text-white/60 hover:text-white"
              }`}
            >
              Hardware
            </button>
          </div>
        </div>

        <Navigation />

        {/* Terminal Button */}
        <button 
          onClick={() => setIsTerminalOpen(true)}
          className="absolute top-20 right-6 z-40 bg-black/60 backdrop-blur-xl border border-white/10 p-3 rounded-full hover:bg-white/10 transition-colors pointer-events-auto shadow-lg group"
          title="Open UART Terminal"
        >
          <TerminalSquare className="w-5 h-5 text-white/60 group-hover:text-green-400 transition-colors" />
        </button>

        <ToastContainer />
        <LeftPanel />
        <RightPanel />
        <BottomToolbar />
        <TerminalPanel />

        {/* 3-D Canvas */}
        <div className="absolute inset-0 z-0">
          <Canvas
            shadows={{ type: THREE.PCFShadowMap }}
            camera={{ position: [8, 4, 8], fov: 45 }}
          >
            <SharedScene />
          </Canvas>
        </div>

        {/* Disconnected Overlay (Only in Hardware Mode) */}
        {dashboardType === "hardware" && !dataSourceInfo.isConnected && (
          <div className="absolute inset-0 z-50 flex items-center justify-center bg-black/80 backdrop-blur-sm">
            <div className="bg-black/90 p-8 rounded-2xl border border-white/10 text-center max-w-md shadow-2xl relative">
              <button
                onClick={() => setDashboardType("software")}
                className="absolute top-4 right-4 text-white/50 hover:text-white transition-colors p-1"
                title="Return to Software Mode"
              >
                <X className="w-5 h-5" />
              </button>
              
              <div className="w-16 h-16 bg-red-500/20 rounded-full flex items-center justify-center mx-auto mb-4 border border-red-500/30">
                <Cpu className="w-8 h-8 text-red-500" />
              </div>
              <h2 className="text-2xl font-bold text-white mb-2 tracking-wide uppercase">Board Disconnected</h2>
              <p className="text-white/60 text-sm mb-8">
                Hardware-in-the-Loop mode requires a live connection to the Zybo Z7 FPGA board via USB UART.
              </p>
              <button 
                onClick={connectFPGA}
                className="w-full py-4 bg-green-600 hover:bg-green-500 text-white font-bold tracking-widest uppercase rounded-lg transition-colors flex items-center justify-center gap-2"
              >
                <Zap className="w-5 h-5 fill-white" /> Connect to FPGA
              </button>
            </div>
          </div>
        )}
      </div>
  );
}
