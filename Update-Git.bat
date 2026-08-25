@echo off
:: Tu dong xin quyen Administrator neu chua co
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo Dang yeu cau quyen Administrator...
    powershell -Command "Start-Process '%~f0' -Verb RunAs"
    exit /b
)

echo ==========================================
echo       DANG TU DONG NANG CAP GIT...
echo ==========================================

:: Dong cac tien trinh Git dang chay de tranh bi loi khoa file
powershell -Command "Get-Process -Name 'bash','git','sh','mintty' -ErrorAction SilentlyContinue | Stop-Process -Force"

:: Chay nang cap Git qua winget
winget upgrade --id Git.Git -e --accept-source-agreements --accept-package-agreements --silent

echo ==========================================
echo   NANG CAP HOAN TAT! Kiem tra phien ban:
echo ==========================================
git --version

echo.
pause
