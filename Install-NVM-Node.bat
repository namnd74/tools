@echo off
:: Tu dong xin quyen Administrator neu chua co
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo Dang yeu cau quyen Administrator...
    powershell -Command "Start-Process '%~f0' -Verb RunAs"
    exit /b
)

echo ==========================================
echo     DANG CAI DAT NVM & NODE.JS 22.23+
echo ==========================================

powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0Install-NVM-Node.ps1"
