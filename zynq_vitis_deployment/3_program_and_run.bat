@echo off
setlocal enabledelayedexpansion
title [Step 3] XSDB Hardware Flasher & Execution

echo ==========================================================================
echo  [STEP 3] Flashing Bitstream and Launching ARM Cortex-A9 UART Bridge
echo ==========================================================================

where xsdb >nul 2>nul
if %ERRORLEVEL% NEQ 0 (
    for %%D in (C D E F) do (
        for %%P in (AMDDesignTools Xilinx AMD) do (
            if exist "%%D:\%%P\Vivado" (
                for /f "delims=" %%V in ('dir /b "%%D:\%%P\Vivado" 2^>nul') do (
                    if exist "%%D:\%%P\Vivado\%%V\settings64.bat" (
                        call "%%D:\%%P\Vivado\%%V\settings64.bat" >nul 2>&1
                    )
                )
            )
            if exist "%%D:\%%P\2025.2\Vivado\settings64.bat" (
                call "%%D:\%%P\2025.2\Vivado\settings64.bat" >nul 2>&1
            )
        )
    )
)

where xsdb >nul 2>nul
if %ERRORLEVEL% NEQ 0 (
    echo [ERROR] 'xsdb' command not found. Sourcing Vivado/Vitis settings64.bat first.
    pause
    exit /b 1
)

echo [RUNNING] xsdb scripts/program_and_run_xsdb.tcl
call xsdb scripts/program_and_run_xsdb.tcl

echo.
echo ==========================================================================
echo  [STEP 3 COMPLETE] Hardware is executing live on Digilent Zybo!
echo  Open the Drone Web Dashboard, connect to COM port at 115200 baud,
echo  and test live telemetry and fault injection.
echo ==========================================================================
pause
