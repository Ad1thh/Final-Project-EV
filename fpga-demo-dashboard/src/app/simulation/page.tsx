"use client";

import React, { useRef, useMemo, useState, useEffect } from "react";
import { Canvas, useFrame } from "@react-three/fiber";
import { OrbitControls, useGLTF } from "@react-three/drei";
import * as THREE from "three";
import Navigation from "@/components/Navigation";
import { motion, AnimatePresence } from "framer-motion";

// ═══════════════════════════════════════════════════════════════════════════
// CUSTOM SHADERS & MATERIALS
// ═══════════════════════════════════════════════════════════════════════════

const groundGradientMaterial = new THREE.ShaderMaterial({
  transparent: true,
  depthWrite: false,
  uniforms: {
    color1: { value: new THREE.Color("#2a2a2e") },
    color2: { value: new THREE.Color("#0d0d10") },
  },
  vertexShader: `
    varying vec2 vUv;
    void main() {
      vUv = uv;
      gl_Position = projectionMatrix * modelViewMatrix * vec4(position, 1.0);
    }
  `,
  fragmentShader: `
    uniform vec3 color1;
    uniform vec3 color2;
    varying vec2 vUv;
    void main() {
      float d = distance(vUv, vec2(0.5));
      float alpha = smoothstep(0.5, 0.0, d) * 0.4; // 0.4 max opacity in center
      gl_FragColor = vec4(color1, alpha);
    }
  `,
});

// ═══════════════════════════════════════════════════════════════════════════
// 3D SCENE COMPONENTS
// ═══════════════════════════════════════════════════════════════════════════

