"use client";

import React, { createContext, useContext, useState, useEffect } from "react";

export type FaultType = "SEC" | "DED" | "ALU" | "MODE";

export interface ToastMessage {
  id: number;
  message: string;
  type: "info" | "warning" | "error" | "success";
}

export type LiveMonitorState = 
  | { type: "IDLE"; value: string }
  | { type: "SEC_INJECTED"; register: string; bit: string; badValue: string }
  | { type: "SEC_CORRECTED"; register: string; goodValue: string }
  | { type: "DED_DETECTED"; register: string }
  | { type: "ALU_INJECTED"; aluId: number; badValue: string; goodValue: string }
  | { type: "ALU_RECOVERED"; goodValue: string };

export interface FaultStats {
  sec: number;
  ded: number;
  alu: number;
  total: number;
}

export interface FaultHistoryPoint {
  time: string;
  sec: number;
  ded: number;
  alu: number;
}

interface DashboardState {
  // System Status
  processorState: "Running" | "Degraded" | "Recovering" | "Halted";
  clock: string;
  currentMode: "Simplex" | "Triple Modular Redundancy";
  
  // 3D Visual State
  isHovering: boolean;
  setIsHovering: (v: boolean) => void;
  isRotating: boolean;
  setIsRotating: (v: boolean) => void;
  highlightedModules: string[];
  setHighlightedModules: (modules: string[]) => void;
  toggleHighlightedModule: (module: string) => void;
  
  // The actual module that is glowing based on the fault
  activeFaultModule: string | null;
  cameraResetTrigger: number;
  triggerCameraReset: () => void;
  
  // Explosion state
  explosionFactor: number;
  setExplosionFactor: (v: number) => void;
  
  // Live Monitor State
  liveMonitor: LiveMonitorState;
  
  // Toasts
  toasts: ToastMessage[];
  removeToast: (id: number) => void;

  // Analytics
  faultStats: FaultStats;
  faultHistory: FaultHistoryPoint[];

  // Actions
  injectFault: (type: FaultType, reg?: string, bit?: string, alu?: string) => void;
  resetDemo: () => void;
  isDemoActive: boolean;
  setIsDemoActive: (v: boolean) => void;
}

let nextToastId = 0;

const DashboardContext = createContext<DashboardState | undefined>(undefined);

