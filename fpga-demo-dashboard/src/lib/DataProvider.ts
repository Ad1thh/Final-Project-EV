export type FaultEvent = {
  type: 'SEC' | 'DED' | 'TMR_MISMATCH' | 'MODE_CHANGE' | 'RESET';
  register?: number;   // which register (0-15 for RV32E)
  bit?: number;        // which bit position (0-38 for SEC-DED codeword)
  aluInstance?: number; // 0, 1, or 2 for TMR
  correctedValue?: number; // hex value after correction
  rawValue?: number;   // hex value before correction
  timestamp: number;
};

export interface DataSource {
  start(): Promise<void>;
  stop(): void;
  onEvent(cb: (event: FaultEvent) => void): void;
  isConnected: boolean;
  sourceName: string; // "Simulated" or "NEXYS 4 · COMx"
}
