@echo off
set "PATH=C:\src\flutter\bin;%PATH%"
cd /d "%~dp0"
echo Running Flutter app on Chrome...
flutter run -d chrome %*