export function DashboardProvider({ children }: { children: React.ReactNode }) {
  const [processorState, setProcessorState] = useState<"Running" | "Degraded" | "Recovering" | "Halted">("Running");
  const [currentMode, setCurrentMode] = useState<"Simplex" | "Triple Modular Redundancy">("Simplex");
  
  // 3D Visual State
  const [isHovering, setIsHovering] = useState(true);
  const [isRotating, setIsRotating] = useState(true);
  const [highlightedModules, setHighlightedModules] = useState<string[]>([]);
  
  // Fault State
  const [activeFaultModule, setActiveFaultModule] = useState<string | null>(null);
  const [liveMonitor, setLiveMonitor] = useState<LiveMonitorState>({ type: "IDLE", value: "0x00000000" });
  
  const [cameraResetTrigger, setCameraResetTrigger] = useState(0);
  const [explosionFactor, setExplosionFactor] = useState(0);
  
  const [toasts, setToasts] = useState<ToastMessage[]>([]);
  const [isDemoActive, setIsDemoActive] = useState(true);

  // Analytics State
  const [faultStats, setFaultStats] = useState<FaultStats>({ sec: 0, ded: 0, alu: 0, total: 0 });
  const [faultHistory, setFaultHistory] = useState<FaultHistoryPoint[]>([]);

  // We need to keep track of persistent faults (like DED)
  const [hasPersistentFault, setHasPersistentFault] = useState(false);

  useEffect(() => {
    const interval = setInterval(() => {
      setFaultHistory(prev => {
        const now = new Date();
        const timeStr = `${now.getHours().toString().padStart(2, '0')}:${now.getMinutes().toString().padStart(2, '0')}:${now.getSeconds().toString().padStart(2, '0')}`;
        return [...prev, { time: timeStr, ...faultStats }].slice(-20);
      });
    }, 3000);
    return () => clearInterval(interval);
  }, [faultStats]);

  const addToast = (message: string, type: ToastMessage["type"]) => {
    const id = nextToastId++;
    setToasts((prev) => [...prev, { id, message, type }].slice(-5));
    setTimeout(() => removeToast(id), 4000);
  };

  const removeToast = (id: number) => {
    setToasts((prev) => prev.filter((t) => t.id !== id));
  };

  const triggerCameraReset = () => {
    setCameraResetTrigger(prev => prev + 1);
  };

  const toggleHighlightedModule = (module: string) => {
    setHighlightedModules(prev => 
      prev.includes(module) ? prev.filter(m => m !== module) : [...prev, module]
    );
  };

  const resetDemo = () => {
    setProcessorState("Running");
    setCurrentMode("Simplex");
    setActiveFaultModule(null);
    setHighlightedModules([]);
    setLiveMonitor({ type: "IDLE", value: "0x00000000" });
    setHasPersistentFault(false);
    setExplosionFactor(0);
    setFaultStats({ sec: 0, ded: 0, alu: 0, total: 0 });
    setFaultHistory([]);
    triggerCameraReset();
    addToast("System reset.", "info");
  };

  const injectFault = (type: FaultType, reg?: string, bit?: string, alu?: string) => {
    // If there's an unrecoverable fault, block new faults until reset
    if (hasPersistentFault && type !== "MODE") return;

    if (type === "SEC") {
      setFaultStats(s => ({ ...s, sec: s.sec + 1, total: s.total + 1 }));
      const targetReg = reg || "x5";
      const targetBit = bit || "7";
      setActiveFaultModule("CPU_SEC");
      setLiveMonitor({ type: "SEC_INJECTED", register: targetReg, bit: targetBit, badValue: "0xDEADBEEF" });
      
      // Simulate correction after 1 frame/tick (we'll use 800ms for visual effect)
      setTimeout(() => {
        if (!hasPersistentFault) {
          setLiveMonitor({ type: "SEC_CORRECTED", register: targetReg, goodValue: "0x0000000F" });
          addToast("ECC corrected single-bit fault", "warning");
          
          setTimeout(() => {
            setLiveMonitor({ type: "IDLE", value: "0x0000000F" });
            setActiveFaultModule(null);
          }, 2000);
        }
      }, 800);
      
    } else if (type === "DED") {
      setFaultStats(s => ({ ...s, ded: s.ded + 1, total: s.total + 1 }));
      const targetReg = reg || "x9";
      setProcessorState("Degraded");
      setHasPersistentFault(true);
      setActiveFaultModule("CPU_DED");
      
      setLiveMonitor({ type: "DED_DETECTED", register: targetReg });
      addToast("Double-bit error detected — data unreliable", "error");
      // Note: This does NOT auto-recover. It persists until resetDemo.
      
    } else if (type === "ALU") {
      setFaultStats(s => ({ ...s, alu: s.alu + 1, total: s.total + 1 }));
      const targetAlu = parseInt(alu || "0", 10);
      setActiveFaultModule(`ALU_${targetAlu}`);
      setProcessorState("Recovering");
      
      setLiveMonitor({ type: "ALU_INJECTED", aluId: targetAlu, badValue: "0x00007FFF", goodValue: "0x0000000F" });
      
      setTimeout(() => {
        if (!hasPersistentFault) {
          setLiveMonitor({ type: "ALU_RECOVERED", goodValue: "0x0000000F" });
          setActiveFaultModule("TMR_RECOVER");
          setProcessorState("Running"); // fallback to Running
          
          addToast("TMR masked ALU failure", "success");
          
          setTimeout(() => {
            setProcessorState("Running");
            setLiveMonitor({ type: "IDLE", value: "0x0000000F" });
            setActiveFaultModule(null);
          }, 2000);
        }
      }, 1500);
      
    } else if (type === "MODE") {
      setCurrentMode((prev) => {
        const newMode = prev === "Simplex" ? "Triple Modular Redundancy" : "Simplex";
        addToast(`Mode switched to ${newMode}`, "info");
        return newMode;
      });
    }
  };

  useEffect(() => {
    if (!isDemoActive || hasPersistentFault) return;
    const interval = setInterval(() => {
      // Don't inject if already recovering
      if (processorState !== "Running") return;
      
      if (Math.random() > 0.6) {
        // Bias towards SEC and ALU so it doesn't instantly halt on DED
        const faults: FaultType[] = ["SEC", "SEC", "ALU", "ALU", "DED"];
        const randomFault = faults[Math.floor(Math.random() * faults.length)];
        const randomReg = `x${Math.floor(Math.random() * 15) + 1}`;
        const randomAlu = `${Math.floor(Math.random() * 3)}`;
        injectFault(randomFault, randomReg, "0", randomAlu);
      }
    }, 6000);
    return () => clearInterval(interval);
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [isDemoActive, hasPersistentFault, processorState]);

  // WebSocket Integration for Live Telemetry
  useEffect(() => {
    const ws = new WebSocket("ws://localhost:8080");

    ws.onopen = () => {
      console.log("Connected to Serial Bridge WebSocket");
      setIsDemoActive(false); // Disable internal mock loop
      addToast("Connected to live telemetry bridge", "success");
    };

    ws.onmessage = (event) => {
      try {
        const data = JSON.parse(event.data);

        if (data.type === "SEC") {
           setFaultStats(s => ({ ...s, sec: s.sec + 1, total: s.total + 1 }));
           setActiveFaultModule("CPU_SEC");
           setLiveMonitor({ type: "SEC_INJECTED", register: data.reg, bit: data.bit || "0", badValue: data.badValue || "0xDEADBEEF" });
        } else if (data.type === "SEC_CORRECTED") {
           setLiveMonitor({ type: "SEC_CORRECTED", register: data.reg, goodValue: data.goodValue });
           setTimeout(() => {
             setLiveMonitor({ type: "IDLE", value: "0x0000000F" });
             setActiveFaultModule(null);
           }, 2000);
        } else if (data.type === "ALU") {
           setFaultStats(s => ({ ...s, alu: s.alu + 1, total: s.total + 1 }));
           setActiveFaultModule(`ALU_${data.aluId}`);
           setProcessorState("Recovering");
           setLiveMonitor({ type: "ALU_INJECTED", aluId: parseInt(data.aluId, 10), badValue: data.badValue, goodValue: "0x0000000F" });
        } else if (data.type === "ALU_RECOVERED") {
           setLiveMonitor({ type: "ALU_RECOVERED", goodValue: data.goodValue });
           setActiveFaultModule("TMR_RECOVER");
           setProcessorState("Running");
           setTimeout(() => {
             setLiveMonitor({ type: "IDLE", value: "0x0000000F" });
             setActiveFaultModule(null);
           }, 2000);
        } else if (data.type === "DED") {
           setFaultStats(s => ({ ...s, ded: s.ded + 1, total: s.total + 1 }));
           setProcessorState("Degraded");
           setHasPersistentFault(true);
           setActiveFaultModule("CPU_DED");
           setLiveMonitor({ type: "DED_DETECTED", register: data.reg });
        }
      } catch (e) {
        console.error("Failed to parse websocket message", e);
      }
    };

    ws.onclose = () => {
      console.log("WebSocket disconnected");
      addToast("Disconnected from telemetry bridge", "error");
    };

    return () => ws.close();
  }, []);

  return (
    <DashboardContext.Provider
      value={{
        processorState,
        clock: "100 MHz",
        currentMode,
        isHovering, setIsHovering,
        isRotating, setIsRotating,
        highlightedModules, setHighlightedModules, toggleHighlightedModule,
        activeFaultModule,
        cameraResetTrigger, triggerCameraReset,
        explosionFactor, setExplosionFactor,
        liveMonitor,
        toasts, removeToast,
        faultStats, faultHistory,
        injectFault, resetDemo, isDemoActive, setIsDemoActive,
      }}
    >
      {children}
    </DashboardContext.Provider>
  );
}

export function useDashboard() {
  const context = useContext(DashboardContext);
  if (context === undefined) {
    throw new Error("useDashboard must be used within a DashboardProvider");
  }
  return context;
}
