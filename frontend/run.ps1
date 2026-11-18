$env:Path = "C:\src\flutter\bin;C:\Users\chait\AppData\Local\Android\sdk\platform-tools;" + $env:Path

# Forward port 5000 from PC to USB-connected Android phone
& "C:\Users\chait\AppData\Local\Android\sdk\platform-tools\adb.exe" reverse tcp:5000 tcp:5000 2>$null

Write-Host "Starting Flutter app on C:\src\flutter SDK..." -ForegroundColor Green
flutter run $args
