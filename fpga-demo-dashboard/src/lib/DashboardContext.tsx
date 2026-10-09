"use client";

import React, { createContext, useContext, useState, useEffect, useRef } from "react";
import { DataSource, FaultEvent } from "./DataProvider";
import { SimulatedDataSource } from "./SimulatedDataSource";
import { UARTDataSource, REALISTIC_ALU_VALUES } from "./UARTDataSource";

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

export interface DataSourceInfo {
  isConnected: boolean;
  sourceName: string;
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
  
  // Fault State
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
  resetDemo: (initialMode?: "Simplex" | "Triple Modular Redundancy" | unknown, sendToHardware?: boolean) => void;
  isDemoActive: boolean;
  setIsDemoActive: (v: boolean) => void;
  
  // Hardware Data Architecture
  dataSourceInfo: DataSourceInfo;
  connectFPGA: () => Promise<void>;
  disconnectFPGA: () => Promise<void>;
  
  // Expose an event counter so the UI (like SignalPipeline) can trigger burst animations
  eventCounter: number;
  
  // Dashboard Type (Software vs Hardware)
  dashboardType: "software" | "hardware";
  setDashboardType: (type: "software" | "hardware") => void;

  // UART Terminal
  uartLogs: string[];
  isTerminalOpen: boolean;
  setIsTerminalOpen: (v: boolean) => void;
  clearTerminal: () => void;

  // Active Protection Event for Hardware Button Highlights
  activeProtectionEvent: "SEC" | "DED" | "TMR" | "MODE" | "RESET" | null;
}

let nextToastId = 0;

const DashboardContext = createContext<DashboardState | undefined>(undefined);

