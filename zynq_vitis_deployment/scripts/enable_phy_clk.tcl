connect
targets -set -nocase -filter {name =~ "*Cortex-A9*#0"}
configparams force-mem-accesses 1

# 1. Unlock SLCR
mwr 0xF8000008 0x0000DF0D

# 2. Enable GPIO clock in APER_CLK_CTRL
mwr 0xF800012C 0x016C000D

# 3. Configure MIO 47 as GPIO output
mwr 0xF80007BC 0x00001600

# 4. Set Direction and Output Enable for MIO 47 (Bank 1 bit 15)
# Bank 1 DIRM is at 0xE00A0244, Bank 1 OEN is at 0xE00A0248
catch {
    mwr 0xE00A0244 0x00008000
    mwr 0xE00A0248 0x00008000
    mwr 0xE00A0044 0x00008000
    puts "=== SUCCESS: MIO 47 SET TO HIGH ==="
} res
puts "Result: $res"

# Lock SLCR
mwr 0xF8000004 0x0000767B

# Check PL GPIO Channel 2 (0x41200008)
after 200
puts "=== PL GPIO Channel 2 (0x41200008): ==="
puts [mrd 0x41200008 1]

exit
