# ==============================================================================
# Install-WSL-Docker.ps1
# Cai dat WSL2 + Ubuntu, sau do cai Docker Engine ben trong WSL
#
# Chay trong PowerShell Administrator:
#   powershell -ExecutionPolicy Bypass -File "F:\tools\Install-WSL-Docker.ps1"
#
# Hoac click doi Install-WSL-Docker.bat
# ==============================================================================

# Tu dong xin quyen Administrator neu chua co
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "Dang yeu cau quyen Administrator..." -ForegroundColor Yellow
    Start-Process powershell.exe -Verb RunAs -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`""
    exit
}

$TOOLS_DIR = Split-Path -Parent $MyInvocation.MyCommand.Path
$DOCKER_SCRIPT = Join-Path $TOOLS_DIR "setup-docker-wsl.sh"

function Write-Step { param([string]$msg) Write-Host "`n[$([char]0x25B6)] $msg" -ForegroundColor Cyan }
function Write-OK   { param([string]$msg) Write-Host "  [OK] $msg" -ForegroundColor Green }
function Write-Warn { param([string]$msg) Write-Host "  [WARN] $msg" -ForegroundColor Yellow }
function Write-Err  { param([string]$msg) Write-Host "  [ERR] $msg" -ForegroundColor Red }

Write-Host "=============================================" -ForegroundColor Cyan
Write-Host "   CAI DAT WSL2 + UBUNTU + DOCKER ENGINE    " -ForegroundColor Cyan
Write-Host "=============================================" -ForegroundColor Cyan

# ==============================================================================
# BUOC 1: Kiem tra Windows Version (WSL2 can Windows 10 2004+ / Win11)
# ==============================================================================
Write-Step "1/6 Kiem tra phien ban Windows"
$build = [System.Environment]::OSVersion.Version.Build
if ($build -ge 19041) {
    Write-OK "Windows Build $build - hop le cho WSL2"
} else {
    Write-Err "Windows Build $build qua cu. Can >= 19041 (Windows 10 2004)"
    exit 1
}

# ==============================================================================
# BUOC 2: Bat tinh nang Windows Optional Features
# ==============================================================================
Write-Step "2/6 Bat tinh nang VirtualMachinePlatform & WSL"

$wslFeature = Get-WindowsOptionalFeature -Online -FeatureName Microsoft-Windows-Subsystem-Linux -ErrorAction SilentlyContinue
$vmFeature   = Get-WindowsOptionalFeature -Online -FeatureName VirtualMachinePlatform -ErrorAction SilentlyContinue

$needReboot = $false

if ($wslFeature.State -ne "Enabled") {
    Write-Host "  Dang bat Microsoft-Windows-Subsystem-Linux..." -ForegroundColor Yellow
    Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Windows-Subsystem-Linux -NoRestart -All | Out-Null
    $needReboot = $true
    Write-OK "Da bat Microsoft-Windows-Subsystem-Linux"
} else {
    Write-OK "Microsoft-Windows-Subsystem-Linux da bat"
}

if ($vmFeature.State -ne "Enabled") {
    Write-Host "  Dang bat VirtualMachinePlatform..." -ForegroundColor Yellow
    Enable-WindowsOptionalFeature -Online -FeatureName VirtualMachinePlatform -NoRestart -All | Out-Null
    $needReboot = $true
    Write-OK "Da bat VirtualMachinePlatform"
} else {
    Write-OK "VirtualMachinePlatform da bat"
}

if ($needReboot) {
    Write-Warn "Can KHOI DONG LAI may truoc khi tiep tuc."
    Write-Host "`n  Sau khi reboot, chay lai script nay de tiep tuc cai Ubuntu + Docker." -ForegroundColor Yellow
    Write-Host "`n  Nhan Enter de reboot ngay, hoac Ctrl+C de huy..." -ForegroundColor Yellow
    Read-Host
    Restart-Computer -Force
    exit
}

# ==============================================================================
# BUOC 3: Cai dat / Cap nhat WSL kernel
# ==============================================================================
Write-Step "3/6 Cap nhat WSL kernel (wsl --update)"
try {
    wsl.exe --update --web-download 2>&1 | ForEach-Object { Write-Host "  $_" }
    Write-OK "WSL kernel da duoc cap nhat"
} catch {
    Write-Warn "Khong cap nhat duoc WSL kernel qua web, thu tiep."
}

