import { DataSource, FaultEvent } from "./DataProvider";

export class SimulatedDataSource implements DataSource {
  public isConnected = false;
  public sourceName = "Simulated";
  private intervalId: NodeJS.Timeout | null = null;
  private listeners: ((event: FaultEvent) => void)[] = [];

  public async start(): Promise<void> {
    if (this.intervalId) return;
    this.intervalId = setInterval(() => {
      this.tick();
    }, 6000);
  }

  public stop(): void {
    if (this.intervalId) {
      clearInterval(this.intervalId);
      this.intervalId = null;
    }
  }

  public onEvent(cb: (event: FaultEvent) => void): void {
    this.listeners.push(cb);
  }

  private emit(event: FaultEvent) {
    this.listeners.forEach(cb => cb(event));
  }

  private tick() {
    if (Math.random() > 0.6) {
      const faults: ('SEC' | 'DED' | 'TMR_MISMATCH')[] = ["SEC", "SEC", "TMR_MISMATCH", "TMR_MISMATCH", "DED"];
      const randomFault = faults[Math.floor(Math.random() * faults.length)];
      const randomReg = Math.floor(Math.random() * 15) + 1; // 1-15
      const randomAlu = Math.floor(Math.random() * 3); // 0-2
      const randomBit = Math.floor(Math.random() * 39); // 0-38

      const event: FaultEvent = {
        type: randomFault,
        register: randomReg,
        bit: randomBit,
        timestamp: Date.now()
      };

      if (randomFault === 'TMR_MISMATCH') {
        event.aluInstance = randomAlu;
        event.correctedValue = 0x0000000F;
        event.rawValue = 0x00007FFF;
      } else {
        event.correctedValue = 0x0000000F;
        event.rawValue = 0xDEADBEEF;
      }

      this.emit(event);
    }
  }
}
