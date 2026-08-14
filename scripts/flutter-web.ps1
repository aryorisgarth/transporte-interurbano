# Flutter Web - evita pantalla blanca (CanvasKit / CDN bloqueado)
#
# Desde la raiz del repo:
#   .\scripts\flutter-web.ps1
#
# Requiere Keycloak en 8180 y backend en 8080 para login y paneles.

$ErrorActionPreference = "Stop"
$Root = Split-Path -Parent $PSScriptRoot
Set-Location "$Root\mobile"

$KeycloakHealth = "http://127.0.0.1:8180/realms/transporte-bluefields"
$BackendHealth = "http://127.0.0.1:8080/api/health"

function Test-Url([string]$Url, [int]$TimeoutSec = 3) {
    try {
        $null = Invoke-WebRequest -Uri $Url -UseBasicParsing -TimeoutSec $TimeoutSec
        return $true
    } catch {
        return $false
    }
}

Write-Host ""
Write-Host "=== Flutter Web — app completa (modular) ===" -ForegroundColor Cyan
Write-Host ""

# --- Keycloak (obligatorio para login) ---
if (-not (Test-Url $KeycloakHealth)) {
    Write-Host "Keycloak no responde en 8180. Iniciando Docker..." -ForegroundColor Yellow
    Set-Location $Root
    docker compose up -d
    Write-Host "Esperando Keycloak (hasta 60 s)..." -ForegroundColor Gray
    $ok = $false
    for ($i = 0; $i -lt 30; $i++) {
        Start-Sleep -Seconds 2
        if (Test-Url $KeycloakHealth) { $ok = $true; break }
    }
    Set-Location "$Root\mobile"
    if (-not $ok) {
        Write-Host ""
        Write-Host "ERROR: Keycloak no levanto en http://127.0.0.1:8180" -ForegroundColor Red
        Write-Host "  1. Verifique Docker Desktop encendido" -ForegroundColor Yellow
        Write-Host "  2. Ejecute: docker compose up -d" -ForegroundColor Yellow
        Write-Host "  3. Revise logs: docker logs transporte-keycloak" -ForegroundColor Yellow
        exit 1
    }
    Write-Host "Keycloak OK" -ForegroundColor Green
} else {
    Write-Host "Keycloak OK  -> http://127.0.0.1:8180" -ForegroundColor Green
}

# --- Backend (aviso si falta) ---
if (-not (Test-Url $BackendHealth)) {
    Write-Host "Backend NO responde en 8080 (consulta/login API fallaran)" -ForegroundColor Yellow
    Write-Host "  En otra terminal:" -ForegroundColor Gray
    Write-Host "    cd backend" -ForegroundColor Gray
    Write-Host "    `$env:DB_PORT='3307'; `$env:DB_PASSWORD='root'; mvn spring-boot:run" -ForegroundColor Gray
} else {
    Write-Host "Backend OK  -> http://127.0.0.1:8080" -ForegroundColor Green
}

Write-Host ""
Write-Host "Flutter:   http://127.0.0.1:5050" -ForegroundColor Green
Write-Host "Login:     admin.global / password" -ForegroundColor Gray
Write-Host "NO use http://0.0.0.0 en el navegador" -ForegroundColor Yellow
Write-Host ""

flutter pub get
flutter run -d chrome `
  --no-web-resources-cdn `
  --web-port=5050 `
  --web-launch-url=http://127.0.0.1:5050/ `
  --web-define=API_BASE=http://127.0.0.1:8080
