# Firebase Setup Script
# Fuehre dieses Skript in einem neuen PowerShell-Fenster aus,
# sobald der Download fertig ist.

$firebasePath = "$env:LOCALAPPDATA\Programs\firebase-cli"
$env:PATH = "$firebasePath;$env:PATH"

Write-Host "Firebase CLI Version:" -ForegroundColor Cyan
& "$firebasePath\firebase.exe" --version

Write-Host ""
Write-Host "Firebase Login-Status pruefen..." -ForegroundColor Cyan
& "$firebasePath\firebase.exe" login:list

Write-Host ""
Write-Host "Falls nicht eingeloggt: firebase login wird gestartet..." -ForegroundColor Yellow
# & "$firebasePath\firebase.exe" login   # Kommentar entfernen falls noetig

Write-Host ""
Write-Host "FlutterFire configure starten..." -ForegroundColor Green
Set-Location "c:\Users\jarno\OneDrive\Desktop\sightseeing_collector"
dart pub global run flutterfire_cli:flutterfire configure --platforms=android,ios
