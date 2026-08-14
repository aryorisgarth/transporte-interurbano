# Flutter Web — modo demo estático (sin Keycloak ni backend)
#
# Desde la raiz del repo:
#   .\scripts\flutter-web-demo.ps1
#
# Equivalente a VITE_USE_MOCK=true en React.

$ErrorActionPreference = "Stop"
$Root = Split-Path -Parent $PSScriptRoot
Set-Location "$Root\mobile"

Write-Host ""
Write-Host "=== Flutter Web — MODO DEMO (USE_MOCK=true) ===" -ForegroundColor Cyan
Write-Host "Sin backend ni Keycloak. Datos estaticos en lib/mocks/" -ForegroundColor Gray
Write-Host ""
Write-Host "Flutter:   http://127.0.0.1:5050" -ForegroundColor Green
Write-Host "Usuario:   demo / cualquier contrasena" -ForegroundColor Gray
Write-Host ""

flutter pub get
flutter run -d chrome `
  --no-web-resources-cdn `
  --web-port=5050 `
  --web-launch-url=http://127.0.0.1:5050/ `
  --dart-define=USE_MOCK=true
