# RISC-V LED Firmware: Instantly turns ON all 16 LEDs, then runs chaser
# MMIO LED Address: 0x80000000

    lui x5, 0x80000      # x5 (t0) = 0x80000000 (LED MMIO Address)
    addi x6, x0, -1      # x6 (t1) = 0xFFFF (Turn ON all 16 LEDs immediately)
    sw x6, 0(x5)         # Write 0xFFFF to LEDs

    # Initial delay (~1 second with all LEDs ON to confirm boot)
    addi x7, x0, 0
    lui x8, 0x003F0      # ~1 second delay
init_delay:
    addi x7, x7, 1
    bne x7, x8, init_delay

    # Start moving pattern
    addi x6, x0, 1       # x6 = 1 (LED 0)
loop:
    sw x6, 0(x5)         # Store pattern to LEDs

    # Delay loop (~50ms)
    addi x7, x0, 0
    lui x8, 0x00050
delay:
    addi x7, x7, 1
    bne x7, x8, delay

    # Shift LED pattern left
    slli x6, x6, 1
    andi x6, x6, 65535   # Keep 16 bits (0xFFFF)
    bne x6, x0, loop
    addi x6, x0, 1       # Reset pattern to 1
    jal x0, loop
