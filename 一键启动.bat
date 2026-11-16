@echo off
chcp 65001 >nul
title Zhiwei Ticket Agent - Start

echo Starting Zhiwei Ticket Agent...
echo.

powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0scripts\start-all.ps1" %*

if errorlevel 1 (
    echo.
    echo Start failed. Check the logs under .run\logs.
)

echo.
pause
