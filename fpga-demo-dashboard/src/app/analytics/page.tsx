"use client";

import React, { useEffect, useRef } from "react";
import { DashboardProvider, useDashboard } from "@/lib/DashboardContext";
import Navigation from "@/components/Navigation";
import { BarChart2, Activity, ShieldAlert, Cpu } from "lucide-react";
import { XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer, AreaChart, Area } from "recharts";
import anime from "animejs";

function AnalyticsContent() {
  const { faultStats, faultHistory, isDemoActive, setIsDemoActive, resetDemo } = useDashboard();
  const panelRef = useRef<HTMLDivElement>(null);

  useEffect(() => {
    anime({
      targets: panelRef.current,
      translateY: [50, 0],
      opacity: [0, 1],
      delay: 500,
      easing: "easeOutExpo",
      duration: 1200,
    });
  }, []);

  return (
    <div
      className="w-screen h-screen overflow-hidden bg-grid-pattern text-white relative font-sans no-scrollbar"
      style={{ backgroundColor: "#0d0d10" }}
    >
      <div className="absolute inset-0 bg-radial-gradient from-transparent to-black/80 pointer-events-none" />

      {/* Title */}
      <div className="absolute top-6 left-6 right-[30rem] z-10 pointer-events-none text-center flex flex-col items-center">
        <div className="bg-black/80 px-6 py-3 rounded-xl backdrop-blur-md border border-white/5 shadow-2xl">
          <h1 className="text-xl font-bold tracking-widest text-white/90 uppercase">Fault Tolerant Processor</h1>
          <p className="text-xs font-mono text-orange-500 mt-1 uppercase tracking-widest">Fault Analytics</p>
        </div>
      </div>

      <Navigation />

      <div ref={panelRef} className="absolute inset-0 pt-32 pb-12 px-12 z-10 flex flex-col pointer-events-none">
        
        {/* Stats row */}
        <div className="flex gap-6 mb-8 pointer-events-auto">
          <div className="flex-1 bg-black/60 backdrop-blur-xl border border-white/10 rounded-xl p-6 shadow-2xl flex items-center gap-6">
             <div className="p-4 bg-orange-500/10 rounded-full border border-orange-500/30">
               <Activity className="w-8 h-8 text-orange-500" />
             </div>
             <div>
                <div className="text-white/60 text-xs font-bold uppercase tracking-[0.2em] mb-1">Total Faults</div>
                <div className="text-4xl font-mono text-white/90">{faultStats.total}</div>
             </div>
          </div>
          <div className="flex-1 bg-black/60 backdrop-blur-xl border border-white/10 rounded-xl p-6 shadow-2xl flex items-center gap-6">
             <div className="p-4 bg-amber-500/10 rounded-full border border-amber-500/30">
               <ShieldAlert className="w-8 h-8 text-amber-500" />
             </div>
             <div>
                <div className="text-white/60 text-xs font-bold uppercase tracking-[0.2em] mb-1">SEC (Corrected)</div>
                <div className="text-4xl font-mono text-amber-500">{faultStats.sec}</div>
             </div>
          </div>
          <div className="flex-1 bg-black/60 backdrop-blur-xl border border-white/10 rounded-xl p-6 shadow-2xl flex items-center gap-6">
             <div className="p-4 bg-red-500/10 rounded-full border border-red-500/30">
               <Cpu className="w-8 h-8 text-red-500" />
             </div>
             <div>
                <div className="text-white/60 text-xs font-bold uppercase tracking-[0.2em] mb-1">ALU / DED</div>
                <div className="text-4xl font-mono text-red-500">{faultStats.alu + faultStats.ded}</div>
             </div>
          </div>
        </div>

        {/* Charts */}
        <div className="flex-1 bg-black/60 backdrop-blur-xl border border-white/10 rounded-xl p-8 shadow-2xl pointer-events-auto flex flex-col">
          <div className="flex justify-between items-center mb-6">
            <h2 className="text-white/60 text-sm font-bold uppercase tracking-[0.2em] flex items-center gap-2">
              <BarChart2 className="w-5 h-5 text-orange-500" /> Real-time Fault Events
            </h2>
            <div className="flex gap-4">
              <button onClick={() => setIsDemoActive(!isDemoActive)} className="px-4 py-1.5 bg-white/5 hover:bg-white/10 border border-white/10 text-white font-mono text-xs rounded transition-colors uppercase tracking-widest">
                {isDemoActive ? "Pause Tracking" : "Resume Tracking"}
              </button>
              <button onClick={resetDemo} className="px-4 py-1.5 bg-white/5 hover:bg-white/10 border border-white/10 text-white font-mono text-xs rounded transition-colors uppercase tracking-widest">
                Reset Stats
              </button>
            </div>
          </div>

          <div className="flex-1 min-h-[300px]">
            {faultHistory.length > 0 ? (
              <ResponsiveContainer width="100%" height="100%">
                <AreaChart data={faultHistory} margin={{ top: 10, right: 30, left: 0, bottom: 0 }}>
                  <defs>
                    <linearGradient id="colorSec" x1="0" y1="0" x2="0" y2="1">
                      <stop offset="5%" stopColor="#f59e0b" stopOpacity={0.8}/>
                      <stop offset="95%" stopColor="#f59e0b" stopOpacity={0}/>
                    </linearGradient>
                    <linearGradient id="colorAlu" x1="0" y1="0" x2="0" y2="1">
                      <stop offset="5%" stopColor="#ef4444" stopOpacity={0.8}/>
                      <stop offset="95%" stopColor="#ef4444" stopOpacity={0}/>
                    </linearGradient>
                  </defs>
                  <CartesianGrid strokeDasharray="3 3" stroke="#ffffff15" vertical={false} />
                  <XAxis dataKey="time" stroke="#ffffff50" fontSize={12} tickMargin={10} fontFamily="monospace" />
                  <YAxis stroke="#ffffff50" fontSize={12} tickMargin={10} fontFamily="monospace" />
                  <Tooltip 
                    contentStyle={{ backgroundColor: 'rgba(0,0,0,0.8)', borderColor: 'rgba(255,255,255,0.1)', borderRadius: '8px', color: '#fff' }}
                    itemStyle={{ fontFamily: 'monospace' }}
                    labelStyle={{ color: 'rgba(255,255,255,0.5)', marginBottom: '5px' }}
                  />
                  <Area type="monotone" dataKey="sec" name="SEC Events" stroke="#f59e0b" fillOpacity={1} fill="url(#colorSec)" strokeWidth={2} />
                  <Area type="monotone" dataKey="alu" name="ALU Faults" stroke="#ef4444" fillOpacity={1} fill="url(#colorAlu)" strokeWidth={2} />
                </AreaChart>
              </ResponsiveContainer>
            ) : (
              <div className="w-full h-full flex flex-col items-center justify-center text-white/30 font-mono text-sm gap-2">
                <BarChart2 className="w-8 h-8 opacity-20" />
                Waiting for fault events...
              </div>
            )}
          </div>
        </div>

      </div>
    </div>
  );
}

export default function AnalyticsPage() {
  return (
    <DashboardProvider>
      <AnalyticsContent />
    </DashboardProvider>
  );
}
