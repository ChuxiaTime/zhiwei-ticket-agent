@echo off
chcp 65001 >nul
title Zhiwei Ticket Agent - Stop

echo Stopping Zhiwei Ticket Agent...
echo.

powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0scripts\stop-all.ps1"

echo.
pause
