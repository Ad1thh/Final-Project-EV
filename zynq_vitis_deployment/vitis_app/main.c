#include "xparameters.h"
#include "xuartps.h"
#include "xgpio.h"
#include "xil_printf.h"

#ifndef XPAR_XUARTPS_0_DEVICE_ID
#ifdef XPAR_XUARTPS_0_BASEADDR
#define XPAR_XUARTPS_0_DEVICE_ID XPAR_XUARTPS_0_BASEADDR
#endif
#endif

#ifndef XPAR_AXI_GPIO_0_DEVICE_ID
#ifdef XPAR_XGPIO_0_BASEADDR
#define XPAR_AXI_GPIO_0_DEVICE_ID XPAR_XGPIO_0_BASEADDR
#endif
#endif

static XUartPs Uart;
static XGpio Gpio;

int main() {
    // 1. Initialize UART1 (connected to Zybo FT2232 USB-UART port)
    XUartPs_Config *Config = XUartPs_LookupConfig(XPAR_XUARTPS_0_DEVICE_ID);
    if (Config != NULL) {
        XUartPs_CfgInitialize(&Uart, Config, Config->BaseAddress);
        XUartPs_SetBaudRate(&Uart, 115200);
        // Explicitly enable UART transmitter and receiver
        XUartPs_WriteReg(Config->BaseAddress, XUARTPS_CR_OFFSET, XUARTPS_CR_TX_EN | XUARTPS_CR_RX_EN);
    }

    // 2. Initialize AXI GPIO (connected to PL RISC-V HIL bridge)
    XGpio_Initialize(&Gpio, XPAR_AXI_GPIO_0_DEVICE_ID);
    XGpio_SetDataDirection(&Gpio, 1, 0x00000000); // Channel 1: Output to PL
    XGpio_SetDataDirection(&Gpio, 2, 0xFFFFFFFF); // Channel 2: Input from PL

    u32 gpio_ch1_val = 0;
    u32 rx_toggle = 0;
    u32 tx_ack = 0;
    u32 last_tx_toggle = 0;

    // Reset initial state to PL
    XGpio_DiscreteWrite(&Gpio, 1, gpio_ch1_val);

    // Initial boot heartbeat bytes out to PC
    const char boot_msg[] = "ZYBO_READY\r\n";
    for (int i = 0; boot_msg[i] != '\0'; i++) {
        while (XUartPs_IsTransmitFull(Config->BaseAddress));
        XUartPs_WriteReg(Config->BaseAddress, XUARTPS_FIFO_OFFSET, (u8)boot_msg[i]);
    }

    while (1) {
        // --------------------------------------------------------------------
        // PC -> FPGA (Dashboard / PC sends command to board)
        // --------------------------------------------------------------------
        if (XUartPs_IsReceiveData(Config->BaseAddress)) {
            u8 rx_byte = (u8)XUartPs_ReadReg(Config->BaseAddress, XUARTPS_FIFO_OFFSET);
            
            // Toggle bit 8 to signal new valid byte to PL
            rx_toggle ^= 0x100;
            gpio_ch1_val = (gpio_ch1_val & 0x200) | (u32)rx_byte | rx_toggle;
            XGpio_DiscreteWrite(&Gpio, 1, gpio_ch1_val);
        }

        // --------------------------------------------------------------------
        // FPGA -> PC (Board sends telemetry / fault frame to PC)
        // --------------------------------------------------------------------
        u32 pl_in = XGpio_DiscreteRead(&Gpio, 2);
        u32 tx_toggle = pl_in & 0x100;
        
        // If PL toggled bit 8, it has a new byte to send
        if (tx_toggle != last_tx_toggle) {
            u8 tx_byte = (u8)(pl_in & 0xFF);
            
            // Wait until UART TX FIFO has room
            while (XUartPs_IsTransmitFull(Config->BaseAddress));
            
            XUartPs_WriteReg(Config->BaseAddress, XUARTPS_FIFO_OFFSET, tx_byte);
            last_tx_toggle = tx_toggle;
            
            // Acknowledge receipt back to PL by toggling bit 9
            tx_ack ^= 0x200;
            gpio_ch1_val = (gpio_ch1_val & 0x1FF) | tx_ack;
            XGpio_DiscreteWrite(&Gpio, 1, gpio_ch1_val);
        }
    }

    return 0;
}
