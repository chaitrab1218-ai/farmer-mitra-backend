@echo off
set "PATH=%PATH%;C:\src\flutter\bin"
cd /d "%~dp0frontend"
flutter run %*
