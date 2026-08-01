"use client";

import React, { createContext, useContext, useState, useEffect } from "react";

export type FaultType = "SEC" | "DED" | "ALU" | "MODE";

export interface ToastMessage {
  id: number;
  message: string;
  type: "info" | "warning" | "error" | "success";
}

export interface Register {
  name: string;
  value: string;
  status: "Healthy" | "Locked" | "Corrected" | "Double Error";
}

export interface ALUState {
  id: number;
  result: number;
  status: "Healthy" | "Faulty";
}

interface DashboardState {
  // System Status
  processorState: "Running" | "Halted";
  clock: string;
  currentMode: "Simplex" | "Triple Modular Redundancy";
  
  // 3D Visual State
  isExploded: boolean;
  setIsExploded: (v: boolean) => void;
  isHovering: boolean;
  setIsHovering: (v: boolean) => void;
  isRotating: boolean;
  setIsRotating: (v: boolean) => void;
  highlightedModules: string[];
  setHighlightedModules: (modules: string[]) => void;
  toggleHighlightedModule: (module: string) => void;
  activeFaultModule: string | null;
  cameraResetTrigger: number;
  triggerCameraReset: () => void;
  
  // Toasts
  toasts: ToastMessage[];
  removeToast: (id: number) => void;

  // Data
  registers: Register[];
  alus: ALUState[];
  voterOutput: number | "Mismatch";
  secCount: number;
  dedCount: number;
  currentSyndrome: string;
  
  // Actions
  injectFault: (type: FaultType, reg?: string, bit?: string, alu?: string) => void;
  resetDemo: () => void;
  isDemoActive: boolean;
  setIsDemoActive: (v: boolean) => void;
}

const defaultRegisters: Register[] = Array.from({ length: 16 }).map((_, i) => ({
  name: `x${i}`,
  value: "00000000",
  status: i === 0 ? "Locked" : "Healthy",
}));

const DashboardContext = createContext<DashboardState | undefined>(undefined);

