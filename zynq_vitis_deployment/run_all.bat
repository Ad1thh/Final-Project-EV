@echo off
setlocal enabledelayedexpansion
title Master 1-Click Zynq-7000 SoC Build & Deployment Flow

echo ==========================================================================
echo   MASTER 1-CLICK ZYNQ-7000 SOC BUILD & RUNTIME DEPLOYMENT
echo   Target: Digilent Zybo (Zynq-7000 XC7Z010-1CLG400C)
echo ==========================================================================
echo.

echo [1/3] Executing Vivado SoC Synthesis and Bitstream Build...
call 1_build_bitstream.bat
if %ERRORLEVEL% NEQ 0 exit /b %ERRORLEVEL%

echo.
echo [2/3] Executing Vitis Baremetal C Firmware Build...
call 2_build_vitis_app.bat
if %ERRORLEVEL% NEQ 0 exit /b %ERRORLEVEL%

echo.
echo [3/3] Programming Zybo FPGA and Launching ARM Cortex-A9 Application...
call 3_program_and_run.bat
if %ERRORLEVEL% NEQ 0 exit /b %ERRORLEVEL%

echo.
echo ==========================================================================
echo  [SUCCESS] Full Zynq SoC Flow Built, Deployed, and Running on Digilent Zybo!
echo ==========================================================================
pause
