@echo off
rem Launches SignalRGB's MCP server from the newest installed app version.
rem SignalRGB ships SignalRgbMcp.exe inside a version-specific folder
rem (%LOCALAPPDATA%\VortxEngine\app-<version>\Signal-x64\), so a config that
rem points at the exe directly breaks on every app update. This wrapper
rem resolves the newest installed version at launch time instead.
rem
rem Reference it from claude_desktop_config.json or `claude mcp add`:
rem   cmd /c C:\path\to\signalrgb-mcp.cmd
setlocal enabledelayedexpansion
set "BASE=%LOCALAPPDATA%\VortxEngine"
set "EXE="
for /f "delims=" %%D in ('dir /b /ad /o:-d "%BASE%\app-*" 2^>nul') do (
  if not defined EXE if exist "%BASE%\%%D\Signal-x64\SignalRgbMcp.exe" set "EXE=%BASE%\%%D\Signal-x64\SignalRgbMcp.exe"
)
if not defined EXE (
  echo SignalRgbMcp.exe not found under %BASE% 1>&2
  exit /b 1
)
"%EXE%" %*
