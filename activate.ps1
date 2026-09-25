# Kich hoat moi truong Node.js & Git Portable cho session PowerShell hien tai
$ToolsDir = Split-Path -Parent $MyInvocation.MyCommand.Path
if (-not $ToolsDir) { $ToolsDir = $PSScriptRoot }
if (-not $ToolsDir) { $ToolsDir = "F:\tools" }

$NodeDir = Join-Path $ToolsDir "nodejs"
$GitDir  = Join-Path $ToolsDir "git\cmd"

# Xoa GIT_DIR neu dang set sai (gay loi "not a git repository")
if ($env:GIT_DIR) { Remove-Item Env:\GIT_DIR -ErrorAction SilentlyContinue }
if ($env:GIT_WORK_TREE) { Remove-Item Env:\GIT_WORK_TREE -ErrorAction SilentlyContinue }

# Dam bao PATH co cac thu muc can thiet (tranh trung lap)
$currentPaths = $env:Path -split ';' | Where-Object { $_.Trim() -ne "" }
$newPaths = @($NodeDir, $GitDir) + ($currentPaths | Where-Object {
    ($_ -ne $NodeDir) -and ($_ -ne $GitDir)
})
$env:Path = $newPaths -join ';'

Write-Host "====================================================" -ForegroundColor Cyan
Write-Host "  Moi truong Node.js & Git Portable da san sang!" -ForegroundColor Cyan
Write-Host "====================================================" -ForegroundColor Cyan
try { Write-Host "Node: $(node -v 2>&1)"    -ForegroundColor Green } catch { Write-Host "Node: KHONG TIM THAY" -ForegroundColor Red }
try { Write-Host "NPM:  v$(npm -v 2>&1)"   -ForegroundColor Green } catch { Write-Host "NPM:  KHONG TIM THAY" -ForegroundColor Red }
try { Write-Host "Git:  $(git --version 2>&1)" -ForegroundColor Green } catch { Write-Host "Git:  KHONG TIM THAY" -ForegroundColor Red }
Write-Host "====================================================" -ForegroundColor Cyan
