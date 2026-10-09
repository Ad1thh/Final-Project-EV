@echo off
setlocal enabledelayedexpansion
title [Step 2] Vitis Embedded C Firmware Builder

echo ==========================================================================
echo  [STEP 2] Compiling Baremetal ARM Cortex-A9 Firmware (zynq_uart_bridge.elf)
echo ==========================================================================

if not exist "output\system_wrapper.xsa" (
    echo [ERROR] 'output\system_wrapper.xsa' not found!
    echo Please run '1_build_bitstream.bat' first.
    pause
    exit /b 1
)

where vitis >nul 2>nul
if %ERRORLEVEL% NEQ 0 (
    for %%D in (C D E F) do (
        for %%P in (AMDDesignTools Xilinx AMD) do (
            if exist "%%D:\%%P\Vitis" (
                for /f "delims=" %%V in ('dir /b "%%D:\%%P\Vitis" 2^>nul') do (
                    if exist "%%D:\%%P\Vitis\%%V\settings64.bat" (
                        echo [FOUND] Sourcing %%D:\%%P\Vitis\%%V\settings64.bat
                        call "%%D:\%%P\Vitis\%%V\settings64.bat" >nul 2>&1
                    )
                )
            )
            if exist "%%D:\%%P\2025.2.1\Vitis\settings64.bat" (
                echo [FOUND] Sourcing %%D:\%%P\2025.2.1\Vitis\settings64.bat
                call "%%D:\%%P\2025.2.1\Vitis\settings64.bat" >nul 2>&1
            )
            if exist "%%D:\%%P\2025.2\Vitis\settings64.bat" (
                echo [FOUND] Sourcing %%D:\%%P\2025.2\Vitis\settings64.bat
                call "%%D:\%%P\2025.2\Vitis\settings64.bat" >nul 2>&1
            )
            if exist "%%D:\%%P\2024.2\Vitis\settings64.bat" (
                echo [FOUND] Sourcing %%D:\%%P\2024.2\Vitis\settings64.bat
                call "%%D:\%%P\2024.2\Vitis\settings64.bat" >nul 2>&1
            )
        )
    )
)

where vitis >nul 2>nul
if %ERRORLEVEL% EQU 0 (
    echo [RUNNING] vitis -s scripts/vitis_build_app.py
    call vitis -s scripts/vitis_build_app.py
) else (
    where xsct >nul 2>nul
    if %ERRORLEVEL% EQU 0 (
        echo [RUNNING] xsct scripts/vitis_build_app_xsct.tcl
        call xsct scripts/vitis_build_app_xsct.tcl
    ) else (
        echo [ERROR] Neither 'vitis' nor 'xsct' found in system PATH.
        echo Please ensure Vitis is installed on this machine and settings64.bat is sourced.
        pause
        exit /b 1
    )
)

echo.
echo ==========================================================================
echo  [STEP 2 COMPLETE] Vitis Application Compiled Successfully!
echo ==========================================================================