const Drone = React.forwardRef<THREE.Group, { activeFault: "NORMAL" | "SEC" | "DED" }>((props, ref) => {
  const { scene } = useGLTF("/rc_quadcopter_v3.glb");
  const internalRef = useRef<THREE.Group>(null);
  
  // Expose to parent
  React.useImperativeHandle(ref, () => internalRef.current!);

  const state = useRef<"NORMAL" | "SEC" | "DED">("NORMAL");
  const landingState = useRef<{ active: boolean; startX: number; startY: number; startZ: number; }>({ active: false, startX: 0, startY: 4, startZ: 0 });
  const secWobbleTime = useRef(0);
  const pathTime = useRef(0);
  const dedPulseTime = useRef(0);
  
  // Particle systems
  const sparksRef = useRef<{ pos: THREE.Vector3; vel: THREE.Vector3; age: number }[]>([]);
  const sparkMeshRef = useRef<THREE.InstancedMesh>(null);
  const dummy = useMemo(() => new THREE.Object3D(), []);

  const { cloned, normScale, normOffset, bodyMaterials } = useMemo(() => {
    const cloned = scene.clone(true);
    cloned.position.set(0, 0, 0);
    cloned.rotation.set(0, 0, 0);
    cloned.scale.set(1, 1, 1);
    cloned.updateMatrixWorld(true);

    const box = new THREE.Box3().setFromObject(cloned);
    const sz = box.getSize(new THREE.Vector3());
    const ct = box.getCenter(new THREE.Vector3());
    const maxDim = Math.max(sz.x, sz.y, sz.z, 0.001);

    const normScale = 4.0 / maxDim;
    const normOffset = ct.clone().negate().multiplyScalar(normScale);

    const GRAPHITE_COLOR = new THREE.Color("#141416");
    const mats: THREE.MeshStandardMaterial[] = [];
    
    cloned.traverse((child) => {
      if ((child as THREE.Mesh).isMesh) {
        const mesh = child as THREE.Mesh;
        if (mesh.name.startsWith("Layer_")) {
          mesh.visible = false;
        } else {
          const mat = new THREE.MeshStandardMaterial({
            color: GRAPHITE_COLOR,
            roughness: 0.72,
            metalness: 0.35,
            emissive: new THREE.Color(0, 0, 0),
            emissiveIntensity: 0,
          });
          mesh.material = mat;
          mesh.castShadow = true;
          mesh.receiveShadow = true;
          mats.push(mat);
        }
      }
    });
    return { cloned, normScale, normOffset, bodyMaterials: mats };
  }, [scene]);

  useEffect(() => {
    if (props.activeFault === "DED") {
      if (state.current !== "DED") {
        state.current = "DED";
        if (internalRef.current) {
          landingState.current = {
            active: true,
            startX: internalRef.current.position.x,
            startY: internalRef.current.position.y,
            startZ: internalRef.current.position.z,
          };
          dedPulseTime.current = 0;
        }
      }
    } else if (props.activeFault === "SEC") {
      if (state.current !== "DED") {
        state.current = "SEC";
        secWobbleTime.current = 1.0; // 1 second pulse
        
        // Spawn sparks
        if (internalRef.current) {
           const newSparks = [];
           for(let i=0; i<12; i++) {
              const vel = new THREE.Vector3(
                 (Math.random() - 0.5) * 4,
                 (Math.random() - 0.5) * 4,
                 (Math.random() - 0.5) * 4
              );
              newSparks.push({ pos: new THREE.Vector3(), vel, age: 0 });
           }
           sparksRef.current = newSparks;
        }
      }
    } else {
      if (state.current === "DED") {
        state.current = "NORMAL";
        landingState.current.active = false;
      }
    }
  }, [props.activeFault]);

  useFrame((rootState, delta) => {
    if (!internalRef.current) return;
    
    const isDED = state.current === "DED";
    const currentY = internalRef.current.position.y;
    const landed = isDED && currentY <= 0.15;
    
    // --- Propellers ---
    let propSpeed = 25; // NORMAL & SEC
    if (isDED) {
      if (landed) {
        propSpeed = 0;
      } else {
        const startY = Math.max(landingState.current.startY, 0.2);
        const progress = Math.max(0, Math.min(1, (currentY - 0.1) / (startY - 0.1)));
        propSpeed = 25 * progress;
      }
    }
    
    cloned.traverse((child) => {
      if (child.name.toLowerCase().includes("prop")) {
        // FIX 1: Rotate on local Z axis
        child.rotation.z += propSpeed * delta;
      }
    });

    // --- Emissive Effects ---
    if (isDED) {
      dedPulseTime.current += delta;
      // Oscillate between 0.3 and 1.2 on a 1.5-second cycle
      // sine frequency = 2*PI / 1.5
      const intensity = 0.3 + ((Math.sin(dedPulseTime.current * (Math.PI * 2 / 1.5)) + 1) / 2) * 0.9;
      bodyMaterials.forEach(m => {
        m.emissive = new THREE.Color(0xef4444);
        m.emissiveIntensity = intensity;
      });
    } else if (state.current === "SEC" && secWobbleTime.current > 0) {
      // 0 -> 1.5 -> 0 over 1 second (sinusoidal pulse)
      const progress = 1.0 - secWobbleTime.current; // 0 to 1
      const intensity = Math.sin(progress * Math.PI) * 1.5;
      bodyMaterials.forEach(m => {
        m.emissive = new THREE.Color(0xf59e0b);
        m.emissiveIntensity = intensity;
      });
    } else {
      bodyMaterials.forEach(m => {
        m.emissive = new THREE.Color(0x000000);
        m.emissiveIntensity = 0;
      });
    }

    // --- Flight Path ---
    if (isDED) {
      if (currentY > 0.1) {
        internalRef.current.position.y -= 0.8 * delta;
        if (internalRef.current.position.y < 0.1) internalRef.current.position.y = 0.1;
        internalRef.current.position.x = landingState.current.startX;
        internalRef.current.position.z = landingState.current.startZ;
        internalRef.current.quaternion.slerp(new THREE.Quaternion().identity(), 5 * delta);
      }
    } else {
      pathTime.current += delta * 0.4;
      const a = 8;
      const b = 5;
      const x = Math.cos(pathTime.current) * a;
      const z = Math.sin(pathTime.current) * b;
      
      const hoverBob = Math.sin(rootState.clock.elapsedTime * 2) * 0.15;
      let targetY = 4 + hoverBob; // FIX 5: Y = 4 minimum
      
      if (currentY < 3.8) {
         internalRef.current.position.y = THREE.MathUtils.lerp(currentY, targetY, delta * 2);
      } else {
         internalRef.current.position.y = targetY;
      }
      
      internalRef.current.position.x = x;
      internalRef.current.position.z = z;
      
      const dx = -Math.sin(pathTime.current) * a;
      const dz = Math.cos(pathTime.current) * b;
      const angle = Math.atan2(dx, dz);
      
      const targetQuat = new THREE.Quaternion().setFromEuler(new THREE.Euler(0, angle, 0));
      
      if (state.current === "SEC" && secWobbleTime.current > 0) {
        secWobbleTime.current -= delta;
        const wobbleIntensity = (secWobbleTime.current / 1.0) * 0.2;
        const roll = (Math.random() - 0.5) * wobbleIntensity;
        const pitch = (Math.random() - 0.5) * wobbleIntensity;
        const wobbleQuat = new THREE.Quaternion().setFromEuler(new THREE.Euler(pitch, 0, roll));
        targetQuat.multiply(wobbleQuat);
      }
      
      internalRef.current.quaternion.slerp(targetQuat, 10 * delta);
    }

    // --- Sparks Update ---
    if (sparkMeshRef.current) {
       sparksRef.current = sparksRef.current.filter(p => p.age < 0.4);
       sparksRef.current.forEach((p, i) => {
          p.age += delta;
          p.pos.addScaledVector(p.vel, delta);
          p.vel.y -= 5 * delta; // gravity
          
          const scale = Math.max(0, 1 - (p.age / 0.4));
          dummy.position.copy(p.pos);
          // Apply drone's world transform to the sparks base position
          // so they spawn at the drone and fly outward
          const worldSpawn = p.pos.clone().applyMatrix4(internalRef.current!.matrixWorld);
          dummy.position.copy(worldSpawn);
          dummy.scale.setScalar(scale);
          dummy.updateMatrix();
          sparkMeshRef.current!.setMatrixAt(i, dummy.matrix);
       });
       sparkMeshRef.current.count = sparksRef.current.length;
       sparkMeshRef.current.instanceMatrix.needsUpdate = true;
    }
  });

  return (
    <>
       <group ref={internalRef}>
         <group position={[normOffset.x, normOffset.y, normOffset.z]} scale={normScale}>
           <primitive object={cloned} />
         </group>
       </group>
       <instancedMesh ref={sparkMeshRef} args={[undefined, undefined, 16]}>
         <sphereGeometry args={[0.05, 8, 8]} />
         <meshBasicMaterial color="#f97316" />
       </instancedMesh>
    </>
  );
});
Drone.displayName = "Drone";

