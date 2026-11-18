$env:Path = "C:\src\flutter\bin;C:\Users\chait\AppData\Local\Android\sdk\platform-tools;" + $env:Path

# Forward port 5000 to connected Android phone
& "C:\Users\chait\AppData\Local\Android\sdk\platform-tools\adb.exe" reverse tcp:5000 tcp:5000 2>$null

Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "Starting Backend API (Node.js + Neon DB)..." -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
Start-Process cmd -ArgumentList "/k cd /d `"$PSScriptRoot\backend`" && npm start"

Write-Host "==========================================" -ForegroundColor Green
Write-Host "Starting Flutter App..." -ForegroundColor Green
Write-Host "==========================================" -ForegroundColor Green
Set-Location "$PSScriptRoot\frontend"
flutter run $args
