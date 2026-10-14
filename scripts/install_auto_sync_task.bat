@echo off
echo ========================================================
echo Installing Windows Scheduled Task for Git Auto-Sync
echo ========================================================
set SCRIPT_PATH=%~dp0auto_sync.ps1
schtasks /create /sc minute /mo 30 /tn "GitAutoSync_FinalProjectEV" /tr "powershell.exe -ExecutionPolicy Bypass -WindowStyle Hidden -File \"%SCRIPT_PATH%\"" /f
if %ERRORLEVEL% EQU 0 (
    echo.
    echo [SUCCESS] Scheduled task 'GitAutoSync_FinalProjectEV' created!
    echo It will automatically sync your branch with main every 30 minutes in the background.
) else (
    echo.
    echo [ERROR] Failed to create scheduled task. Try running as Administrator.
)
pause
