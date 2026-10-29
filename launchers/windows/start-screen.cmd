@echo off
rem Vera Screen (Windows). Double-click: it starts on this computer only (127.0.0.1:5191) and opens
rem in your browser. Close this window to stop it. It never starts by itself.
setlocal
title Vera Screen (close this window to stop)
cd /d "%~dp0screen"
set "PY="
py -3 -c "import sys; sys.exit(0 if sys.version_info >= (3, 9) else 1)" >nul 2>&1 && set "PY=py -3"
if not defined PY python -c "import sys; sys.exit(0 if sys.version_info >= (3, 9) else 1)" >nul 2>&1 && set "PY=python"
if not defined PY (
  echo.
  echo   Vera Screen needs Python 3.9 or newer.
  echo   Open the Claude app, Code tab, open the Vera setup folder and say: set up Vera Screen
  echo.
  pause
  exit /b 1
)
%PY% -E -s server.py --open
if errorlevel 1 pause
