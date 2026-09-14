@echo off
rem Double-click to run CineScope in Chrome with the OMDb key from api_keys.json
title CineScope - Starting
cd /d "%~dp0"
set "FLUTTER_CMD=flutter"
if exist "%USERPROFILE%\Downloads\sdk\flutter\bin\flutter.bat" (
  set "FLUTTER_CMD=%USERPROFILE%\Downloads\sdk\flutter\bin\flutter.bat"
)

echo.
echo Starting CineScope...
echo The first release build can take a few minutes. Chrome will open when it is ready.
echo Using Flutter: %FLUTTER_CMD%
echo.

if not exist api_keys.json (
  echo ERROR: api_keys.json was not found.
  echo Create it from api_keys.example.json, then add your OMDb API key.
  pause
  exit /b 1
)

call "%FLUTTER_CMD%" run -d chrome --release --dart-define-from-file=api_keys.json
if errorlevel 1 (
  echo.
  echo CineScope could not start. Read the error shown above.
)
pause
