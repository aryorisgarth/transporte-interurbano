# Población demo completa — 6 cooperativas
# Ejecutar desde la raíz del proyecto: .\scripts\poblar-demo.ps1

$ErrorActionPreference = "Stop"
$root = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
Set-Location $root

Write-Host "=== Transporte B-M — Poblacion demo ===" -ForegroundColor Cyan

# 1. Docker (MySQL + Keycloak)
Write-Host "`n[1/3] Verificando Docker..." -ForegroundColor Yellow
docker compose up -d
Start-Sleep -Seconds 5

# 2. Liquibase via reinicio del backend (aplica 016-seed-cooperativas.sql)
Write-Host "`n[2/3] Aplicando migraciones Liquibase (incluye semillas V16)..." -ForegroundColor Yellow
Write-Host "      Inicie el backend una vez para que Liquibase ejecute los changesets pendientes:"
Write-Host "      cd backend; `$env:DB_PORT='3307'; mvn spring-boot:run" -ForegroundColor Gray

$applySql = Read-Host "¿Ejecutar SQL V16 directamente en MySQL ahora? (s/N)"
if ($applySql -eq 's' -or $applySql -eq 'S') {
    $sqlPath = Join-Path $root "backend\src\main\resources\db\changelog\changes\016-seed-cooperativas.sql"
    Get-Content $sqlPath -Raw | docker exec -i transporte-mysql mysql -uroot -proot transporte_bluefields
    Write-Host "      SQL V16 aplicado." -ForegroundColor Green
}

# 3. Keycloak — usuarios nuevos (instalaciones existentes)
Write-Host "`n[3/3] Usuarios Keycloak..." -ForegroundColor Yellow
& (Join-Path $root "scripts\keycloak-seed-users.ps1")

Write-Host "`n=== Listo ===" -ForegroundColor Green
Write-Host @"

Cooperativas (6 total):
  1. Wendelyn Transporte     — admin.wendelyn / cajero.wendelyn / cajero.wendelyn.mga
  2. Martínez Líneas         — admin.martinez / cajero.martinez / cajero.martinez.mga
  3. Costa Caribe Express    — admin.costacaribe / cajero.costacaribe.bfs / .mga
  4. Rama Dorada Líneas      — admin.ramadorada / cajero.ramadorada.bfs / .mga
  5. Atlántico Sur Transporte — admin.atlanticosur / cajero.atlanticosur.bfs / .mga
  6. Corredor Centro SA      — admin.corredorcentro / cajero.corredorcentro.bfs / .mga

Plataforma: admin.global / password

Cada cooperativa tiene: 2 buses (50 asientos), viajes hoy/mañana, ventas demo y reservas.

"@
