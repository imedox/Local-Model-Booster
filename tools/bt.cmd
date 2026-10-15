@echo off
setlocal
rem Model-Booster tool launcher. Works from cmd.exe and PowerShell.
rem Usage: bt <tool> <args>     bt list     bt help <tool>
set "T=%~1"
if "%T%"=="" goto :list
if /i "%T%"=="list" goto :list
set "ALL=%*"
for /f "tokens=1,* delims= " %%a in ("%ALL%") do set "REST=%%b"
if /i "%T%"=="help" (
  powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0bt.ps1" -Help %REST%
  exit /b %errorlevel%
)
echo %T%| findstr /r /c:"[\\/:\.]" >nul
if not errorlevel 1 (
  echo invalid tool name: %T%
  exit /b 2
)
if not exist "%~dp0%T%.ps1" (
  echo unknown tool: %T%   ^(run: bt list^)
  exit /b 2
)
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0%T%.ps1" %REST%
exit /b %errorlevel%
:list
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0bt.ps1"
exit /b %errorlevel%
