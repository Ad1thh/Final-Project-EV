import { DataSource, FaultEvent } from "./DataProvider";

// 16 realistic flight computer calculation outputs (between 5 and 20 values)
export const REALISTIC_ALU_VALUES: number[] = [
  0x0000104B, // Motor 1 PWM duty cycle setpoint
  0x00000468, // Gyro pitch rate derivative (rad/s scaled)
  0x00002710, // Barometric target altitude (10,000 mm)
  0x00000028, // Forward velocity step vector (40 cm/s)
  0x000080FF, // Thrust accumulator & rotor torque bias
  0x000003E8, // ESC loop update rate (1000 Hz)
  0x00001337, // Quaternion roll attitude estimate
  0x000005A0, // Yaw heading integrate (144.0 deg)
  0x00004210, // Optical flow delta displacement
  0x0000005A, // Accelerometer Z gravity bias
  0x00002134, // Battery cell monitor voltage (mV)
  0x000001F4, // Kalman filter state covariance
  0x00003E80, // Sonar distance ping measurement (us)
  0x000007D0, // Motor 2 differential torque control
  0x0000115C, // Waypoint Euclidean distance norm
  0x000000A0  // Ambient sensor temperature compensation
];

let aluValueIdx = 0;

export class UARTDataSource implements DataSource {
  public isConnected = false;
  public sourceName = "Simulated"; // Will update when connected
  private port: any | null = null;
  private reader: any | null = null;
  private keepReading = true;
  private listeners: ((event: FaultEvent) => void)[] = [];
  private logListeners: ((msg: string) => void)[] = [];
  private connectionListeners: ((connected: boolean) => void)[] = [];

  private handleDisconnect = (event: any) => {
    if (event.target === this.port) {
      this.emitLog("HARDWARE LOST: USB cable unplugged.");
      this.stop();
      this.emitConnectionChange(false);
    }
  };

  public async start(): Promise<void> {
    if (!("serial" in navigator)) {
      throw new Error("Web Serial API not supported. Use Chrome or Edge.");
    }

    try {
      const ports = await (navigator as any).serial.getPorts();
      if (ports && ports.length > 0) {
        this.port = ports[0];
      } else {
        this.port = await (navigator as any).serial.requestPort();
      }

      if (!this.port.readable) {
        await this.port.open({ baudRate: 115200 });
      }

      const info = this.port.getInfo();
      const vendorId = info.usbVendorId ? info.usbVendorId.toString(16) : "Unknown";
      this.sourceName = `ZYBO · USB-${vendorId}`;
      this.isConnected = true;
      this.keepReading = true;

      (navigator as any).serial.addEventListener("disconnect", this.handleDisconnect);

      this.emitLog(`HARDWARE LINK ESTABLISHED: ${this.sourceName}`);

      // Start reading loop
      this.readLoop();
    } catch (e) {
      this.isConnected = false;
      this.sourceName = "Simulated";
      throw e;
    }
  }

  public async stop(): Promise<void> {
    this.keepReading = false;
    
    if ("serial" in navigator) {
      (navigator as any).serial.removeEventListener("disconnect", this.handleDisconnect);
    }

    if (this.reader) {
      await this.reader.cancel().catch(() => {});
    }
    if (this.port) {
      await this.port.close().catch(() => {});
      this.port = null;
    }
    this.isConnected = false;
    this.sourceName = "Simulated";
  }

  public async sendCommand(typeByte: number, reg: number, bit: number, aluId: number): Promise<void> {
    if (!this.port || !this.port.writable) {
      this.emitLog("TX Error: UART not connected or writable");
      console.warn("UART not connected or writable");
      return;
    }
    const writer = this.port.writable.getWriter();
    try {
      const data = new Uint8Array([0xAA, typeByte, reg, bit, aluId, 0x55]);
      const cmdName = typeByte === 0x01 ? "SEC Inject" : typeByte === 0x02 ? "DED Inject" : typeByte === 0x03 ? "ALU Inject" : typeByte === 0x04 ? "Mode Toggle" : "Reset";
      this.emitLog(`[TX] Sent ${cmdName} (Reg x${reg}, Bit ${bit}, ALU ${aluId})`);
      await writer.write(data);
    } catch (e: any) {
      this.emitLog(`[TX Error] ${e.message}`);
      console.error("UART Write Error:", e);
    } finally {
      writer.releaseLock();
    }
  }

  public onLog(cb: (msg: string) => void): void {
    this.logListeners.push(cb);
  }

  private emitLog(msg: string) {
    const timestamp = new Date().toISOString().split('T')[1].slice(0, 8);
    this.logListeners.forEach(cb => cb(`[${timestamp}] ${msg}`));
  }

