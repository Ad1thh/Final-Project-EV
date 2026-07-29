@echo off
REM ============================================================================
REM Master 1-Click FPGA Build & Programming Batch Script
REM ============================================================================

echo ========================================================
echo  [STEP 1] Assembling Hardware Diagnostic Firmware
echo ========================================================
python sim/asm.py fpga/hardware_test.s fpga/firmware.hex
if %ERRORLEVEL% NEQ 0 (
    echo [ERROR] Firmware assembly failed!
    exit /b %ERRORLEVEL%
)

cmd /c copy /Y fpga\firmware.hex firmware.hex >nul

where vivado >nul 2>nul
if %ERRORLEVEL% NEQ 0 (
    echo [NOTICE] 'vivado' command not found in system PATH.
    echo [NOTICE] Searching standard Xilinx/AMD installation paths...
    for %%D in (C D E F) do (
        if exist "%%D:\Xilinx\Vivado" (
            for /f "delims=" %%V in ('dir /b "%%D:\Xilinx\Vivado" 2^>nul') do (
                if exist "%%D:\Xilinx\Vivado\%%V\settings64.bat" (
                    echo [FOUND] Sourcing %%D:\Xilinx\Vivado\%%V\settings64.bat
                    call "%%D:\Xilinx\Vivado\%%V\settings64.bat" >nul 2>&1
                )
            )
        )
        if exist "%%D:\AMDDesignTools" (
            for /f "delims=" %%V in ('dir /b "%%D:\AMDDesignTools" 2^>nul') do (
                if exist "%%D:\AMDDesignTools\%%V\Vivado\settings64.bat" (
                    echo [FOUND] Sourcing %%D:\AMDDesignTools\%%V\Vivado\settings64.bat
                    call "%%D:\AMDDesignTools\%%V\Vivado\settings64.bat" >nul 2>&1
                )
            )
        )
        if exist "%%D:\AMD\Vivado" (
            for /f "delims=" %%V in ('dir /b "%%D:\AMD\Vivado" 2^>nul') do (
                if exist "%%D:\AMD\Vivado\%%V\settings64.bat" (
                    echo [FOUND] Sourcing %%D:\AMD\Vivado\%%V\settings64.bat
                    call "%%D:\AMD\Vivado\%%V\settings64.bat" >nul 2>&1
                )
            )
        )
    )
)

where vivado >nul 2>nul
if %ERRORLEVEL% NEQ 0 (
    echo.
    echo [ERROR] Could not locate Vivado on this machine or in PATH!
    echo To fix this:
    echo  1. Open 'Vivado Tcl Shell' or 'Vivado Command Prompt' from Start Menu.
    echo  2. Or run 'call C:\Xilinx\Vivado\<version>\settings64.bat' first.
    exit /b 1
)

echo.
echo ========================================================
echo  [STEP 2] Running Vivado Non-Interactive Bitstream Build
echo ========================================================
vivado -mode batch -source fpga/build_bitstream.tcl -log fpga/vivado_build.log -journal fpga/vivado_build.jou
if %ERRORLEVEL% NEQ 0 (
    echo [ERROR] Vivado bitstream synthesis failed! Check fpga/vivado_build.log
    exit /b %ERRORLEVEL%
)

echo.
echo ========================================================
echo  [STEP 3] Flashing Bitstream onto Nexys 4 FPGA Board
echo ========================================================
vivado -mode batch -source fpga/program_fpga.tcl -log fpga/vivado_program.log -journal fpga/vivado_program.jou
if %ERRORLEVEL% NEQ 0 (
    echo [ERROR] FPGA programming failed! Make sure your Nexys 4 USB cable is plugged in and power is ON.
    exit /b %ERRORLEVEL%
)

echo.
echo ========================================================
echo  [COMPLETE] Hardware Test Loaded and Executing!
echo  Check the Nexys 4 board LEDs to confirm results.
echo ========================================================
