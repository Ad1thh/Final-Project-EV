import { DataSource, FaultEvent } from "./DataProvider";

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
      this.port = await (navigator as any).serial.requestPort();
      await this.port.open({ baudRate: 115200 });

      const info = this.port.getInfo();
      const vendorId = info.usbVendorId ? info.usbVendorId.toString(16) : "Unknown";
      this.sourceName = `NEXYS 4 · USB-${vendorId}`;
      this.isConnected = true;
      this.keepReading = true;

      (navigator as any).serial.addEventListener("disconnect", this.handleDisconnect);

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
      const hex = Array.from(data).map(b => b.toString(16).padStart(2, '0').toUpperCase()).join(' ');
      this.emitLog(`TX: ${hex}`);
      await writer.write(data);
    } catch (e: any) {
      this.emitLog(`TX Error: ${e.message}`);
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
            const hex = Array.from(value as Uint8Array).map(b => b.toString(16).padStart(2, '0').toUpperCase()).join(' ');
            this.emitLog(`RX: ${hex}`);
            
            // Append to buffer
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

    this.emit(event);
  }
}
