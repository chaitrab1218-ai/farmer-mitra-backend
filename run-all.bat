@echo off
set "PATH=C:\src\flutter\bin;C:\Users\chait\AppData\Local\Android\sdk\platform-tools;%PATH%"

REM Forward PC port 5000 to connected Android phones over USB
adb reverse tcp:5000 tcp:5000 >nul 2>&1

echo ==========================================
echo Starting Krushi Mitra Backend API...
echo ==========================================
start "Krushi Mitra Backend" cmd /k "cd /d "%~dp0backend" && npm start"

echo ==========================================
echo Starting Krushi Mitra Flutter App...
echo ==========================================
cd /d "%~dp0frontend"
flutter run %*
