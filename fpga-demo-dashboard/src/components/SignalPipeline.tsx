"use client";

import React, { useState, useEffect } from "react";
import { motion, AnimatePresence } from "framer-motion";
import { useDashboard } from "@/lib/DashboardContext";

export default function SignalPipeline() {
  const [isExpanded, setIsExpanded] = useState(true);
  const { dataSourceInfo, connectFPGA, disconnectFPGA, eventCounter } = useDashboard();
  
  const [isFlashing, setIsFlashing] = useState(false);
  const [isBursting, setIsBursting] = useState(false);

  useEffect(() => {
    if (eventCounter > 0) {
      setIsFlashing(true);
      setIsBursting(true);
      const t1 = setTimeout(() => setIsFlashing(false), 300);
      const t2 = setTimeout(() => setIsBursting(false), 1200); // 1.2s burst
      return () => { clearTimeout(t1); clearTimeout(t2); };
    }
  }, [eventCounter]);

  const { isConnected, sourceName } = dataSourceInfo;
  
  const nodeStatusColor = isConnected ? "bg-green-500" : "bg-white/20";
  const borderFlash = isFlashing ? "border-orange-500" : "border-white/10";

  return (
    <div className="absolute bottom-6 right-6 z-50 flex flex-col items-end">
      {/* Animated dots styles */}
      <style dangerouslySetInnerHTML={{__html: `
        @keyframes flowDown {
          0% { transform: translateY(-100%); opacity: 0; }
          20% { opacity: 1; }
          80% { opacity: 1; }
          100% { transform: translateY(300%); opacity: 0; }
        }
        .data-dot {
          width: 4px;
          height: 4px;
          background-color: #f97316;
          border-radius: 50%;
          position: absolute;
          left: 50%;
          margin-left: -2px;
          animation: flowDown 1s linear infinite;
        }
        .dot-delay-1 { animation-delay: 0s; }
        .dot-delay-2 { animation-delay: 0.4s; }
        .dot-delay-3 { animation-delay: 0.8s; }
        
        .burst .data-dot {
          animation-duration: 0.3s;
        }
        .burst .dot-delay-1 { animation-delay: 0s; }
        .burst .dot-delay-2 { animation-delay: 0.1s; }
        .burst .dot-delay-3 { animation-delay: 0.2s; }
      `}} />

      <motion.div 
        layout
        className={`bg-[#0d0d10]/95 backdrop-blur-xl border border-white/10 rounded-lg shadow-2xl overflow-hidden flex flex-col ${isFlashing ? 'shadow-orange-500/20' : ''}`}
        transition={{ duration: 0.3, ease: "easeInOut" }}
      >
        {/* Header */}
        <div 
          className="flex justify-between items-center px-4 py-3 cursor-pointer bg-white/5 hover:bg-white/10 transition-colors"
          onClick={() => setIsExpanded(!isExpanded)}
        >
          <div className="flex items-center gap-2">
            <h2 className="text-xs font-bold text-orange-500 tracking-widest uppercase">
              Signal Pipeline
            </h2>
            {isFlashing && (
              <span className="w-2 h-2 rounded-full bg-orange-500 animate-ping" />
            )}
          </div>
          <svg 
            width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" 
            className={`text-white/50 transition-transform duration-300 ${isExpanded ? 'rotate-180' : ''}`}
          >
            <path strokeLinecap="round" strokeLinejoin="round" d="M19 9l-7 7-7-7" />
          </svg>
        </div>

        <AnimatePresence>
          {isExpanded && (
            <motion.div 
              initial={{ height: 0, opacity: 0 }}
              animate={{ height: "auto", opacity: 1 }}
              exit={{ height: 0, opacity: 0 }}
              className="px-4 pb-4 w-64"
            >
              <div className="flex flex-col items-center pt-2">
                
                {/* Node 1: FPGA */}
                <div className={`w-full bg-black/40 border ${borderFlash} rounded py-2 px-3 flex items-center justify-between transition-colors duration-300`}>
                  <span className="text-xs font-mono text-white/80">NEXYS 4 FPGA</span>
                  <span className={`w-2 h-2 rounded-full ${nodeStatusColor} transition-colors`} />
                </div>
                
                {/* Connection Line */}
                <div className={`h-8 w-px bg-white/10 relative ${isBursting ? 'burst' : ''}`}>
                  <div className="data-dot dot-delay-1" />
                  <div className="data-dot dot-delay-2" />
                  <div className="data-dot dot-delay-3" />
                </div>
                
                {/* Node 2: UART */}
                <div className={`w-full bg-black/40 border ${borderFlash} rounded py-2 px-3 flex items-center justify-between transition-colors duration-300`}>
                  <span className="text-xs font-mono text-white/80">UART / SERIAL</span>
                  <span className={`w-2 h-2 rounded-full ${nodeStatusColor} transition-colors`} />
                </div>
                
                {/* Connection Line */}
                <div className={`h-8 w-px bg-white/10 relative ${isBursting ? 'burst' : ''}`}>
                  <div className="data-dot dot-delay-1" />
                  <div className="data-dot dot-delay-2" />
                  <div className="data-dot dot-delay-3" />
                </div>
                
                {/* Node 3: WEB SERIAL API */}
                <div className={`w-full bg-black/40 border ${borderFlash} rounded py-2 px-3 flex items-center justify-between transition-colors duration-300`}>
                  <span className="text-xs font-mono text-white/80">WEB SERIAL API</span>
                  <span className={`w-2 h-2 rounded-full ${nodeStatusColor} transition-colors`} />
                </div>
                
                {/* Connection Line */}
                <div className={`h-8 w-px bg-white/10 relative ${isBursting ? 'burst' : ''}`}>
                  <div className="data-dot dot-delay-1" />
                  <div className="data-dot dot-delay-2" />
                  <div className="data-dot dot-delay-3" />
                </div>
                
                {/* Node 4: DASHBOARD */}
                <div className={`w-full bg-black/40 border ${borderFlash} rounded py-2 px-3 flex items-center justify-between transition-colors duration-300`}>
                  <span className="text-xs font-mono text-white/80 text-orange-400">DASHBOARD</span>
                  <span className="w-2 h-2 rounded-full bg-green-500 shadow-[0_0_8px_rgba(34,197,94,0.6)]" />
                </div>

                {/* Branches */}
                <div className="flex w-full mt-2 relative">
                  <div className="absolute top-0 left-1/2 -ml-px w-px h-2 bg-white/10" />
                  <div className="absolute top-2 left-6 right-6 h-px bg-white/10" />
                  <div className="absolute top-2 left-6 w-px h-2 bg-white/10" />
                  <div className="absolute top-2 left-1/2 -ml-px w-px h-2 bg-white/10" />
                  <div className="absolute top-2 right-6 w-px h-2 bg-white/10" />
                  
                  <div className="flex justify-between w-full pt-4">
                    <div className="flex flex-col items-center">
                      <span className="w-1.5 h-1.5 rounded-full bg-green-500 mb-1" />
                      <span className="text-[9px] font-mono text-white/50">DASHBOARD</span>
                    </div>
                    <div className="flex flex-col items-center">
                      <span className="w-1.5 h-1.5 rounded-full bg-green-500 mb-1" />
                      <span className="text-[9px] font-mono text-white/50">SIMULATION</span>
                    </div>
                    <div className="flex flex-col items-center">
                      <span className="w-1.5 h-1.5 rounded-full bg-green-500 mb-1" />
                      <span className="text-[9px] font-mono text-white/50">SUBSYSTEMS</span>
                    </div>
                  </div>
                </div>

              </div>

              {/* Status Footer */}
              <div className="mt-6 pt-4 border-t border-white/10">
                <p className={`text-xs font-mono mb-3 text-center ${isConnected ? 'text-green-400' : 'text-white/40'}`}>
                  {isConnected 
                    ? `SOURCE: Live · ${sourceName}` 
                    : "SOURCE: Simulated · No hardware detected"}
                </p>

                {isConnected ? (
                  <button 
                    onClick={disconnectFPGA}
                    className="w-full py-2 border border-white/20 rounded text-xs font-bold text-white/70 hover:bg-white/5 transition-colors uppercase tracking-wider"
                  >
                    Disconnect
                  </button>
                ) : (
                  <button 
                    onClick={connectFPGA}
                    className="w-full py-2 border border-orange-500/50 rounded text-xs font-bold text-orange-400 hover:bg-orange-500/10 transition-colors uppercase tracking-wider"
                  >
                    Connect FPGA Board
                  </button>
                )}
              </div>
            </motion.div>
          )}
        </AnimatePresence>
      </motion.div>
    </div>
  );
}
