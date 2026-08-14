# Ejecutar Flutter en iPhone (misma red Wi-Fi que la laptop)
#
# Requisitos previos:
#   1. docker compose up -d          (MySQL + Keycloak)
#   2. Backend en la laptop:         cd backend; mvn spring-boot:run
#   3. iPhone y laptop en la MISMA Wi-Fi
#   4. Firewall Windows: permitir puertos 8080 y 8180 (ver abajo)

$wifiIp = (
  Get-NetIPAddress -AddressFamily IPv4 -ErrorAction SilentlyContinue |
  Where-Object {
    $_.IPAddress -notmatch '^127\.' -and
    $_.IPAddress -notmatch '^169\.254\.' -and
    $_.PrefixOrigin -ne 'WellKnown'
  } |
  Sort-Object InterfaceMetric |
  Select-Object -First 1 -ExpandProperty IPAddress
)

if (-not $wifiIp) {
  Write-Host "No se detecto IP Wi-Fi. Use ipconfig y edite mobile/lib/config/api_config.dart (phoneUrl)." -ForegroundColor Yellow
  $wifiIp = "192.168.0.6"
}

Write-Host ""
Write-Host "=== Flutter en iPhone ===" -ForegroundColor Cyan
Write-Host "IP laptop:  $wifiIp"
Write-Host "Backend:    http://${wifiIp}:8080"
Write-Host "Keycloak:   http://${wifiIp}:8180"
Write-Host ""
Write-Host "Pruebe en Safari del iPhone:" -ForegroundColor Yellow
Write-Host "  http://${wifiIp}:8080/api/health"
Write-Host "  http://${wifiIp}:8180"
Write-Host ""
Write-Host "Login demo: cajero.wendelyn / password"
Write-Host ""

Set-Location "$PSScriptRoot\..\mobile"
flutter pub get
flutter run --dart-define=API_BASE="http://${wifiIp}:8080"
