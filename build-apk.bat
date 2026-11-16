@echo off
setlocal
set "ROOT=%~dp0"
if not defined GODOT_BIN set "GODOT_BIN=godot"
where "%GODOT_BIN%" >nul 2>nul
if errorlevel 1 (
  echo Godot 4 executable not found. Set GODOT_BIN to its full path.
  exit /b 1
)
for /f "delims=" %%V in ('"%GODOT_BIN%" --version') do set "VERSION=%%V"
if not "%VERSION:~0,2%"=="4." (
  echo Godot 4 required. Found %VERSION%
  exit /b 1
)
if not exist "%ROOT%build" mkdir "%ROOT%build"
"%GODOT_BIN%" --headless --editor --path "%ROOT%" --import
if errorlevel 1 exit /b 1
"%GODOT_BIN%" --headless --path "%ROOT%" --quit
if errorlevel 1 exit /b 1
"%GODOT_BIN%" --headless --path "%ROOT%" --export-debug Android "%ROOT%build\tak_khat.apk"
if errorlevel 1 exit /b 1
if not exist "%ROOT%build\tak_khat.apk" (echo Export did not create APK.& exit /b 1)
echo Created %ROOT%build\tak_khat.apk
