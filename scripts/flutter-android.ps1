# Flutter en emulador Android (Android Studio)
#
# Requisitos: Docker + backend Spring Boot corriendo en la PC

Set-Location "$PSScriptRoot\..\mobile"

Write-Host "Configurando JDK 17 (Gradle no soporta Java 25 de Android Studio)..." -ForegroundColor Yellow
flutter config --jdk-dir="C:\Program Files\Java\jdk-17"

Write-Host ""
Write-Host "=== Flutter Android Emulator ===" -ForegroundColor Cyan
Write-Host "API:      http://10.0.2.2:8080"
Write-Host "Keycloak: http://10.0.2.2:8180"
Write-Host ""
Write-Host "1. Abra Android Studio -> Device Manager -> inicie un emulador" -ForegroundColor Yellow
Write-Host "2. En la app use preset Emulador (10.0.2.2) si hace falta" -ForegroundColor Yellow
Write-Host ""

flutter pub get
flutter devices
Write-Host ""
flutter run --dart-define=API_BASE=http://10.0.2.2:8080