# Dat WSL2 lam mac dinh
wsl.exe --set-default-version 2 2>&1 | Out-Null
Write-OK "WSL default version = 2"

# ==============================================================================
# BUOC 4: Cai dat Ubuntu (distro mac dinh)
# ==============================================================================
Write-Step "4/6 Cai dat Ubuntu (WSL distro)"

$installedDistros = wsl.exe --list --quiet 2>&1
$ubuntuInstalled = $installedDistros | Where-Object { $_ -match "Ubuntu" }

if ($ubuntuInstalled) {
    Write-OK "Ubuntu da duoc cai dat: $($ubuntuInstalled -join ', ')"
} else {
    Write-Host "  Dang cai Ubuntu qua winget..." -ForegroundColor Yellow
    winget install -e --id Canonical.Ubuntu.2204 --accept-source-agreements --accept-package-agreements --silent
    if ($LASTEXITCODE -ne 0) {
        Write-Warn "winget that bai, thu wsl --install..."
        wsl.exe --install -d Ubuntu-22.04 --web-download
    }
    Write-OK "Ubuntu-22.04 da duoc cai dat"
    Write-Warn "Lan dau mo Ubuntu, Windows se yeu cau dat username/password. Hay lam theo huong dan."
}

# ==============================================================================
# BUOC 5: Khoi dong Ubuntu lan dau (khoi tao)
# ==============================================================================
Write-Step "5/6 Khoi dong Ubuntu lan dau"

$distros = wsl.exe --list --quiet 2>&1 | Where-Object { $_ -match "Ubuntu" }
if (-not $distros) {
    Write-Warn "Chua thay Ubuntu trong danh sach WSL. Thu khoi dong tay:"
    Write-Host "  wsl --install -d Ubuntu-22.04" -ForegroundColor Yellow
} else {
    Write-OK "Distro san co: $($distros -join ', ')"

    # Kiem tra xem Ubuntu da khoi tao chua (co /etc/os-release)
    $testResult = wsl.exe -d Ubuntu-22.04 -- bash -c "cat /etc/os-release 2>/dev/null | head -1" 2>&1
    if ($testResult -match "NAME") {
        Write-OK "Ubuntu da khoi tao xong"
    } else {
        Write-Warn "Ubuntu co the chua hoan tat khoi tao lan dau."
        Write-Host "  Vui long mo Ubuntu tu Start Menu, dat username/password, sau do chay lai script nay." -ForegroundColor Yellow
    }
}

# ==============================================================================
# BUOC 6: Copy setup-docker-wsl.sh vao WSL va chay
# ==============================================================================
Write-Step "6/6 Cai Docker Engine ben trong Ubuntu WSL"

if (-not (Test-Path $DOCKER_SCRIPT)) {
    Write-Err "Khong tim thay: $DOCKER_SCRIPT"
    Write-Host "  File setup-docker-wsl.sh phai nam cung thu muc voi script nay." -ForegroundColor Yellow
    exit 1
}

# Convert duong dan Windows sang WSL path
$wslScriptPath = "/tmp/setup-docker-wsl.sh"
Write-Host "  Dang copy setup-docker-wsl.sh vao WSL..." -ForegroundColor Yellow
$wslToolsDir = wsl.exe -d Ubuntu-22.04 -- bash -c "wslpath '$($TOOLS_DIR.Replace('\','\\'))'" 2>&1
if ($LASTEXITCODE -eq 0 -and $wslToolsDir) {
    $wslDockerScript = "$wslToolsDir/setup-docker-wsl.sh"
    Write-Host "  WSL path: $wslDockerScript" -ForegroundColor Gray
    wsl.exe -d Ubuntu-22.04 -- bash -c "chmod +x '$wslDockerScript' && '$wslDockerScript'"
} else {
    # Fallback: copy qua /tmp
    $content = Get-Content -Path $DOCKER_SCRIPT -Raw
    $content = $content -replace "`r`n", "`n"
    wsl.exe -d Ubuntu-22.04 -- bash -c "cat > $wslScriptPath << 'WSLEOF'
$content
WSLEOF
chmod +x $wslScriptPath && $wslScriptPath"
}

Write-Host "`n=============================================" -ForegroundColor Green
Write-Host "   HOAN TAT! Kiem tra lai:" -ForegroundColor Green
Write-Host "   wsl -d Ubuntu-22.04 -- docker version" -ForegroundColor Green
Write-Host "=============================================" -ForegroundColor Green
