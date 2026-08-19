"use client";

import React, { Component, ErrorInfo, ReactNode } from "react";
import { AlertTriangle } from "lucide-react";

interface Props {
  children?: ReactNode;
  fallbackMessage?: string;
}

interface State {
  hasError: boolean;
  error: Error | null;
}

export class ErrorBoundary extends Component<Props, State> {
  public state: State = {
    hasError: false,
    error: null
  };

  public static getDerivedStateFromError(error: Error): State {
    return { hasError: true, error };
  }

  public componentDidCatch(error: Error, errorInfo: ErrorInfo) {
    console.error("Uncaught error in 3D scene:", error, errorInfo);
  }

  public render() {
    if (this.state.hasError) {
      return (
        <div className="absolute inset-0 flex items-center justify-center bg-black/40 backdrop-blur-sm z-50">
          <div className="bg-red-950/80 border border-red-500/50 rounded-xl p-6 flex flex-col items-center gap-4 text-center max-w-md shadow-2xl">
            <AlertTriangle className="w-12 h-12 text-red-500" />
            <div>
              <h3 className="text-red-400 font-bold tracking-widest uppercase text-sm mb-2">Visualization Unavailable</h3>
              <p className="text-red-200/80 text-xs font-mono leading-relaxed">
                {this.props.fallbackMessage || "The 3D model or animation data could not be loaded correctly. This page will remain in safe mode."}
              </p>
            </div>
          </div>
        </div>
      );
    }

    return this.props.children;
  }
}
