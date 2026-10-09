"use client";

import React, { useRef, useEffect, useState } from "react";
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
    <div className="bg-black/60 backdrop-blur-xl border border-white/10 rounded-xl p-3 pointer-events-auto mb-2">
      <h2 className="text-white/60 text-[11px] font-bold uppercase tracking-[0.2em] mb-1.5 flex items-center gap-1.5">
        <Cpu className="w-3.5 h-3.5 text-orange-500" /> Live Register / ALU Monitor
      </h2>

      <div className="h-16 flex items-center justify-center border border-white/5 bg-black/40 rounded-lg relative overflow-hidden">
        <div className="absolute inset-0 bg-grid-pattern opacity-30" />

        <AnimatePresence mode="wait">
          {liveMonitor.type === "IDLE" && (
            <motion.div key="idle" initial={{opacity:0}} animate={{opacity:1}} exit={{opacity:0}} className="relative z-10">
              <span className="text-2xl font-mono text-white/90">{liveMonitor.value}</span>
            </motion.div>
          )}

          {liveMonitor.type === "SEC_INJECTED" && (
            <motion.div key="sec_inj" initial={{scale:0.9,opacity:0}} animate={{scale:1,opacity:1}} exit={{scale:0.9,opacity:0}} className="relative z-10 flex flex-col items-center">
              <span className="text-xs font-mono text-amber-500">{liveMonitor.register} [Bit {liveMonitor.bit}]</span>
              <span className="text-2xl font-mono text-amber-500">{liveMonitor.badValue}</span>
            </motion.div>
          )}

          {liveMonitor.type === "SEC_CORRECTED" && (
            <motion.div key="sec_corr" initial={{scale:1.1,opacity:0}} animate={{scale:1,opacity:1}} exit={{opacity:0}} className="relative z-10 flex flex-col items-center">
              <span className="text-[10px] font-bold uppercase tracking-widest text-amber-500 px-1.5 py-0.2 bg-amber-500/20 rounded border border-amber-500/30">ECC Corrected</span>
              <span className="text-2xl font-mono text-green-400">{liveMonitor.goodValue}</span>
            </motion.div>
          )}

          {liveMonitor.type === "DED_DETECTED" && (
            <motion.div key="ded" initial={{opacity:0,x:-5}} animate={{opacity:1,x:0}} exit={{opacity:0}} className="relative z-10 flex flex-col items-center">
              <span className="text-[10px] font-bold uppercase tracking-widest text-red-500 px-1.5 py-0.2 bg-red-500/20 rounded border border-red-500/30 animate-pulse">DED Detected</span>
              <span className="text-2xl font-mono text-red-500 line-through decoration-red-500/50 decoration-2">UNRELIABLE</span>
            </motion.div>
          )}

          {liveMonitor.type === "ALU_INJECTED" && (
            <motion.div key="alu_inj" initial={{opacity:0,y:5}} animate={{opacity:1,y:0}} exit={{opacity:0,y:-5}} className="relative z-10 flex gap-2">
              {[0,1,2].map(id => (
                <div key={id} className={`flex flex-col items-center p-1.5 rounded border ${id === liveMonitor.aluId ? 'border-red-500/50 bg-red-500/10' : 'border-green-500/30 bg-green-500/5'}`}>
                  <span className="text-[9px] text-white/50">ALU{id}</span>
                  <span className={`text-xs font-mono ${id === liveMonitor.aluId ? 'text-red-400' : 'text-green-400'}`}>
                    {id === liveMonitor.aluId ? liveMonitor.badValue : liveMonitor.goodValue}
                  </span>
                </div>
              ))}
            </motion.div>
          )}

          {liveMonitor.type === "ALU_RECOVERED" && (
            <motion.div key="alu_rec" initial={{scale:0.8,opacity:0}} animate={{scale:1,opacity:1}} exit={{opacity:0}} className="relative z-10 flex flex-col items-center">
              <span className="text-[10px] font-bold uppercase tracking-widest text-green-500 px-1.5 py-0.2 bg-green-500/20 rounded border border-green-500/30">TMR Recovered</span>
              <span className="text-2xl font-mono text-green-400">{liveMonitor.goodValue}</span>
            </motion.div>
          )}
        </AnimatePresence>
      </div>
    </div>
  );
}

