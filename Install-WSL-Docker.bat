@echo off
:: Install-WSL-Docker.bat
:: Click doi de chay - tu dong xin quyen Administrator
echo Dang yeu cau quyen Administrator...
powershell -NoProfile -ExecutionPolicy Bypass -Command ^
  "Start-Process powershell -Verb RunAs -ArgumentList '-NoProfile -ExecutionPolicy Bypass -File ""%~dp0Install-WSL-Docker.ps1""'"
