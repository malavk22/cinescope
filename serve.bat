@echo off
rem Double-click to open the already-built CineScope instantly (no compiling).
rem After changing code, run run.bat once to rebuild, then use this again.
cd /d "%~dp0build\web"
if not exist main.dart.js (
  echo No build found. Run run.bat once first.
  pause
  exit /b
)
start "" /min powershell -NoProfile -Command "Start-Sleep 2; Start-Process 'http://localhost:8080'"
echo CineScope is running at http://localhost:8080  -  close this window to stop it.
python -m http.server 8080
