@echo off
title 1-Click Automated Installer (Qwen 3.8 + Bionic + Billion-Context)
cd /d "%~dp0"

echo ======================================================================
echo    STARTING 1-CLICK ALL-IN-ONE AUTOMATED INSTALLER...
echo ======================================================================
echo.

powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0install.ps1"

echo.
echo ======================================================================
echo Setup execution finished.
echo ======================================================================
pause
