$ErrorActionPreference = "Stop"

$realm = "transporte-bluefields"
$kc = "transporte-keycloak"

function Invoke-Kcadm {
    param([string[]]$KcArgs)

    # kcadm escribe mensajes informativos en stderr; PowerShell no debe tratarlos como error fatal
    $prev = $ErrorActionPreference
    $ErrorActionPreference = "Continue"
    try {
        $output = docker exec $kc /opt/keycloak/bin/kcadm.sh @KcArgs 2>&1 | ForEach-Object {
            if ($_ -is [System.Management.Automation.ErrorRecord]) { $_.ToString() } else { $_ }
        }
        if ($LASTEXITCODE -and $LASTEXITCODE -ne 0) {
            throw "kcadm fallo (codigo $LASTEXITCODE): $($output -join ' ')"
        }
        return $output
    } finally {
        $ErrorActionPreference = $prev
    }
}

$users = @(
    @{ u = "cajero.martinez.mga"; fn = "Cajero"; ln = "Martinez Managua"; em = "cajero.mga@martinez.com"; roles = @("CAJERO") },
    @{ u = "admin.costacaribe"; fn = "Admin"; ln = "Costa Caribe"; em = "admin@costacaribe.com"; roles = @("ADMIN_EMPRESA", "RESERVA_EXCEPCIONAL") },
    @{ u = "cajero.costacaribe.bfs"; fn = "Cajero"; ln = "CC Bluefields"; em = "cajero.bfs@costacaribe.com"; roles = @("CAJERO") },
    @{ u = "cajero.costacaribe.mga"; fn = "Cajero"; ln = "CC Managua"; em = "cajero.mga@costacaribe.com"; roles = @("CAJERO") },

    @{ u = "admin.ramadorada"; fn = "Admin"; ln = "Rama Dorada"; em = "admin@ramadorada.com"; roles = @("ADMIN_EMPRESA") },
    @{ u = "cajero.ramadorada.bfs"; fn = "Cajero"; ln = "RD Bluefields"; em = "cajero.bfs@ramadorada.com"; roles = @("CAJERO") },
    @{ u = "cajero.ramadorada.mga"; fn = "Cajero"; ln = "RD Managua"; em = "cajero.mga@ramadorada.com"; roles = @("CAJERO") },

    @{ u = "admin.atlanticosur"; fn = "Admin"; ln = "Atlantico Sur"; em = "admin@atlanticosur.com"; roles = @("ADMIN_EMPRESA") },
    @{ u = "cajero.atlanticosur.bfs"; fn = "Cajero"; ln = "AS Bluefields"; em = "cajero.bfs@atlanticosur.com"; roles = @("CAJERO") },
    @{ u = "cajero.atlanticosur.mga"; fn = "Cajero"; ln = "AS Managua"; em = "cajero.mga@atlanticosur.com"; roles = @("CAJERO") },

    @{ u = "admin.corredorcentro"; fn = "Admin"; ln = "Corredor Centro"; em = "admin@corredorcentro.com"; roles = @("ADMIN_EMPRESA", "RESERVA_EXCEPCIONAL") },
    @{ u = "cajero.corredorcentro.bfs"; fn = "Cajero"; ln = "CCN Bluefields"; em = "cajero.bfs@corredorcentro.com"; roles = @("CAJERO") },
    @{ u = "cajero.corredorcentro.mga"; fn = "Cajero"; ln = "CCN Managua"; em = "cajero.mga@corredorcentro.com"; roles = @("CAJERO") }
)

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "   SEED DE USUARIOS KEYCLOAK" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

if (-not (docker ps -q -f "name=$kc")) {
    throw "Contenedor $kc no esta en ejecucion. Ejecute: docker compose up -d"
}

Write-Host "Conectando a Keycloak..." -ForegroundColor Yellow

Invoke-Kcadm @(
    "config",
    "credentials",
    "--server", "http://localhost:8180",
    "--realm", "master",
    "--user", "admin",
    "--password", "admin"
)

Write-Host "Conexion correcta." -ForegroundColor Green
Write-Host ""

foreach ($user in $users) {

    Write-Host "Procesando: $($user.u)" -ForegroundColor Cyan

    $exists = Invoke-Kcadm @(
        "get",
        "users",
        "-r", $realm,
        "-q", "username=$($user.u)"
    )

    if ($exists -match '"username"') {
        Write-Host "  Ya existe - actualizando password y roles..." -ForegroundColor DarkGray
        $existsText = ($exists | Out-String)
        $userId = $null
        if ($existsText -match '"id"\s*:\s*"([0-9a-f-]+)"') {
            $userId = $Matches[1]
        }
        if ($userId) {
            Invoke-Kcadm @(
                "set-password",
                "-r", $realm,
                "--userid", $userId,
                "--new-password", "password"
            ) | Out-Null
            foreach ($role in $user.roles) {
                Invoke-Kcadm @(
                    "add-roles",
                    "-r", $realm,
                    "--uusername", $user.u,
                    "--rolename", $role
                ) | Out-Null
            }
            Write-Host "  Sincronizado." -ForegroundColor Green
        }
        continue
    }

    Write-Host "  Creando usuario..." -ForegroundColor Yellow

    $createOut = Invoke-Kcadm @(
        "create",
        "users",
        "-r", $realm,
        "-s", "username=$($user.u)",
        "-s", "enabled=true",
        "-s", "emailVerified=true",
        "-s", "firstName=$($user.fn)",
        "-s", "lastName=$($user.ln)",
        "-s", "email=$($user.em)"
    )

    Write-Host $createOut

    $createText = ($createOut | Out-String)
    $userId = $null
    if ($createText -match 'Created new user with id ''([0-9a-f-]+)''') {
        $userId = $Matches[1]
    }

    if (-not $userId) {
        Write-Host "  ERROR: No se pudo crear $($user.u)" -ForegroundColor Red
        continue
    }

    Write-Host "  ID: $userId" -ForegroundColor DarkGray

    Invoke-Kcadm @(
        "set-password",
        "-r", $realm,
        "--userid", $userId,
        "--new-password", "password"
    )

    Write-Host "  Password configurado." -ForegroundColor Green

    foreach ($role in $user.roles) {

        Write-Host "  Asignando rol: $role" -ForegroundColor Yellow

        Invoke-Kcadm @(
            "add-roles",
            "-r", $realm,
            "--uusername", $user.u,
            "--rolename", $role
        )
    }

    Write-Host "  Usuario creado correctamente." -ForegroundColor Green
    Write-Host ""
}

Write-Host "========================================" -ForegroundColor Green
Write-Host "   USUARIOS DEMO SINCRONIZADOS" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
