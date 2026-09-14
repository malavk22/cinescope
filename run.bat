@echo off
rem Double-click to run CineScope in Chrome with the OMDb key from api_keys.json
cd /d "%~dp0"
flutter run -d chrome --release --dart-define-from-file=api_keys.json
pause