export function DashboardProvider({ children }: { children: React.ReactNode }) {
  const [processorState, setProcessorState] = useState<"Running" | "Degraded" | "Recovering" | "Halted">("Running");
  const [currentMode, setCurrentMode] = useState<"Simplex" | "Triple Modular Redundancy">("Simplex");
  const [dashboardType, setDashboardType] = useState<"software" | "hardware">("software");
  
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

  // Persistent Fault (like DED)
  const [hasPersistentFault, setHasPersistentFault] = useState(false);
  const hasPersistentFaultRef = useRef(false);
  useEffect(() => {
     hasPersistentFaultRef.current = hasPersistentFault;
  }, [hasPersistentFault]);

  // Data Source Architecture
  const simulatedSource = useRef(new SimulatedDataSource());
  const uartSource = useRef(new UARTDataSource());
  const [dataSourceInfo, setDataSourceInfo] = useState<DataSourceInfo>({ isConnected: false, sourceName: "Simulated" });
  const [eventCounter, setEventCounter] = useState(0);

  // UART Terminal State
  const [uartLogs, setUartLogs] = useState<string[]>([]);
  const [isTerminalOpen, setIsTerminalOpen] = useState(false);
  const clearTerminal = () => setUartLogs([]);

  // Active Protection Event State (for button highlight sync)
  const [activeProtectionEvent, setActiveProtectionEvent] = useState<"SEC" | "DED" | "TMR" | "MODE" | "RESET" | null>(null);
  const aluSimIdx = useRef(0);

  // Helper to format hex values
  const toHex = (val?: number) => val !== undefined ? "0x" + val.toString(16).toUpperCase().padStart(8, '0') : "0x00000000";

  // The event handler for incoming FaultEvents from the active DataSource
  const handleFaultEvent = (event: FaultEvent) => {
    // If there's an unrecoverable fault, block new faults until reset
    if (hasPersistentFaultRef.current && event.type !== 'MODE_CHANGE' && event.type !== 'RESET') return;
    
    // Trigger animation in UI
    setEventCounter(c => c + 1);

    if (event.type === 'SEC') {
      setActiveProtectionEvent("SEC");
      setTimeout(() => setActiveProtectionEvent(null), 2500);
      setFaultStats(s => ({ ...s, sec: s.sec + 1, total: s.total + 1 }));
      const targetReg = `x${event.register || 1}`;
      const targetBit = `${event.bit ?? 0}`;
      setActiveFaultModule("CPU_SEC");

      const goodSec = (event.correctedValue && event.correctedValue !== 0) ? toHex(event.correctedValue) : "0x0000A5A5";
      const badSec = (event.rawValue && event.rawValue !== 0 && event.rawValue !== 0xDEADBEEF) ? toHex(event.rawValue) : "0x0000A5A4";

      setLiveMonitor({ type: "SEC_INJECTED", register: targetReg, bit: targetBit, badValue: badSec });
      
      // Auto-recover after short visual delay
      setTimeout(() => {
        if (!hasPersistentFaultRef.current) {
          setLiveMonitor({ type: "SEC_CORRECTED", register: targetReg, goodValue: goodSec });
          addToast("ECC corrected single-bit fault", "warning");
          setTimeout(() => {
            setLiveMonitor({ type: "IDLE", value: goodSec });
            setActiveFaultModule(null);
          }, 2000);
        }
      }, 800);
      
    } else if (event.type === 'DED') {
      setActiveProtectionEvent("DED");
      setFaultStats(s => ({ ...s, ded: s.ded + 1, total: s.total + 1 }));
      const targetReg = `x${event.register || 9}`;
      setProcessorState("Degraded");
      setHasPersistentFault(true);
      setActiveFaultModule("CPU_DED");
      setLiveMonitor({ type: "DED_DETECTED", register: targetReg });
      addToast("Double-bit error detected — data unreliable", "error");
      
    } else if (event.type === 'TMR_MISMATCH') {
      setActiveProtectionEvent("TMR");
      setTimeout(() => setActiveProtectionEvent(null), 2500);
      setFaultStats(s => ({ ...s, alu: s.alu + 1, total: s.total + 1 }));
      const targetAlu = event.aluInstance || 0;
      setActiveFaultModule(`ALU_${targetAlu}`);
      setProcessorState("Recovering");

      // Use realistic flight calculations from the pool (5-20 values) instead of 0x00000000
      const goodNum = (event.correctedValue && event.correctedValue !== 0)
        ? event.correctedValue
        : REALISTIC_ALU_VALUES[aluSimIdx.current % REALISTIC_ALU_VALUES.length];
      aluSimIdx.current = (aluSimIdx.current + 1) % REALISTIC_ALU_VALUES.length;

      const badNum = (event.rawValue && event.rawValue !== 0 && event.rawValue !== 0xDEADBEEF)
        ? event.rawValue
        : (goodNum ^ (1 << (event.bit || 0)));

      const goodVal = toHex(goodNum);
      const badVal = toHex(badNum);

      setLiveMonitor({ type: "ALU_INJECTED", aluId: targetAlu, badValue: badVal, goodValue: goodVal });
      
      setTimeout(() => {
        if (!hasPersistentFaultRef.current) {
          setLiveMonitor({ type: "ALU_RECOVERED", goodValue: goodVal });
          setActiveFaultModule("TMR_RECOVER");
          setProcessorState("Running");
          addToast("TMR masked ALU failure", "success");
          setTimeout(() => {
            setProcessorState("Running");
            setLiveMonitor({ type: "IDLE", value: goodVal });
            setActiveFaultModule(null);
          }, 2000);
        }
      }, 1500);
      
    } else if (event.type === 'MODE_CHANGE') {
      setActiveProtectionEvent("MODE");
      setTimeout(() => setActiveProtectionEvent(null), 2000);
      setCurrentMode((prev) => {
        const newMode = (event.register !== undefined)
          ? (event.register === 1 ? "Triple Modular Redundancy" : "Simplex")
          : (prev === "Simplex" ? "Triple Modular Redundancy" : "Simplex");
        addToast(`Mode switched to ${newMode}`, "info");
        return newMode;
      });
    } else if (event.type === 'RESET') {
      setActiveProtectionEvent("RESET");
      setTimeout(() => setActiveProtectionEvent(null), 2000);
      resetDemo(event.register === 1 ? "Triple Modular Redundancy" : "Simplex", false);
    }
  };

  useEffect(() => {
    // Bind the handler to both sources
    simulatedSource.current.onEvent(handleFaultEvent);
    uartSource.current.onEvent(handleFaultEvent);
    uartSource.current.onLog((msg) => {
      setUartLogs(prev => [...prev, msg].slice(-100)); // Keep last 100 logs
    });
    uartSource.current.onConnectionChange((connected) => {
      if (!connected) {
        setDataSourceInfo({ isConnected: false, sourceName: simulatedSource.current.sourceName });
      }
    });
    
    return () => {
      simulatedSource.current.stop();
      uartSource.current.stop();
    };
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  useEffect(() => {
    if (dashboardType === "software" && isDemoActive && !dataSourceInfo.isConnected) {
      simulatedSource.current.start();
    } else {
      simulatedSource.current.stop();
    }
  }, [isDemoActive, dataSourceInfo.isConnected, dashboardType]);

  const connectFPGA = async () => {
    try {
      await uartSource.current.start();
      setDataSourceInfo({ isConnected: true, sourceName: uartSource.current.sourceName });
      addToast("Connected to live FPGA hardware", "success");
    } catch (e: any) {
      addToast(e.message || "Failed to connect to FPGA", "error");
      setDataSourceInfo({ isConnected: false, sourceName: simulatedSource.current.sourceName });
    }
  };

  const changeDashboardType = async (type: "software" | "hardware") => {
    setDashboardType(type);
    if (type === "hardware" && !dataSourceInfo.isConnected) {
      if (typeof navigator !== "undefined" && "serial" in navigator) {
        try {
          const ports = await (navigator as any).serial.getPorts();
          if (ports && ports.length > 0) {
            await connectFPGA();
          }
        } catch (e) {
          console.warn("Auto-connect check error:", e);
        }
      }
    }
  };

  const disconnectFPGA = async () => {
    await uartSource.current.stop();
    setDataSourceInfo({ isConnected: false, sourceName: simulatedSource.current.sourceName });
    addToast("Disconnected from hardware. Using simulated data.", "info");
  };

  // Keep history interval
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

  const resetDemo = (
    initialMode?: "Simplex" | "Triple Modular Redundancy" | unknown,
    sendToHardware: boolean = true
  ) => {
    setProcessorState("Running");
    const validMode = (initialMode === "Triple Modular Redundancy" || initialMode === "Simplex")
      ? (initialMode as "Simplex" | "Triple Modular Redundancy")
      : "Simplex";
    setCurrentMode(validMode);
    setActiveFaultModule(null);
    setActiveProtectionEvent("RESET");
    setTimeout(() => setActiveProtectionEvent(null), 1500);
    setHighlightedModules([]);
    setLiveMonitor({ type: "IDLE", value: "0x00000000" });
    setHasPersistentFault(false);
    setExplosionFactor(0);
    setFaultStats({ sec: 0, ded: 0, alu: 0, total: 0 });
    setFaultHistory([]);
    triggerCameraReset();
    addToast("Hardware Reset: Flight computer reset. Nominal flight resumed.", "success");
    if (sendToHardware && dashboardType === "hardware" && dataSourceInfo.isConnected) {
      uartSource.current.sendCommand(0x05, 0, 0, 0);
    }
  };

  // Fault injection handler
  const injectFault = (type: FaultType, reg?: string, bit?: string, alu?: string) => {
    if (dashboardType === "hardware") {
      addToast("Hardware mode active: Fault injection is controlled exclusively via board buttons (BTN1-3)", "warning");
      return;
    }

    let convertedType: FaultEvent['type'] = 'SEC';
    if (type === 'DED') { convertedType = 'DED'; }
    if (type === 'ALU') { convertedType = 'TMR_MISMATCH'; }
    if (type === 'MODE') { convertedType = 'MODE_CHANGE'; }

    const regNum = reg ? parseInt(reg.replace('x', ''), 10) : (type === 'DED' ? 9 : 5);
    const bitNum = bit ? parseInt(bit, 10) : 7;
    const aluNum = alu ? parseInt(alu, 10) : 0;

    // Simulate locally in software mode
    handleFaultEvent({
      type: convertedType,
      register: regNum,
      bit: bitNum,
      aluInstance: aluNum,
      timestamp: Date.now()
    });
  };

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
        injectFault, resetDemo,
        isDemoActive, setIsDemoActive,
        dataSourceInfo, connectFPGA, disconnectFPGA, eventCounter,
        dashboardType, setDashboardType: changeDashboardType,
        uartLogs, isTerminalOpen, setIsTerminalOpen, clearTerminal,
        activeProtectionEvent
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
