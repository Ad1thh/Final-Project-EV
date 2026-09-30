import { DataSource, FaultEvent } from "./DataProvider";

export class UARTDataSource implements DataSource {
  public isConnected = false;
  public sourceName = "Simulated"; // Will update when connected
  private port: any | null = null;
  private reader: any | null = null;
  private keepReading = true;
  private listeners: ((event: FaultEvent) => void)[] = [];

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
    if (this.reader) {
      await this.reader.cancel();
    }
    if (this.port) {
      await this.port.close();
      this.port = null;
    }
    this.isConnected = false;
    this.sourceName = "Simulated";
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
          if (value) {
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
