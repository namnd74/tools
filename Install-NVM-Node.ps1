# Tu dong xin quyen Administrator neu chua co (can de NVM tao symlink C:\Program Files\nodejs)
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "Dang yeu cau quyen Administrator..." -ForegroundColor Yellow
    Start-Process powershell.exe -Verb RunAs -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`""
    exit
}

Write-Host "==========================================" -ForegroundColor Cyan
Write-Host " CAI DAT NVM, NODE.JS 22.23+ & PNPM (WIN) " -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan

# 1. Kiem tra & Cai dat NVM for Windows
$nvmCmd = Get-Command nvm -ErrorAction SilentlyContinue
if (-not $nvmCmd) {
    Write-Host "`n[1/4] Dang cai dat NVM for Windows qua winget..." -ForegroundColor Yellow
    winget install -e --id CoreyButler.NVMforWindows --accept-source-agreements --accept-package-agreements --silent
    
    # Load lai Environment Variables trong phien lam viec hien tai
    $env:NVM_HOME = [System.Environment]::GetEnvironmentVariable("NVM_HOME", "User")
    if (-not $env:NVM_HOME) { $env:NVM_HOME = [System.Environment]::GetEnvironmentVariable("NVM_HOME", "Machine") }
    $env:NVM_SYMLINK = [System.Environment]::GetEnvironmentVariable("NVM_SYMLINK", "User")
    if (-not $env:NVM_SYMLINK) { $env:NVM_SYMLINK = [System.Environment]::GetEnvironmentVariable("NVM_SYMLINK", "Machine") }
    
    $machinePath = [System.Environment]::GetEnvironmentVariable("Path", "Machine")
    $userPath = [System.Environment]::GetEnvironmentVariable("Path", "User")
    $env:Path = "$machinePath;$userPath;$env:NVM_HOME;$env:NVM_SYMLINK"
} else {
    Write-Host "`n[1/4] NVM for Windows da duoc cai dat." -ForegroundColor Green
}

# 2. Cai dat Node.js 22 (>= 22.23)
Write-Host "`n[2/4] Dang cai dat Node.js 22 (>= 22.23)..." -ForegroundColor Yellow
nvm install 22

# 3. Kich hoat Node 22 va set default
Write-Host "`n[3/4] Dang kich hoat va set default Node.js 22..." -ForegroundColor Yellow
nvm use 22

# 4. Cai dat PNPM
Write-Host "`n[4/4] Dang cai dat / cap nhat PNPM..." -ForegroundColor Yellow
$pnpmCmd = Get-Command pnpm -ErrorAction SilentlyContinue
if (-not $pnpmCmd) {
    powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "iwr -useb https://get.pnpm.io/install.ps1 | iex"
    $env:PNPM_HOME = [System.Environment]::GetEnvironmentVariable("PNPM_HOME", "User")
    if ($env:PNPM_HOME) {
        $env:Path = "$env:PNPM_HOME;$env:PNPM_HOME\bin;$env:Path"
    }
} else {
    Write-Host "PNPM da duoc cai dat." -ForegroundColor Green
}

# 5. Cau hinh PowerShell Profile de them alias
$profilePath = $PROFILE
if (-not (Test-Path -Path $profilePath)) {
    $profileDir = Split-Path -Parent $profilePath
    if (-not (Test-Path -Path $profileDir)) {
        New-Item -ItemType Directory -Path $profileDir -Force | Out-Null
    }
    New-Item -ItemType File -Path $profilePath -Force | Out-Null
}
$profileContent = Get-Content -Path $profilePath -Raw -ErrorAction SilentlyContinue
if ($profileContent -notmatch 'function node22') {
    Add-Content -Path $profilePath -Value "`n# Node.js, NVM & PNPM Aliases`nfunction node22 { nvm use 22 }`nfunction node-lts { nvm use lts }`n"
}

Write-Host "`n==========================================" -ForegroundColor Green
Write-Host "  THIET LAP HOAN TAT! Kiem tra phien ban: " -ForegroundColor Green
Write-Host "==========================================" -ForegroundColor Green
nvm list
Write-Host "Node version: $(node -v)" -ForegroundColor Green
Write-Host "NPM version:  $(npm -v)" -ForegroundColor Green
Write-Host "PNPM version: $(pnpm -v 2>$null)" -ForegroundColor Green

Write-Host "`nNhan phim bat ky de thoat..."
[void][System.Console]::ReadKey()
