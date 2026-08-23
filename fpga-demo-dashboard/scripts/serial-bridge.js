const { SerialPort } = require('serialport');
const { ReadlineParser } = require('@serialport/parser-readline');
const WebSocket = require('ws');

const WS_PORT = 8080;
const BAUD_RATE = 115200;

// Set up WebSocket server
const wss = new WebSocket.Server({ port: WS_PORT });

wss.on('connection', (ws) => {
    console.log('[WebSocket] Client connected to dashboard bridge.');
    ws.on('close', () => console.log('[WebSocket] Client disconnected.'));
});

// Function to broadcast data to all connected clients
function broadcast(data) {
    wss.clients.forEach((client) => {
        if (client.readyState === WebSocket.OPEN) {
            client.send(JSON.stringify(data));
        }
    });
}

// Try to auto-detect the Nexys 4 COM port or fallback to mock data
async function startBridge() {
    console.log(`[Bridge] Starting... looking for serial ports.`);
    
    try {
        const ports = await SerialPort.list();
        // Typically, FTDI ports might show up as 'USB Serial Port'
        const fpgaPort = ports.find(p => p.manufacturer?.includes('FTDI') || p.path.includes('COM'));

        if (fpgaPort) {
            console.log(`[Bridge] Found potential FPGA port at ${fpgaPort.path}. Connecting...`);
            
            const port = new SerialPort({
                path: fpgaPort.path,
                baudRate: BAUD_RATE,
            });

            const parser = port.pipe(new ReadlineParser({ delimiter: '\n' }));

            port.on('open', () => {
                console.log(`[Serial] Successfully opened ${fpgaPort.path} at ${BAUD_RATE} baud.`);
            });

            parser.on('data', (data) => {
                console.log(`[Serial RX] ${data}`);
                try {
                    const parsed = JSON.parse(data.trim());
                    broadcast(parsed);
                } catch (e) {
                    console.error(`[Serial] Failed to parse JSON: ${data}`);
                }
            });

            port.on('error', (err) => {
                console.error(`[Serial Error] ${err.message}`);
                startMocking();
            });

        } else {
            console.warn('[Bridge] No suitable serial port found. Falling back to MOCK mode.');
            startMocking();
        }
    } catch (err) {
        console.error('[Bridge] Failed to list serial ports:', err);
        startMocking();
    }
}

// Mocking logic to simulate FPGA telemetry
function startMocking() {
    console.log('[Mock] Starting simulated FPGA telemetry broadcast...');
    
    // Simulate periodic normal heartbeats
    setInterval(() => {
        broadcast({ type: "HEARTBEAT", state: "Running", mode: "Simplex" });
    }, 1000);

    // Simulate random faults every 6 seconds to drive the dashboard
    setInterval(() => {
        const r = Math.random();
        if (r < 0.4) {
            // Simulate single bit ECC
            const reg = `x${Math.floor(Math.random() * 15) + 1}`;
            console.log(`[Mock] Injecting SEC fault on ${reg}`);
            broadcast({ type: "SEC", reg: reg, bit: "3", badValue: "0xDEADBEEF" });
            
            // Auto correct it after 800ms
            setTimeout(() => {
                broadcast({ type: "SEC_CORRECTED", reg: reg, goodValue: "0x0000000F" });
            }, 800);
            
        } else if (r < 0.8) {
            // Simulate ALU fault
            const aluId = Math.floor(Math.random() * 3).toString();
            console.log(`[Mock] Injecting ALU fault on ALU${aluId}`);
            broadcast({ type: "ALU", aluId: aluId, badValue: "0x00007FFF" });
            
            // Auto recover via TMR after 1.5s
            setTimeout(() => {
                broadcast({ type: "ALU_RECOVERED", aluId: aluId, goodValue: "0x0000000F" });
            }, 1500);
            
        } else {
            // Simulate Double-bit ECC (fatal)
            const reg = `x${Math.floor(Math.random() * 15) + 1}`;
            console.log(`[Mock] Injecting DED fault on ${reg}`);
            broadcast({ type: "DED", reg: reg });
        }
    }, 6000);
}

startBridge();
