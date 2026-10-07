#include "xparameters.h"
#include "xuartps.h"
#include "xgpio.h"
#include "xil_printf.h"

XUartPs Uart;
XGpio Gpio;

int main() {
    // 1. Initialize UART1 (connected to Zybo USB-UART port)
    XUartPs_Config *Config = XUartPs_LookupConfig(XPAR_XUARTPS_0_DEVICE_ID);
    XUartPs_CfgInitialize(&Uart, Config, Config->BaseAddress);
    XUartPs_SetBaudRate(&Uart, 115200);

    // 2. Initialize AXI GPIO (connected to PL RISC-V core)
    XGpio_Initialize(&Gpio, XPAR_AXI_GPIO_0_DEVICE_ID);
    XGpio_SetDataDirection(&Gpio, 1, 0x00000000); // Channel 1: Output to PL
    XGpio_SetDataDirection(&Gpio, 2, 0xFFFFFFFF); // Channel 2: Input from PL

    u32 rx_toggle = 0;
    u32 tx_ack = 0;
    u32 last_tx_toggle = 0;

    // Reset initial state
    XGpio_DiscreteWrite(&Gpio, 1, 0x00000000);

    while (1) {
        // --------------------------------------------------------------------
        // PC -> FPGA (Dashboard sends command to board)
        // --------------------------------------------------------------------
        if (XUartPs_IsReceiveData(Config->BaseAddress)) {
            u8 rx_byte = XUartPs_ReadReg(Config->BaseAddress, XUARTPS_FIFO_OFFSET);
            
            // Toggle bit 8 to signal new valid byte to PL
            rx_toggle ^= 0x100; 
            XGpio_DiscreteWrite(&Gpio, 1, rx_byte | rx_toggle | tx_ack);
        }

        // --------------------------------------------------------------------
        // FPGA -> PC (Board sends response to Dashboard)
        // --------------------------------------------------------------------
        u32 pl_in = XGpio_DiscreteRead(&Gpio, 2);
        u32 tx_toggle = pl_in & 0x100;
        
        // If PL toggled bit 8, it has a new byte to send
        if (tx_toggle != last_tx_toggle) {
            u8 tx_byte = pl_in & 0xFF;
            
            // Wait until UART TX FIFO is not full
            while (XUartPs_IsTransmitFull(Config->BaseAddress));
            
            XUartPs_WriteReg(Config->BaseAddress, XUARTPS_FIFO_OFFSET, tx_byte);
            last_tx_toggle = tx_toggle;
            
            // Acknowledge receipt back to PL by toggling bit 9
            tx_ack ^= 0x200; 
            XGpio_DiscreteWrite(&Gpio, 1, (XGpio_DiscreteRead(&Gpio, 1) & 0x1FF) | tx_ack);
        }
    }

    return 0;
}
