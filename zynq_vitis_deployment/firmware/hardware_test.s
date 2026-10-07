# ============================================================================
# File: hardware_test.s
# Description: RV32E Hardware Diagnostic Firmware for Xilinx Nexys 4 FPGA
# ============================================================================

    .text
    .globl _start

_start:
    # Set LED MMIO Base Address into x5 (t0) = 0x80000000
    lui x5, 0x80000

    # ------------------------------------------------------------------------
    # BOOT DISPLAY: Alternating Flash Pattern (0xAAAA -> 0x5555)
    # ------------------------------------------------------------------------
    li x6, 0xAAAA            # x6 = 0x0000AAAA
    sw x6, 0(x5)
    jal x1, delay_short

    li x6, 0x5555            # x6 = 0x00005555
    sw x6, 0(x5)
    jal x1, delay_short

    # ------------------------------------------------------------------------
    # STAGE 1: ALU Arithmetic & Logical Operations
    # ------------------------------------------------------------------------
    addi x6, x0, 1           # Status: Stage 1 active (LED 0 ON)
    sw x6, 0(x5)

    addi x1, x0, 15
    addi x2, x0, 25
    add x3, x1, x2           # 15 + 25 = 40
    addi x4, x0, 40
    bne x3, x4, fail_stage1

    sub x3, x2, x1           # 25 - 15 = 10
    addi x4, x0, 10
    bne x3, x4, fail_stage1

    and x3, x1, x2           # 15 & 25 = 9
    addi x4, x0, 9
    bne x3, x4, fail_stage1

    or x3, x1, x2            # 15 | 25 = 31
    addi x4, x0, 31
    bne x3, x4, fail_stage1

    xor x3, x1, x2           # 15 ^ 25 = 22
    addi x4, x0, 22
    bne x3, x4, fail_stage1

    slt x3, x1, x2           # 15 < 25 -> 1
    addi x4, x0, 1
    bne x3, x4, fail_stage1

    slt x3, x2, x1           # 25 < 15 -> 0
    bne x3, x0, fail_stage1

    jal x1, delay_short

    # ------------------------------------------------------------------------
    # STAGE 2: Shifts & Immediates
    # ------------------------------------------------------------------------
    addi x6, x0, 2           # Status: Stage 2 active (LED 1 ON)
    sw x6, 0(x5)

    addi x1, x0, 15
    slli x2, x1, 4           # 15 << 4 = 240
    addi x4, x0, 240
    bne x2, x4, fail_stage2

    srli x3, x2, 2           # 240 >> 2 = 60
    addi x4, x0, 60
    bne x3, x4, fail_stage2

    lui x1, 0x12345          # 0x12345000
    lui x4, 0x12345
    bne x1, x4, fail_stage2

    jal x1, delay_short

    # ------------------------------------------------------------------------
    # STAGE 3: Memory Alignment & Load/Store (SW, LW, SB, LBU, SH, LHU)
    # ------------------------------------------------------------------------
    addi x6, x0, 3           # Status: Stage 3 active (LED 0 & 1 ON)
    sw x6, 0(x5)

    # Use RAM address 0x00000400 (1024 bytes)
    lui x1, 0x00000
    addi x1, x1, 1024        # x1 = RAM pointer 0x400

    # 32-bit Word Test (SW / LW)
    lui x2, 0x12345
    sw x2, 0(x1)
    nop
    lw x3, 0(x1)
    bne x2, x3, fail_stage3

    # Byte Test (SB / LBU) - Uses x7 so x5 (MMIO pointer) is preserved!
    addi x4, x0, 0x5A
    sb x4, 4(x1)
    nop
    lbu x7, 4(x1)
    addi x6, x0, 0x5A
    bne x7, x6, fail_stage3

    # Halfword Test (SH / LHU) - Uses x7 so x5 (MMIO pointer) is preserved!
    addi x4, x0, 0x0468
    sh x4, 8(x1)
    nop
    lhu x7, 8(x1)
    bne x7, x4, fail_stage3

    jal x1, delay_short

    # ------------------------------------------------------------------------
    # STAGE 4: Control Flow (BEQ, BLT, JAL)
    # ------------------------------------------------------------------------
    addi x6, x0, 4           # Status: Stage 4 active (LED 2 ON)
    sw x6, 0(x5)

    beq x0, x0, br_target1
    jal x0, fail_stage4

br_target1:
    addi x1, x0, 5
    addi x2, x0, 10
    blt x1, x2, br_target2
    jal x0, fail_stage4

br_target2:
    jal x3, jump_target
    jal x0, fail_stage4

jump_target:
    beq x3, x0, fail_stage4
    jal x1, delay_short

    # ------------------------------------------------------------------------
    # STAGE 5: ALL TESTS PASSED! Display Success Pattern on LEDs (0x80FF)
    # ------------------------------------------------------------------------
pass_loop:
    # LED pattern: 0x80FF (LED 15 ON + Lower 8 LEDs ON)
    lui x6, 0x00008
    addi x6, x6, 255         # 0x80FF
    sw x6, 0(x5)
    jal x1, delay_short

    # Dynamic Chaser Effect
    addi x6, x0, 1
chaser:
    lui x7, 0x00008
    or x7, x7, x6
    sw x7, 0(x5)
    jal x1, delay_short
    slli x6, x6, 1
    andi x6, x6, 255         # Keep lower 8 bits
    bne x6, x0, chaser
    jal x0, pass_loop

# ----------------------------------------------------------------------------
# FAILURE HANDLERS: Display 0xF00<Stage_ID> on LEDs
# ----------------------------------------------------------------------------
fail_stage1:
    lui x6, 0x0000F
    addi x6, x6, 1           # 0xF001 (Fail Stage 1)
    sw x6, 0(x5)
    jal x0, trap_halt

fail_stage2:
    lui x6, 0x0000F
    addi x6, x6, 2           # 0xF002 (Fail Stage 2)
    sw x6, 0(x5)
    jal x0, trap_halt

fail_stage3:
    lui x6, 0x0000F
    addi x6, x6, 3           # 0xF003 (Fail Stage 3)
    sw x6, 0(x5)
    jal x0, trap_halt

fail_stage4:
    lui x6, 0x0000F
    addi x6, x6, 4           # 0xF004 (Fail Stage 4)
    sw x6, 0(x5)
    jal x0, trap_halt

trap_halt:
    ebreak
    jal x0, trap_halt

# ----------------------------------------------------------------------------
# DELAY SUBROUTINES (~0.1 seconds per delay)
# ----------------------------------------------------------------------------
delay_short:
    addi x8, x0, 0
    lui x9, 0x00100          # ~0.08 seconds at 25MHz
ds_loop:
    addi x8, x8, 1
    bne x8, x9, ds_loop
    jalr x0, 0(x1)
