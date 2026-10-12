@echo off
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0Install-Addon.ps1" -ElevateOnAccessDenied
set "installExitCode=%ERRORLEVEL%"
echo.
echo Press any key to close this window . . .
pause >nul
exit /b %installExitCode%