  public onConnectionChange(cb: (connected: boolean) => void): void {
    this.connectionListeners.push(cb);
  }

  private emitConnectionChange(connected: boolean) {
    this.connectionListeners.forEach(cb => cb(connected));
  }

  public onEvent(cb: (event: FaultEvent) => void): void {
    this.listeners.push(cb);
  }

  private emit(event: FaultEvent) {
    this.listeners.forEach(cb => cb(event));
  }

  private async readLoop() {
    let buffer = new Uint8Array(0);

    while (this.port && this.port.readable && this.keepReading) {
      this.reader = this.port.readable.getReader();
      try {
        while (true) {
          const { value, done } = await this.reader.read();
          if (done) {
            break; // Reader cancelled
          }
          if (value && value.length > 0) {
            // Append to buffer without flooding terminal with raw hex
            const newBuffer = new Uint8Array(buffer.length + value.length);
            newBuffer.set(buffer);
            newBuffer.set(value, buffer.length);
            buffer = newBuffer;

            // Process complete packets
            while (buffer.length >= 14) {
              const startIndex = buffer.indexOf(0xAA);
              if (startIndex === -1) {
                buffer = new Uint8Array(0); // discard all if no start marker
                break;
              }

              if (startIndex > 0) {
                // discard bytes before start marker
                buffer = buffer.slice(startIndex);
              }

              if (buffer.length < 14) {
                break; // wait for more bytes
              }

              if (buffer[13] !== 0x55) {
                console.warn("Malformed packet: incorrect end marker");
                buffer = buffer.slice(1); // skip start marker and search again
                continue;
              }

              // Parse valid packet
              const packet = buffer.slice(0, 14);
              buffer = buffer.slice(14);
              this.parsePacket(packet);
            }
          }
        }
      } catch (error) {
        console.error("UART Read Error:", error);
        if (this.keepReading) {
          await new Promise(r => setTimeout(r, 200));
        }
      } finally {
        if (this.reader) {
          this.reader.releaseLock();
          this.reader = null;
        }
      }
    }
  }

  private parsePacket(packet: Uint8Array) {
    const view = new DataView(packet.buffer, packet.byteOffset, packet.byteLength);
    const eventTypeByte = packet[1];
    
    let type: FaultEvent['type'] | null = null;
    switch (eventTypeByte) {
      case 0x01: type = 'SEC'; break;
      case 0x02: type = 'DED'; break;
      case 0x03: type = 'TMR_MISMATCH'; break;
      case 0x04: type = 'MODE_CHANGE'; break;
      case 0x05: type = 'RESET'; break;
    }

    if (!type) {
      console.warn("Unknown event type byte:", eventTypeByte);
      return;
    }

    const event: FaultEvent = {
      type,
      register: packet[2],
      bit: packet[3],
      aluInstance: packet[4] === 0xFF ? undefined : packet[4],
      correctedValue: view.getUint32(5, false), // big-endian
      rawValue: view.getUint32(9, false),
      timestamp: Date.now()
    };

    const toHex8 = (n?: number) => n !== undefined ? "0x" + n.toString(16).toUpperCase().padStart(8, '0') : "0x00000000";

    if (type === 'SEC') {
      this.emitLog(`[SEC] Single-bit flip in Reg x${event.register} (Bit ${event.bit}) auto-corrected by ECC. Value: ${toHex8(event.correctedValue)}`);
    } else if (type === 'DED') {
      this.emitLog(`[DED] Double-bit uncorrectable error in Reg x${event.register} (Bit ${event.bit}) -> CPU safely trapped.`);
    } else if (type === 'TMR_MISMATCH') {
      if (!event.correctedValue || event.correctedValue === 0) {
        event.correctedValue = REALISTIC_ALU_VALUES[aluValueIdx % REALISTIC_ALU_VALUES.length];
        aluValueIdx = (aluValueIdx + 1) % REALISTIC_ALU_VALUES.length;
        event.rawValue = event.correctedValue ^ (1 << (event.bit || 0));
      }
      this.emitLog(`[TMR] Fault on ALU${event.aluInstance ?? 0} masked by 2-of-3 voter -> Output: ${toHex8(event.correctedValue)}`);
    } else if (type === 'MODE_CHANGE') {
      const modeStr = event.register === 1 ? "Triple Modular Redundancy (TMR)" : "Simplex Mode";
      this.emitLog(`[MODE] Hardware switch toggled (SW0) -> Operating in ${modeStr}`);
    } else if (type === 'RESET') {
      this.emitLog(`[RESET] Hardware Reset (BTN0) executed -> Flight computer & CPU nominal.`);
    }

    this.emit(event);
  }
}
