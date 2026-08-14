# Permite que iPhone/Android en la misma Wi-Fi accedan al backend y Keycloak
# Ejecutar PowerShell COMO ADMINISTRADOR

$rules = @(
  @{ Name = "Transporte Backend 8080"; Port = 8080 },
  @{ Name = "Transporte Keycloak 8180"; Port = 8180 }
)

foreach ($r in $rules) {
  $existing = Get-NetFirewallRule -DisplayName $r.Name -ErrorAction SilentlyContinue
  if ($existing) {
    Write-Host "Regla ya existe: $($r.Name)" -ForegroundColor Yellow
    continue
  }
  New-NetFirewallRule `
    -DisplayName $r.Name `
    -Direction Inbound `
    -LocalPort $r.Port `
    -Protocol TCP `
    -Action Allow `
    -Profile Private,Domain | Out-Null
  Write-Host "Regla creada: $($r.Name) puerto $($r.Port)" -ForegroundColor Green
}

Write-Host ""
Write-Host "Listo. Pruebe desde el iPhone en Safari:" -ForegroundColor Cyan
$ip = (Get-NetIPAddress -AddressFamily IPv4 | Where-Object { $_.IPAddress -match '^192\.168\.' } | Select-Object -First 1).IPAddress
if ($ip) {
  Write-Host "  http://${ip}:8080/api/health"
  Write-Host "  http://${ip}:8180"
}
