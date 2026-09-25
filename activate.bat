@echo off
setlocal enabledelayedexpansion

set "TOOLS_DIR=%~dp0"
set "NODE_DIR=%TOOLS_DIR%nodejs"
set "GIT_CMD_DIR=%TOOLS_DIR%git\cmd"

:: Xoa bien GIT_DIR neu ton tai de tranh lam hong git repo
set "GIT_DIR="
set "GIT_WORK_TREE="

set "PATH=%NODE_DIR%;%GIT_CMD_DIR%;%PATH%"

echo ====================================================
echo  Da kich hoat moi truong Node.js & Git Portable
echo ====================================================
node -v
git --version
echo ====================================================
echo Mo terminal voi moi truong da san sang...
cmd /k
