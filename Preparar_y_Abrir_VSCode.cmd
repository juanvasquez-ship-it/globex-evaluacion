@echo off
setlocal
cd /d "%~dp0"
set "PSModulePath="
powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%~dp0preparar_entorno.ps1"
if errorlevel 1 pause
endlocal
