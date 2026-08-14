# Arranque demo — Transporte Bluefields
# Uso: .\scripts\start-demo.ps1

$ErrorActionPreference = "Stop"
$Root = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)

Write-Host "=== Transporte Bluefields — Demo ===" -ForegroundColor Cyan
Write-Host ""

# 1. Docker
Write-Host "[1/3] Iniciando MySQL + Keycloak..." -ForegroundColor Yellow
Set-Location $Root
docker compose up -d

Write-Host "      Esperando Keycloak (~25 s)..." -ForegroundColor Gray
Start-Sleep -Seconds 25

# 2. Backend
Write-Host "[2/3] Iniciando backend (nueva ventana)..." -ForegroundColor Yellow
$backendCmd = @"
Set-Location '$Root\backend'
`$env:DB_PORT='3307'
`$env:DB_PASSWORD='root'
Write-Host 'Backend en http://localhost:8080' -ForegroundColor Green
mvn spring-boot:run
"@
Start-Process powershell -ArgumentList "-NoExit", "-Command", $backendCmd

Start-Sleep -Seconds 5

# 3. Frontend
Write-Host "[3/3] Iniciando frontend (nueva ventana)..." -ForegroundColor Yellow
$frontendCmd = @"
Set-Location '$Root\frontend'
if (-not (Test-Path node_modules)) { npm install }
Write-Host 'Frontend en http://localhost:5173' -ForegroundColor Green
npm run dev
"@
Start-Process powershell -ArgumentList "-NoExit", "-Command", $frontendCmd

Write-Host ""
Write-Host "Demo lista:" -ForegroundColor Green
Write-Host "  Frontend:  http://localhost:5173"
Write-Host "  Swagger:   http://localhost:8080/swagger-ui.html"
Write-Host "  Keycloak:  http://localhost:8180/admin"
Write-Host ""
Write-Host "Usuarios: cajero.wendelyn, cajero.martinez, admin.wendelyn, admin.martinez, admin.global — password: password"
Write-Host "Guia: docs\DEMO.md"