function LeftPanel() {
  const { processorState, currentMode, injectFault, dashboardType, activeProtectionEvent } = useDashboard();
  const panelRef = useRef<HTMLDivElement>(null);

  const isSecActive = activeProtectionEvent === "SEC";
  const isDedActive = activeProtectionEvent === "DED" || processorState === "Degraded";
  const isTmrActive = activeProtectionEvent === "TMR";
  const isModeActive = activeProtectionEvent === "MODE" || currentMode === "Triple Modular Redundancy";
  const isResetActive = activeProtectionEvent === "RESET";

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
    <div ref={panelRef} className="absolute left-6 top-6 bottom-6 w-[340px] z-10 flex flex-col overflow-y-auto pointer-events-none pb-4 no-scrollbar">
      <LiveMonitor />

      {/* System Status Panel */}
      <div className="bg-black/60 backdrop-blur-xl border border-white/10 rounded-xl p-3 pointer-events-auto mb-2">
        <h2 className="text-white/60 text-[11px] font-bold uppercase tracking-[0.2em] mb-1.5 flex items-center gap-1.5">
          <Activity className="w-3.5 h-3.5 text-orange-500" /> System Status
        </h2>

        <div className="space-y-1.5 font-mono text-xs">
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

      {/* Controls Panel: Pin Planning Guide in Hardware Mode vs Injection in Software Mode */}
      {dashboardType === "hardware" ? (
        <div className="bg-black/70 backdrop-blur-xl border border-green-500/30 rounded-xl p-3 pointer-events-auto shadow-2xl">
          <div className="flex items-center justify-between mb-2">
            <h2 className="text-green-400 text-[11px] font-bold uppercase tracking-[0.2em] flex items-center gap-1.5">
              <Cpu className="w-3.5 h-3.5 text-green-400" /> Zybo Board Controls
            </h2>
            <span className="flex items-center gap-1.5 px-2 py-0.5 rounded-full bg-green-500/20 border border-green-500/40 text-[9px] font-mono text-green-300 font-bold tracking-wider">
              <span className="w-1.5 h-1.5 rounded-full bg-green-400 animate-pulse"></span>
              EXCLUSIVE HW
            </span>
          </div>

          <p className="text-[9.5px] text-white/50 mb-2 leading-tight">
            Fault injections and resets are routed solely through physical Zybo board inputs.
          </p>

          <div className="space-y-1.5 font-mono text-xs">
            {/* BTN1: SEC */}
            <div className={`rounded-lg p-1.5 flex items-center justify-between transition-all duration-300 ${
              isSecActive 
                ? "bg-orange-500/20 border border-orange-500 shadow-[0_0_15px_rgba(249,115,22,0.4)] ring-1 ring-orange-500/50" 
                : "bg-white/5 border border-white/10"
            }`}>
              <div>
                <div className="flex items-center gap-1.5">
                  <span className={`px-1.5 py-0.5 rounded text-[9px] font-bold border transition-colors ${
                    isSecActive ? "bg-orange-500 text-black border-orange-400 font-extrabold" : "bg-orange-500/20 text-orange-400 border-orange-500/30"
                  }`}>BTN1 · P16</span>
                  <span className="text-white/90 font-semibold text-[10px]">SEC Fault</span>
                </div>
                <div className="text-[8.5px] text-white/40 mt-0.5">Flip 1 bit in Reg x1 (ECC auto-corrected)</div>
              </div>
              {isSecActive ? (
                <span className="text-[9px] text-orange-300 font-bold flex items-center gap-1 animate-pulse">
                  <span className="w-1.5 h-1.5 rounded-full bg-orange-400 animate-ping"></span>
                  CORRECTING
                </span>
              ) : (
                <span className="text-[9px] text-orange-400 font-bold">READY</span>
              )}
            </div>

            {/* BTN2: DED */}
            <div className={`rounded-lg p-1.5 flex items-center justify-between transition-all duration-300 ${
              isDedActive 
                ? "bg-red-500/20 border border-red-500 shadow-[0_0_15px_rgba(239,68,68,0.4)] ring-1 ring-red-500/50" 
                : "bg-white/5 border border-white/10"
            }`}>
              <div>
                <div className="flex items-center gap-1.5">
                  <span className={`px-1.5 py-0.5 rounded text-[9px] font-bold border transition-colors ${
                    isDedActive ? "bg-red-500 text-white border-red-400 font-extrabold" : "bg-red-500/20 text-red-400 border-red-500/30"
                  }`}>BTN2 · V16</span>
                  <span className="text-white/90 font-semibold text-[10px]">DED Fault</span>
                </div>
                <div className="text-[8.5px] text-white/40 mt-0.5">Flip 2 bits in Reg x1 (CPU safe trap)</div>
              </div>
              {isDedActive ? (
                <span className="text-[9px] text-red-300 font-bold flex items-center gap-1 animate-pulse">
                  <span className="w-1.5 h-1.5 rounded-full bg-red-400 animate-ping"></span>
                  TRAPPED
                </span>
              ) : (
                <span className="text-[9px] text-red-400 font-bold">TRAP</span>
              )}
            </div>

            {/* BTN3: ALU */}
            <div className={`rounded-lg p-1.5 flex items-center justify-between transition-all duration-300 ${
              isTmrActive 
                ? "bg-blue-500/20 border border-blue-500 shadow-[0_0_15px_rgba(59,130,246,0.4)] ring-1 ring-blue-500/50" 
                : "bg-white/5 border border-white/10"
            }`}>
              <div>
                <div className="flex items-center gap-1.5">
                  <span className={`px-1.5 py-0.5 rounded text-[9px] font-bold border transition-colors ${
                    isTmrActive ? "bg-blue-500 text-white border-blue-400 font-extrabold" : "bg-blue-500/20 text-blue-400 border-blue-500/30"
                  }`}>BTN3 · Y16</span>
                  <span className="text-white/90 font-semibold text-[10px]">ALU Fault</span>
                </div>
                <div className="text-[8.5px] text-white/40 mt-0.5">Corrupt ALU0 (TMR voter masks)</div>
              </div>
              {isTmrActive ? (
                <span className="text-[9px] text-blue-300 font-bold flex items-center gap-1 animate-pulse">
                  <span className="w-1.5 h-1.5 rounded-full bg-blue-400 animate-ping"></span>
                  MASKING
                </span>
              ) : (
                <span className="text-[9px] text-blue-400 font-bold">MASK</span>
              )}
            </div>

            {/* SW0: Mode */}
            <div className={`rounded-lg p-1.5 flex items-center justify-between transition-all duration-300 ${
              isModeActive 
                ? "bg-purple-500/20 border border-purple-500 shadow-[0_0_15px_rgba(168,85,247,0.3)] ring-1 ring-purple-500/50" 
                : "bg-white/5 border border-white/10"
            }`}>
              <div>
                <div className="flex items-center gap-1.5">
                  <span className={`px-1.5 py-0.5 rounded text-[9px] font-bold border transition-colors ${
                    currentMode === "Triple Modular Redundancy" ? "bg-purple-500 text-white border-purple-400 font-extrabold" : "bg-purple-500/20 text-purple-400 border-purple-500/30"
                  }`}>SW0 · G15</span>
                  <span className="text-white/90 font-semibold text-[10px]">Mode Selector</span>
                </div>
                <div className="text-[8.5px] text-white/40 mt-0.5">Down: Simplex | Up: TMR Mode</div>
              </div>
              <span className={`text-[9px] font-bold ${currentMode === "Triple Modular Redundancy" ? "text-purple-300" : "text-white/40"}`}>
                {currentMode === "Simplex" ? "SIMPLEX" : "TMR MODE"}
              </span>
            </div>

            {/* BTN0: Reset */}
            <div className={`rounded-lg p-1.5 flex items-center justify-between transition-all duration-300 ${
              isResetActive 
                ? "bg-emerald-500/20 border border-emerald-400 shadow-[0_0_15px_rgba(16,185,129,0.4)] ring-1 ring-emerald-500/50" 
                : "bg-white/5 border border-emerald-500/30"
            }`}>
              <div>
                <div className="flex items-center gap-1.5">
                  <span className={`px-1.5 py-0.5 rounded text-[9px] font-bold border transition-colors ${
                    isResetActive ? "bg-emerald-500 text-black border-emerald-400 font-extrabold" : "bg-emerald-500/20 text-emerald-400 border-emerald-500/30"
                  }`}>BTN0 · R18</span>
                  <span className="text-emerald-300 font-semibold text-[10px]">Hardware Reset</span>
                </div>
                <div className="text-[8.5px] text-white/40 mt-0.5">Physical reset: Restores nominal flight</div>
              </div>
              {isResetActive ? (
                <span className="text-[9px] text-emerald-300 font-bold flex items-center gap-1 animate-pulse">
                  <span className="w-1.5 h-1.5 rounded-full bg-emerald-400 animate-ping"></span>
                  RESETTING
                </span>
              ) : (
                <span className="text-[9px] text-emerald-400 font-bold">RESET</span>
              )}
            </div>
          </div>

          {/* On-Board LEDs status */}
          <div className="mt-2.5 pt-2 border-t border-white/10">
            <div className="text-[9px] uppercase tracking-wider text-white/40 font-mono mb-1">Zybo Board LEDs:</div>
            <div className="grid grid-cols-4 gap-1 text-center font-mono text-[9px]">
              <div className={`p-1 rounded border transition-all duration-300 ${
                !isDedActive ? "bg-green-500/20 border-green-500/50 shadow-[0_0_8px_rgba(34,197,94,0.3)] text-green-300" : "bg-white/5 border-white/10 text-white/30"
              }`}>
                <div className="font-bold flex items-center justify-center gap-0.5">
                  {!isDedActive && <span className="w-1.5 h-1.5 rounded-full bg-green-400 animate-pulse"></span>}
                  LD0
                </div>
                <div className="text-[8px] truncate">{!isDedActive ? "Heartbeat" : "OFF"}</div>
              </div>

              <div className={`p-1 rounded border transition-all duration-300 ${
                isSecActive ? "bg-orange-500/30 border-orange-500 shadow-[0_0_12px_rgba(249,115,22,0.6)] text-orange-300" : "bg-white/5 border-white/10 text-orange-400/50"
              }`}>
                <div className="font-bold flex items-center justify-center gap-0.5">
                  {isSecActive && <span className="w-1.5 h-1.5 rounded-full bg-orange-400 animate-ping"></span>}
                  LD1
                </div>
                <div className="text-[8px] truncate">{isSecActive ? "ACTIVE" : "SEC Fix"}</div>
              </div>

              <div className={`p-1 rounded border transition-all duration-300 ${
                isDedActive ? "bg-red-500/30 border-red-500 shadow-[0_0_12px_rgba(239,68,68,0.6)] text-red-300" : "bg-white/5 border-white/10 text-red-400/50"
              }`}>
                <div className="font-bold flex items-center justify-center gap-0.5">
                  {isDedActive && <span className="w-1.5 h-1.5 rounded-full bg-red-400 animate-pulse"></span>}
                  LD2
                </div>
                <div className="text-[8px] truncate">{isDedActive ? "TRAPPED" : "DED Trap"}</div>
              </div>

              <div className={`p-1 rounded border transition-all duration-300 ${
                isTmrActive ? "bg-blue-500/30 border-blue-500 shadow-[0_0_12px_rgba(59,130,246,0.6)] text-blue-300" : "bg-white/5 border-white/10 text-blue-400/50"
              }`}>
                <div className="font-bold flex items-center justify-center gap-0.5">
                  {isTmrActive && <span className="w-1.5 h-1.5 rounded-full bg-blue-400 animate-ping"></span>}
                  LD3
                </div>
                <div className="text-[8px] truncate">{isTmrActive ? "MASKED" : "TMR Mask"}</div>
              </div>
            </div>
          </div>
        </div>
      ) : (
        /* Fault Injection Panel for Software Mode */
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
      )}
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
  const scrollContainerRef = useRef<HTMLDivElement>(null);

  useEffect(() => {
    if (scrollContainerRef.current) {
      scrollContainerRef.current.scrollTop = scrollContainerRef.current.scrollHeight;
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
          className="absolute right-6 top-20 bottom-6 w-96 bg-black/95 backdrop-blur-3xl border border-white/10 rounded-2xl shadow-2xl z-40 flex flex-col pointer-events-auto overflow-hidden"
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
          
          <div ref={scrollContainerRef} className="flex-1 overflow-y-auto p-4 font-mono text-[11px] leading-relaxed no-scrollbar bg-[#050505]">
            {uartLogs.length === 0 ? (
              <div className="text-white/30 h-full flex items-center justify-center italic">No UART activity yet...</div>
            ) : (
              uartLogs.map((log, i) => {
                const color = log.includes("[DED]") || log.includes("Error") 
                  ? "text-red-400 font-semibold"
                  : log.includes("[SEC]")
                  ? "text-orange-400"
                  : log.includes("[TMR]")
                  ? "text-blue-400"
                  : log.includes("[MODE]")
                  ? "text-purple-400"
                  : log.includes("[RESET]")
                  ? "text-emerald-400"
                  : log.includes("[TX]")
                  ? "text-blue-300"
                  : "text-green-400";
                return (
                  <div key={i} className={`mb-1 ${color}`}>
                    {log}
                  </div>
                );
              })
            )}
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
    dashboardType,
  } = useDashboard();

  const toolbarRef = useRef<HTMLDivElement>(null);
  const isHardware = dashboardType === "hardware";

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
      <div className="bg-black/60 backdrop-blur-xl border border-white/10 rounded-full p-2 flex items-center gap-2 pointer-events-auto shadow-2xl">
        <button
          onClick={() => resetDemo()}
          className="p-3 hover:bg-white/10 rounded-full text-white/70 hover:text-white transition-colors flex items-center gap-2 px-4"
          title="Reset Flight & CPU (Syncs with Zybo BTN0)"
        >
          <RefreshCcw className="w-4 h-4 text-emerald-400" />
          <span className="font-mono text-xs font-bold uppercase tracking-wider text-emerald-400">
            {isHardware ? "Reset Flight (BTN0 Sync)" : "Reset Demo"}
          </span>
        </button>

        {!isHardware && (
          <>
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
          </>
        )}

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
  const [isModalDismissed, setIsModalDismissed] = useState(false);
  
  // No longer forcing software on mount, rely on context defaults.

  return (
      <div
        className="fixed inset-0 w-screen h-screen max-h-screen overflow-hidden bg-grid-pattern text-white font-sans select-none"
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
              onClick={() => { setDashboardType("software"); setIsModalDismissed(false); }}
              className={`px-4 py-1.5 rounded-full text-xs font-bold uppercase tracking-widest transition-colors ${
                dashboardType === "software" ? "bg-orange-500 text-white" : "text-white/60 hover:text-white"
              }`}
            >
              Software
            </button>
            <button
              onClick={() => { setDashboardType("hardware"); setIsModalDismissed(false); }}
              className={`px-4 py-1.5 rounded-full text-xs font-bold uppercase tracking-widest transition-colors ${
                dashboardType === "hardware" ? "bg-green-500 text-white" : "text-white/60 hover:text-white"
              }`}
            >
              Hardware
            </button>
          </div>

          {dashboardType === "hardware" && !dataSourceInfo.isConnected && isModalDismissed && (
            <button
              onClick={connectFPGA}
              className="pointer-events-auto px-4 py-1.5 rounded-full bg-green-600/30 hover:bg-green-600/50 border border-green-500/50 text-[11px] font-mono text-green-300 font-bold uppercase tracking-wider flex items-center gap-1.5 shadow-lg transition-colors animate-pulse"
            >
              <Zap className="w-3.5 h-3.5 fill-green-400 text-green-400" />
              Connect to FPGA
            </button>
          )}
        </div>

        <Navigation
          extraLeft={
            <button 
              onClick={() => setIsTerminalOpen(!isTerminalOpen)}
              className={`backdrop-blur-xl border px-3.5 py-2 rounded-full transition-all pointer-events-auto shadow-lg flex items-center gap-2 text-xs font-mono font-bold uppercase tracking-wider ${
                isTerminalOpen 
                  ? "bg-green-500/20 border-green-500/50 text-green-300 ring-1 ring-green-500/40" 
                  : "bg-black/60 border-white/10 text-white/70 hover:bg-white/10 hover:text-green-400"
              }`}
              title={isTerminalOpen ? "Close Serial Console" : "Open Serial Console"}
            >
              <TerminalSquare className="w-4 h-4 text-green-400" />
              <span>Console</span>
            </button>
          }
        />

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
        {dashboardType === "hardware" && !dataSourceInfo.isConnected && !isModalDismissed && (
          <div className="absolute inset-0 z-50 flex items-center justify-center bg-black/80 backdrop-blur-sm">
            <div className="bg-black/90 p-8 rounded-2xl border border-white/10 text-center max-w-md shadow-2xl relative">
              <button
                onClick={() => setIsModalDismissed(true)}
                className="absolute top-4 right-4 text-white/50 hover:text-white transition-colors p-1"
                title="Dismiss and view board layout"
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
