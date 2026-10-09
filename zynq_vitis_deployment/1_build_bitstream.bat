@echo off
setlocal enabledelayedexpansion
title [Step 1] Vivado Zynq SoC Bitstream Builder

echo ==========================================================================
echo  [STEP 1] Generating Zynq-7000 PS+PL Block Design, Bitstream, and XSA
echo ==========================================================================

where vivado >nul 2>nul
if %ERRORLEVEL% NEQ 0 (
    echo [SEARCH] Searching for Vivado settings64.bat in AMDDesignTools and Xilinx...
    for %%D in (C D E F) do (
        for %%P in (AMDDesignTools Xilinx AMD) do (
            if exist "%%D:\%%P\Vivado" (
                for /f "delims=" %%V in ('dir /b "%%D:\%%P\Vivado" 2^>nul') do (
                    if exist "%%D:\%%P\Vivado\%%V\settings64.bat" (
                        echo [FOUND] Sourcing %%D:\%%P\Vivado\%%V\settings64.bat
                        call "%%D:\%%P\Vivado\%%V\settings64.bat" >nul 2>&1
                    )
                )
            )
            if exist "%%D:\%%P\2025.2.1\Vivado\settings64.bat" (
                echo [FOUND] Sourcing %%D:\%%P\2025.2.1\Vivado\settings64.bat
                call "%%D:\%%P\2025.2.1\Vivado\settings64.bat" >nul 2>&1
            )
            if exist "%%D:\%%P\2025.2\Vivado\settings64.bat" (
                echo [FOUND] Sourcing %%D:\%%P\2025.2\Vivado\settings64.bat
                call "%%D:\%%P\2025.2\Vivado\settings64.bat" >nul 2>&1
            )
            if exist "%%D:\%%P\2024.2\Vivado\settings64.bat" (
                echo [FOUND] Sourcing %%D:\%%P\2024.2\Vivado\settings64.bat
                call "%%D:\%%P\2024.2\Vivado\settings64.bat" >nul 2>&1
            )
            if exist "%%D:\%%P\2024.1\Vivado\settings64.bat" (
                echo [FOUND] Sourcing %%D:\%%P\2024.1\Vivado\settings64.bat
                call "%%D:\%%P\2024.1\Vivado\settings64.bat" >nul 2>&1
            )
            if exist "%%D:\%%P\2023.2\Vivado\settings64.bat" (
                echo [FOUND] Sourcing %%D:\%%P\2023.2\Vivado\settings64.bat
                call "%%D:\%%P\2023.2\Vivado\settings64.bat" >nul 2>&1
            )
        )
    )
)

where vivado >nul 2>nul
if %ERRORLEVEL% NEQ 0 (
    echo [ERROR] Could not find 'vivado' in PATH or standard installation locations!
    echo Please run this script from the Vivado TCL Shell or source settings64.bat first.
    pause
    exit /b 1
)

echo.
echo [RUNNING] vivado -mode batch -source scripts/build_soc_bitstream.tcl
call vivado -mode batch -source scripts/build_soc_bitstream.tcl -log output/vivado_build.log -journal output/vivado_build.jou

if %ERRORLEVEL% NEQ 0 (
    echo.
    echo [ERROR] Vivado bitstream build failed! Check output/vivado_build.log
    pause
    exit /b %ERRORLEVEL%
)

echo.
echo ==========================================================================
echo  [STEP 1 COMPLETE] Bitstream (fpga_top.bit) and Platform (system_wrapper.xsa) ready!
echo ==========================================================================
if not "%1"=="--nopause" pause
