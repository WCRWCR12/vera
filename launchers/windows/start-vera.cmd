@echo off
rem {{ASSISTANT_NAME}} on Telegram (Windows).
rem Double-click this file. A window opens: leave it open while you want {{ASSISTANT_NAME}} on your phone.
rem Close the window to stop. It only runs when you double-click it. Never add it to Startup.
setlocal
title {{ASSISTANT_NAME}} on Telegram (close this window to stop)
cd /d "%~dp0"
rem System folders first, per-user installs last, so nothing planted in a user folder shadows a system tool.
set "PATH=%SystemRoot%\System32;%SystemRoot%;%SystemRoot%\System32\WindowsPowerShell\v1.0;%PATH%;%USERPROFILE%\.local\bin;%USERPROFILE%\.bun\bin"

set "CLAUDE_EXE=%USERPROFILE%\.local\bin\claude.exe"
if not exist "%CLAUDE_EXE%" (
  echo.
  echo   The Claude command-line tool is not installed yet.
  echo   Open the Claude app, Code tab, open the Vera setup folder and say: set up Telegram
  echo.
  pause
  exit /b 1
)

if not exist "%USERPROFILE%\.claude\channels\telegram\.env" (
  echo.
  echo   {{ASSISTANT_NAME}} isn't connected to Telegram yet.
  echo   Open the Claude app, Code tab, open the Vera setup folder and say: set up Telegram
  echo   The bot token only ever goes into the small box Claude opens for you, never into a chat.
  echo.
  pause
  exit /b 1
)

rem Telegram safety rules live in vera-settings.json. Refuse to start if the file or key rules are missing.
if not exist "vera-settings.json" goto badsettings
findstr /L /C:"disableBypassPermissionsMode" "vera-settings.json" >nul || goto badsettings
findstr /L /C:"Edit(./.claude/**)" "vera-settings.json" >nul || goto badsettings
findstr /L /C:"Edit(./people.md)" "vera-settings.json" >nul || goto badsettings
findstr /L /C:"Read(~/.claude/channels/telegram/.env)" "vera-settings.json" >nul || goto badsettings
findstr /L /C:"Edit(~/.claude/channels/telegram/access.json)" "vera-settings.json" >nul || goto badsettings
findstr /L /C:"Bash(curl *)" "vera-settings.json" >nul || goto badsettings

if not exist "%USERPROFILE%\.claude\channels\telegram\inbox" mkdir "%USERPROFILE%\.claude\channels\telegram\inbox"

echo Starting {{ASSISTANT_NAME}} with Telegram. Leave this window open; close it to stop.
echo The first time, this window may ask you to log in or to trust this folder: press Enter to accept.
echo.
rem Only the Telegram inbox (photos, voice notes) is added to the assistant's reach. The token,
rem the allowlist and the pairing files next to it stay outside.
"%CLAUDE_EXE%" --settings "%~dp0vera-settings.json" --add-dir "%USERPROFILE%\.claude\channels\telegram\inbox" --channels plugin:telegram@claude-plugins-official --permission-mode default "You are {{ASSISTANT_NAME}}. Read CLAUDE.md and the files it lists, then wait for messages from Telegram. Reply to every Telegram message with the Telegram reply tool."
echo.
echo   {{ASSISTANT_NAME}} has stopped. Double-click start-vera to start again.
pause
exit /b 0

:badsettings
echo.
echo   vera-settings.json is missing or its safety rules were changed. Not starting.
echo   Ask Claude (in the Vera setup folder) to "repair my Vera install".
echo.
pause
exit /b 1
