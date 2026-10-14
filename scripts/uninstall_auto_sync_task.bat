@echo off
echo ========================================================
echo Removing Windows Scheduled Task for Git Auto-Sync
echo ========================================================
schtasks /delete /tn "GitAutoSync_FinalProjectEV" /f
if %ERRORLEVEL% EQU 0 (
    echo.
    echo [SUCCESS] Scheduled task 'GitAutoSync_FinalProjectEV' removed successfully.
) else (
    echo.
    echo [INFO] Task not found or already removed.
)
pause
