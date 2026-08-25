# Tu dong xin quyen Administrator neu chua co
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "Dang yeu cau quyen Administrator..." -ForegroundColor Yellow
    Start-Process powershell.exe -Verb RunAs -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`""
    exit
}

Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "       DANG TU DONG NANG CAP GIT...      " -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan

# Dong cac tien trinh Git dang chay de tranh bi khoa file
Write-Host "Dang kiem tra va dong cac tien trinh Git..." -ForegroundColor Yellow
Get-Process -Name 'bash','git','sh','mintty' -ErrorAction SilentlyContinue | Stop-Process -Force

# Chay nang cap Git qua winget
Write-Host "Dang chay winget upgrade Git..." -ForegroundColor Yellow
winget upgrade --id Git.Git -e --accept-source-agreements --accept-package-agreements --silent

Write-Host "`n==========================================" -ForegroundColor Green
Write-Host "  NANG CAP HOAN TAT! Kiem tra phien ban:  " -ForegroundColor Green
Write-Host "==========================================" -ForegroundColor Green
git --version

Write-Host "`nNhan phim bat ky de thoat..."
[void][System.Console]::ReadKey()
