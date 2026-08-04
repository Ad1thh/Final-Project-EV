import React from "react";
import Link from "next/link";
import { usePathname } from "next/navigation";
import { LayoutDashboard, Layers, BarChart2 } from "lucide-react";

export default function Navigation() {
  const pathname = usePathname();

  return (
    <div className="absolute top-6 right-6 z-50 flex items-center gap-2 bg-black/60 backdrop-blur-xl border border-white/10 p-1.5 rounded-full pointer-events-auto shadow-lg">
      <Link href="/" className={`flex items-center gap-2 px-4 py-2 rounded-full text-xs font-bold uppercase tracking-widest transition-colors ${pathname === "/" ? "bg-orange-500 text-white" : "text-white/60 hover:text-white hover:bg-white/10"}`}>
        <LayoutDashboard className="w-4 h-4" />
        Dashboard
      </Link>
      <Link href="/subsystems" className={`flex items-center gap-2 px-4 py-2 rounded-full text-xs font-bold uppercase tracking-widest transition-colors ${pathname === "/subsystems" ? "bg-orange-500 text-white" : "text-white/60 hover:text-white hover:bg-white/10"}`}>
        <Layers className="w-4 h-4" />
        Subsystems
      </Link>
      <Link href="/analytics" className={`flex items-center gap-2 px-4 py-2 rounded-full text-xs font-bold uppercase tracking-widest transition-colors ${pathname === "/analytics" ? "bg-orange-500 text-white" : "text-white/60 hover:text-white hover:bg-white/10"}`}>
        <BarChart2 className="w-4 h-4" />
        Analytics
      </Link>
    </div>
  );
}