export function DashboardProvider({ children }: { children: React.ReactNode }) {
  const [processorState, setProcessorState] = useState<"Running" | "Halted">("Running");
  const [currentMode, setCurrentMode] = useState<"Simplex" | "Triple Modular Redundancy">("Simplex");
  
  // 3D Visual State
  const [isExploded, setIsExploded] = useState(false);
  const [isHovering, setIsHovering] = useState(true);
  const [isRotating, setIsRotating] = useState(true);
  const [highlightedModules, setHighlightedModules] = useState<string[]>([]);
  const [activeFaultModule, setActiveFaultModule] = useState<string | null>(null);
  const [cameraResetTrigger, setCameraResetTrigger] = useState(0);
  
  const [toasts, setToasts] = useState<ToastMessage[]>([]);
  
  const [registers, setRegisters] = useState<Register[]>(defaultRegisters);
  const [alus, setAlus] = useState<ALUState[]>([
    { id: 0, result: 15, status: "Healthy" },
    { id: 1, result: 15, status: "Healthy" },
    { id: 2, result: 15, status: "Healthy" },
  ]);
  const [voterOutput, setVoterOutput] = useState<number | "Mismatch">(15);
  
  const [secCount, setSecCount] = useState(0);
  const [dedCount, setDedCount] = useState(0);
  const [currentSyndrome, setCurrentSyndrome] = useState("0000000");

  const [isDemoActive, setIsDemoActive] = useState(true);

  const addToast = (message: string, type: ToastMessage["type"]) => {
    const id = Date.now() + Math.random();
    setToasts((prev) => [...prev, { id, message, type }].slice(-5)); // keep last 5
    // auto remove after 4s
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
    setRegisters(defaultRegisters);
    setAlus([
      { id: 0, result: 15, status: "Healthy" },
      { id: 1, result: 15, status: "Healthy" },
      { id: 2, result: 15, status: "Healthy" },
    ]);
    setVoterOutput(15);
    setSecCount(0);
    setDedCount(0);
    setCurrentSyndrome("0000000");
    setCurrentMode("Simplex");
    setActiveFaultModule(null);
    setHighlightedModules([]);
    setIsExploded(false);
    triggerCameraReset();
    addToast("Demo state reset.", "info");
  };

  const injectFault = (type: FaultType, reg?: string, bit?: string, alu?: string) => {
    if (type === "SEC") {
      const targetReg = reg || "x5";
      const targetBit = bit || "7";
      setRegisters((prev) =>
        prev.map((r) => (r.name === targetReg ? { ...r, status: "Corrected", value: "DEADBEEF" } : r))
      );
      setSecCount((s) => s + 1);
      setCurrentSyndrome("0001000");
      setActiveFaultModule("CPU_SEC"); // Special module ID for sec
      addToast(`ECC corrected single-bit fault in ${targetReg}`, "warning");
      
      setTimeout(() => {
        setRegisters((prev) =>
          prev.map((r) => (r.name === targetReg ? { ...r, status: "Healthy" } : r))
        );
        setActiveFaultModule(null);
      }, 2500);
    } else if (type === "DED") {
      const targetReg = reg || "x9";
      setRegisters((prev) =>
        prev.map((r) => (r.name === targetReg ? { ...r, status: "Double Error", value: "AABBCCDD" } : r))
      );
      setDedCount((d) => d + 1);
      setCurrentSyndrome("0110000");
      setActiveFaultModule("CPU_DED");
      addToast(`Double-bit error detected in ${targetReg}!`, "error");
      
      setTimeout(() => {
        setRegisters((prev) =>
          prev.map((r) => (r.name === targetReg ? { ...r, status: "Healthy" } : r))
        );
        setActiveFaultModule(null);
      }, 3000);
    } else if (type === "ALU") {
      const targetAlu = parseInt(alu || "0", 10);
      setAlus((prev) =>
        prev.map((a) => (a.id === targetAlu ? { ...a, result: 32783, status: "Faulty" } : a))
      );
      setVoterOutput("Mismatch");
      setActiveFaultModule(`ALU_${targetAlu}`);
      addToast(`ALU${targetAlu} Failure Detected!`, "error");
      
      setTimeout(() => {
        setAlus((prev) => prev.map((a) => ({ ...a, result: 15, status: "Healthy" })));
        setVoterOutput(15);
        setActiveFaultModule("TMR_RECOVER");
        addToast("TMR masked ALU failure", "success");
        setTimeout(() => setActiveFaultModule(null), 2000);
      }, 3000);
    } else if (type === "MODE") {
      setCurrentMode((prev) => {
        const newMode = prev === "Simplex" ? "Triple Modular Redundancy" : "Simplex";
        addToast(`Mode switched to ${newMode}`, "info");
        return newMode;
      });
    }
  };

  useEffect(() => {
    if (!isDemoActive) return;
    const interval = setInterval(() => {
      if (Math.random() > 0.6) {
        const faults: FaultType[] = ["SEC", "DED", "ALU", "MODE"];
        const randomFault = faults[Math.floor(Math.random() * faults.length)];
        const randomReg = `x${Math.floor(Math.random() * 15) + 1}`;
        const randomBit = `${Math.floor(Math.random() * 32)}`;
        const randomAlu = `${Math.floor(Math.random() * 3)}`;
        injectFault(randomFault, randomReg, randomBit, randomAlu);
      }
    }, 6000);
    return () => clearInterval(interval);
  }, [isDemoActive]);

  return (
    <DashboardContext.Provider
      value={{
        processorState,
        clock: "100 MHz",
        currentMode,
        isExploded, setIsExploded,
        isHovering, setIsHovering,
        isRotating, setIsRotating,
        highlightedModules, setHighlightedModules, toggleHighlightedModule,
        activeFaultModule,
        cameraResetTrigger, triggerCameraReset,
        toasts, removeToast,
        registers, alus, voterOutput, secCount, dedCount, currentSyndrome,
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