useGLTF.preload("/rc_quadcopter_v3.glb");

function FlightTrail({ droneRef, activeFault }: { droneRef: React.RefObject<THREE.Group | null>, activeFault: string }) {
  const meshRef = useRef<THREE.InstancedMesh>(null);
  const trailRef = useRef<{pos: THREE.Vector3, age: number}[]>([]);
  const dummy = useMemo(() => new THREE.Object3D(), []);
  const emitTimer = useRef(0);

  useFrame((_, delta) => {
    if (!meshRef.current) return;
    
    emitTimer.current += delta;
    if (activeFault !== "DED" && droneRef.current && emitTimer.current > 0.1) {
       emitTimer.current = 0;
       trailRef.current.push({ pos: droneRef.current.position.clone(), age: 0 });
    }
    
    trailRef.current = trailRef.current.filter(p => p.age < 2.0);
    trailRef.current.forEach(p => p.age += delta);
    
    meshRef.current.count = trailRef.current.length;
    trailRef.current.forEach((p, i) => {
       const scale = Math.max(0, 1 - p.age / 2.0);
       dummy.position.copy(p.pos);
       dummy.scale.setScalar(scale);
       dummy.updateMatrix();
       meshRef.current!.setMatrixAt(i, dummy.matrix);
    });
    meshRef.current.instanceMatrix.needsUpdate = true;
  });

  return (
    <instancedMesh ref={meshRef} args={[undefined, undefined, 30]}>
      <sphereGeometry args={[0.04, 8, 8]} />
      <meshBasicMaterial color="#f97316" transparent opacity={0.3} />
    </instancedMesh>
  );
}

function SimEnvironment({ activeFault }: { activeFault: "NORMAL" | "SEC" | "DED" }) {
  const pointLightRef = useRef<THREE.PointLight>(null);
  const targetColor = activeFault === "DED" ? new THREE.Color("#ef4444") : new THREE.Color("#f97316");
  
  useFrame((state, delta) => {
    if (pointLightRef.current) {
      pointLightRef.current.color.lerp(targetColor, delta * 4);
      pointLightRef.current.intensity = THREE.MathUtils.lerp(
        pointLightRef.current.intensity,
        activeFault === "DED" ? 2.5 : 1.5,
        delta * 2
      );
    }
  });

  return (
    <>
      {/* FIX 4: Cinematic Lighting */}
      <directionalLight position={[5, 8, 3]} intensity={2.5} castShadow />
      <ambientLight intensity={0.15} />
      <pointLight ref={pointLightRef} position={[0, 2, 0]} intensity={1.5} distance={12} color="#f97316" />
      
      {/* FIX 8: Ground plane with radial gradient and distinct grid */}
      <mesh rotation={[-Math.PI / 2, 0, 0]} position={[0, -0.01, 0]} receiveShadow>
        <planeGeometry args={[50, 50]} />
        <meshStandardMaterial color="#0d0d10" />
      </mesh>
      <mesh rotation={[-Math.PI / 2, 0, 0]} position={[0, -0.005, 0]}>
         <planeGeometry args={[50, 50]} />
         <primitive object={groundGradientMaterial} attach="material" />
      </mesh>
      <gridHelper args={[50, 50, "#2a2a2e", "#2a2a2e"]} position={[0, 0.001, 0]} />
    </>
  );
}

