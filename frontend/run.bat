@echo off
set "PATH=C:\src\flutter\bin;C:\Users\chait\AppData\Local\Android\sdk\platform-tools;%PATH%"

REM Forward PC port 5000 to connected Android phones over USB
adb reverse tcp:5000 tcp:5000 >nul 2>&1

echo Running Flutter app on your device...
flutter run %*