function SceneContainer({ activeFault }: { activeFault: "NORMAL" | "SEC" | "DED" }) {
  const droneRef = useRef<THREE.Group>(null);
  const markerRef = useRef<THREE.Group>(null);
  const outerRingRef = useRef<THREE.Mesh>(null);
  const beamRef = useRef<THREE.Mesh>(null);
  const wasDED = useRef(false);

  useFrame((state, delta) => {
    const isDED = activeFault === "DED";
    if (isDED && !wasDED.current && droneRef.current && markerRef.current) {
      markerRef.current.position.set(
        droneRef.current.position.x,
        0.01,
        droneRef.current.position.z
      );
      markerRef.current.visible = true;
      wasDED.current = true;
    } else if (!isDED && wasDED.current) {
      if (markerRef.current) markerRef.current.visible = false;
      wasDED.current = false;
    }

    if (isDED && markerRef.current && outerRingRef.current && droneRef.current && beamRef.current) {
       // Pulsing outer ring
       const pulseScale = 1.0 + (Math.sin(state.clock.elapsedTime * Math.PI * 2) * 0.1);
       outerRingRef.current.scale.setScalar(pulseScale);

       // Vertical beam height matching drone altitude
       const alt = Math.max(0.1, droneRef.current.position.y);
       beamRef.current.scale.y = alt;
       beamRef.current.position.y = alt / 2;
    }

    // Soft chase camera - ensure ground plane in lower third
    if (droneRef.current && state.controls) {
      const controls = state.controls as any;
      controls.target.lerp(droneRef.current.position, delta * 2);
      controls.update();
    }
  });

  return (
    <>
      <SimEnvironment activeFault={activeFault} />
      
      {/* FIX 7: Enhanced Landing Marker & Vertical Beam */}
      <group ref={markerRef} visible={false}>
         {/* Inner Ring */}
         <mesh rotation={[-Math.PI / 2, 0, 0]} position={[0, 0.02, 0]}>
            <ringGeometry args={[0.95, 1.0, 32]} />
            <meshBasicMaterial color="#ef4444" opacity={0.8} transparent side={THREE.DoubleSide} />
         </mesh>
         {/* Outer Ring */}
         <mesh ref={outerRingRef} rotation={[-Math.PI / 2, 0, 0]} position={[0, 0.02, 0]}>
            <ringGeometry args={[1.5, 1.6, 32]} />
            <meshBasicMaterial color="#ef4444" opacity={0.8} transparent side={THREE.DoubleSide} />
         </mesh>
         {/* Crosshair */}
         <group position={[0, 0.02, 0]}>
            <mesh position={[0.5, 0, 0]}><boxGeometry args={[0.4, 0.02, 0.02]}/><meshBasicMaterial color="#ef4444"/></mesh>
            <mesh position={[-0.5, 0, 0]}><boxGeometry args={[0.4, 0.02, 0.02]}/><meshBasicMaterial color="#ef4444"/></mesh>
            <mesh position={[0, 0, 0.5]}><boxGeometry args={[0.02, 0.02, 0.4]}/><meshBasicMaterial color="#ef4444"/></mesh>
            <mesh position={[0, 0, -0.5]}><boxGeometry args={[0.02, 0.02, 0.4]}/><meshBasicMaterial color="#ef4444"/></mesh>
         </group>
         {/* Vertical Beam */}
         <mesh ref={beamRef} position={[0, 0, 0]}>
            <cylinderGeometry args={[0.02, 0.02, 1, 8]} />
            <meshBasicMaterial color="#ef4444" transparent opacity={0.4} />
         </mesh>
      </group>

      <FlightTrail droneRef={droneRef} activeFault={activeFault} />
      <Drone ref={droneRef} activeFault={activeFault} />
    </>
  );
}

// ═══════════════════════════════════════════════════════════════════════════
// MAIN PAGE & HUD
// ═══════════════════════════════════════════════════════════════════════════
import { useDashboard } from "@/lib/DashboardContext";

export default function SimulationPage() {
  const { activeFaultModule, injectFault, resetDemo, liveMonitor, toasts } = useDashboard();
  
  const globalFault = activeFaultModule === "CPU_DED" ? "DED" 
                    : (activeFaultModule === "CPU_SEC" || (activeFaultModule && activeFaultModule.startsWith("ALU_"))) ? "SEC" 
                    : "NORMAL";

  const [isSynced, setIsSynced] = useState(true);
  const [localFault, setLocalFault] = useState<"NORMAL" | "SEC" | "DED">("NORMAL");
  const [localEvents, setLocalEvents] = useState<{ id: number, time: string, text: string }[]>([]);

  const localFaultRef = useRef(localFault);
  useEffect(() => {
    localFaultRef.current = localFault;
  }, [localFault]);

  const addLocalEvent = (text: string) => {
    const now = new Date();
    const timeStr = `${now.getHours().toString().padStart(2, '0')}:${now.getMinutes().toString().padStart(2, '0')}:${now.getSeconds().toString().padStart(2, '0')}`;
    setLocalEvents(prev => [...prev, { id: Date.now(), time: timeStr, text }]);
  };

  const injectLocalSEC = () => {
    if (localFaultRef.current === "DED") return;
    setLocalFault("SEC");
    addLocalEvent("SEC injected, auto-correcting...");
    setTimeout(() => {
      if (localFaultRef.current !== "DED") {
        setLocalFault("NORMAL");
        addLocalEvent("SEC corrected — flight nominal");
      }
    }, 1500);
  };

  const injectLocalDED = () => {
    if (localFaultRef.current === "DED") return;
    setLocalFault("DED");
    addLocalEvent("DED detected, safe land initiated");
  };

  const resetLocalSim = () => {
    setLocalFault("NORMAL");
    addLocalEvent("Simulation reset to nominal flight");
  };
                    
  const activeFault = isSynced ? globalFault : localFault;
                    
  // DED State tracking for HUD
  const [dedState, setDedState] = useState<"DETECTED" | "LANDING" | "LANDED">("DETECTED");
  
  useEffect(() => {
    if (activeFault === "DED") {
      setDedState("DETECTED");
      const t1 = setTimeout(() => setDedState("LANDING"), 1000);
      const t2 = setTimeout(() => setDedState("LANDED"), 4000);
      return () => { clearTimeout(t1); clearTimeout(t2); };
    }
  }, [activeFault]);

  let statusText = "STATUS: NOMINAL";
  let statusColor = "text-green-500";
  let borderColor = "border-l-green-500";
  
  if (activeFault === "DED") {
    statusColor = "text-red-500";
    borderColor = "border-l-red-500";
    if (dedState === "DETECTED") statusText = "DED DETECTED — UNCORRECTABLE ERROR";
    else if (dedState === "LANDING") statusText = "INITIATING SAFE LAND";
    else statusText = "LANDED SAFELY";
  } else if (activeFault === "SEC") {
    statusColor = "text-amber-500";
    borderColor = "border-l-amber-500";
    statusText = "FAULT DETECTED — CORRECTED";
  }

  // Build events log from toasts for visual display if synced, else local events
  const events = isSynced 
    ? toasts.map(t => ({
        id: t.id,
        time: new Date().toLocaleTimeString(),
        text: t.message
      }))
    : localEvents;

  return (
    <div className="relative w-full h-screen bg-[#0d0d10] overflow-hidden">
      <Navigation />
      
      {/* HUD OVERLAY */}
      <div className="absolute inset-0 pointer-events-none z-10 p-6 flex flex-col justify-between">
        
        {/* Title and Status Pill */}
        <div className="absolute top-20 left-1/2 -translate-x-1/2 flex flex-col items-center gap-4 w-full max-w-[400px]">
          <h1 className="text-xl font-bold tracking-[0.2em] text-white/90 uppercase text-center w-full">
            Fault Response Simulation
          </h1>
          <AnimatePresence mode="wait">
            <motion.div
              key={activeFault + dedState}
              initial={{ opacity: 0, scale: 0.95, y: -5 }}
              animate={{ opacity: 1, scale: 1, y: 0 }}
              exit={{ opacity: 0, scale: 1.05, y: 5 }}
              transition={{ duration: 0.2 }}
              className={`w-full bg-black/60 backdrop-blur-xl border border-white/10 rounded-full py-3 px-6 shadow-lg border-l-4 ${borderColor}`}
            >
              <p className={`font-mono text-base font-bold tracking-wider text-center ${statusColor}`}>
                {statusText}
              </p>
            </motion.div>
          </AnimatePresence>
        </div>

        {/* Event Log Polish */}
        <div 
          className="absolute bottom-6 left-6 bg-black/60 backdrop-blur-xl border border-white/10 rounded-lg p-3 w-96 shadow-lg"
        >
          <h3 className="text-xs font-bold text-white/50 uppercase tracking-widest mb-2 border-b border-white/10 pb-1">
            System Event Log
          </h3>
          <div 
            className="flex flex-col gap-1 font-mono text-xs overflow-y-auto pr-2"
            style={{ 
               maxHeight: '120px', 
               maskImage: 'linear-gradient(to bottom, transparent, black 15%)',
               WebkitMaskImage: 'linear-gradient(to bottom, transparent, black 15%)' 
            }}
          >
            <AnimatePresence initial={false}>
              {events.length === 0 ? (
                <p className="text-white/30 italic mt-4">Waiting for telemetry...</p>
              ) : (
                [...events].reverse().map((ev) => (
                  <motion.div
                    key={ev.id}
                    initial={{ opacity: 0, x: -10 }}
                    animate={{ opacity: 1, x: 0 }}
                    className="text-white/70 flex gap-2 shrink-0 py-0.5"
                  >
                    <span className="text-white/40">{ev.time}</span>
                    <span>—</span>
                    <span className={ev.text.includes("error") || ev.text.includes("DED") ? "text-red-400" : ev.text.includes("ECC") || ev.text.includes("SEC") ? "text-amber-400" : "text-green-400"}>
                      {ev.text}
                    </span>
                  </motion.div>
                ))
              )}
            </AnimatePresence>
          </div>
        </div>
      </div>

      {/* Manual Injection Buttons */}
      <div className="absolute bottom-6 right-6 bg-black/60 backdrop-blur-xl border border-white/10 rounded-lg p-4 flex flex-col gap-3 shadow-lg pointer-events-auto z-10">
        <div 
          className="flex justify-between items-center mb-3 pb-2 border-b border-white/10"
        >
          <h3 className="text-xs font-bold text-white/50 uppercase tracking-widest">
            Sandbox Controls
          </h3>
          <button 
            onClick={() => setIsSynced(!isSynced)}
            className={`text-[10px] font-bold px-2 py-1 rounded transition-colors ${
              isSynced ? "bg-green-500/20 text-green-400 border border-green-500/50" : "bg-white/10 text-white/50 border border-white/20"
            }`}
          >
            {isSynced ? "SYNCED" : "MANUAL"}
          </button>
        </div>
        <button 
          onClick={() => isSynced ? injectFault("SEC") : injectLocalSEC()} 
          className="bg-amber-500/10 text-amber-500 border border-amber-500 hover:bg-amber-500/20 px-4 py-2 rounded text-xs font-bold tracking-wider transition-colors"
        >
          INJECT SEC / TMR FAULT
        </button>
        <button 
          onClick={() => isSynced ? injectFault("DED") : injectLocalDED()} 
          className="bg-red-500/10 text-red-500 border border-red-500 hover:bg-red-500/20 px-4 py-2 rounded text-xs font-bold tracking-wider transition-colors"
        >
          INJECT DED FAULT
        </button>
        <button 
          onClick={() => isSynced ? resetDemo() : resetLocalSim()} 
          className="bg-white/5 text-white/70 border border-white/20 hover:bg-white/10 px-4 py-2 rounded text-xs font-bold tracking-wider transition-colors mt-2"
        >
          RESET FLIGHT
        </button>
      </div>
      
      {/* 3D CANVAS */}
      <Canvas camera={{ position: [0, 8, 15], fov: 50 }}>
        <OrbitControls 
          makeDefault
          enablePan={false}
          maxPolarAngle={Math.PI / 2 - 0.1} // Keep camera above ground
          minDistance={5}
          maxDistance={30}
        />
        <SceneContainer activeFault={activeFault} />
      </Canvas>
    </div>
  );
}
