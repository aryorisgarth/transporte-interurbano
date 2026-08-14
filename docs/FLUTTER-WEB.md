# Flutter Web — Sistema Transporte B–M

Aplicación web modular en Flutter, **equivalente funcional** a `frontend/` (React).  
La versión React **se mantiene**; ambas consumen el mismo backend Spring Boot + Keycloak.

## Estructura modular (`mobile/lib/`)

```
lib/
├── app.dart                    # MaterialApp.router + Provider
├── main.dart
├── core/
│   ├── api/                    # Espejo de frontend/src/shared/api/
│   ├── auth/                   # JWT + AuthProvider (Keycloak password grant)
│   ├── config/
│   ├── models/
│   ├── router/                 # go_router — mismas rutas que React
│   ├── theme/
│   └── utils/
├── features/
│   ├── auth/                   # Login
│   ├── consulta/               # Landing, búsqueda pública, detalle viaje
│   ├── cajero/                 # Terminal: viajes, venta, manifiesto
│   └── admin/                  # Plataforma + cooperativa (9 secciones)
└── shared/
    ├── layout/                 # PublicScaffold, OperativeShell (sidebar)
    └── widgets/                # SectionCard, StatCard, SeatGrid, …
```

## Rutas (idénticas a React)

| Ruta | Módulo |
|------|--------|
| `/` | Landing |
| `/consulta` | Búsqueda pública |
| `/consulta/viaje/:id` | Detalle + mapa asientos |
| `/acceso/login` | Login Keycloak |
| `/acceso/denegado` | Acceso denegado (rol) |
| `/cajero` | Viajes del día |
| `/cajero/pasajeros` | Manifiesto |
| `/cajero/venta/:id` | Venta en mostrador |
| `/admin` | Panel admin (sidebar interno) |

## Requisitos

- Flutter SDK ≥ 3.11
- Backend en `http://127.0.0.1:8080`
- Keycloak en `http://127.0.0.1:8180`

## Ejecutar en web

Desde la raíz del repo:

```powershell
.\scripts\flutter-web.ps1
```

O manualmente:

```powershell
cd mobile
flutter pub get
flutter run -d chrome `
  --no-web-resources-cdn `
  --web-port=5050 `
  --web-define=API_BASE=http://127.0.0.1:8080
```

Abrir: **http://127.0.0.1:5050**

## Keycloak — conexión y errores

Flutter Web llama al **backend** (`POST /api/auth/token`), que reenvía a Keycloak. Así se evita CORS del navegador hacia el puerto 8180 (React usa proxy de Vite; Flutter usa este endpoint).

### Arranque mínimo

```powershell
# Desde la raíz del repo
docker compose up -d

# Esperar ~20–30 s y verificar:
Invoke-WebRequest http://127.0.0.1:8180/realms/transporte-bluefields -UseBasicParsing
```

Debe responder **200**. Luego el backend:

```powershell
cd backend
$env:DB_PORT="3307"
$env:DB_PASSWORD="root"
mvn spring-boot:run
```

Y Flutter:

```powershell
.\scripts\flutter-web.ps1
```

El script `flutter-web.ps1` ahora **inicia Docker automáticamente** si Keycloak no responde.

### Error: «No se pudo conectar con Keycloak»

| Causa | Solución |
|-------|----------|
| Docker apagado | Abrir Docker Desktop → `docker compose up -d` |
| Keycloak aún iniciando | Esperar 30 s; ver `docker logs transporte-keycloak` |
| Puerto 8180 ocupado | `docker ps` — debe verse `transporte-keycloak` en `0.0.0.0:8180` |
| Backend caído | Otro error en API; Keycloak puede estar bien — revise 8080 |

### Verificar token manualmente

```powershell
$body = "client_id=transporte-api&grant_type=password&username=admin.global&password=password"
Invoke-WebRequest -Uri "http://127.0.0.1:8180/realms/transporte-bluefields/protocol/openid-connect/token" `
  -Method POST -ContentType "application/x-www-form-urlencoded" -Body $body
```

Respuesta **200** con `access_token` = Keycloak OK.

## Credenciales demo

| Usuario | Rol |
|---------|-----|
| `admin.global` | Admin plataforma |
| `admin.wendelyn` | Admin cooperativa |
| `cajero.wendelyn` | Cajero Bluefields |

Contraseña: `password`

## Paridad con React (implementado)

- **Admin plataforma**: KPIs, lista buscable, wizard 2 pasos (cooperativa + admin), panel detalle con tabs
- **Admin CRUD**: buses, viajes, operadores — crear, editar, desactivar
- **Paradas**: mapa interactivo (`flutter_map`), CRUD completo
- **Reportes ingresos**: campos corregidos, 5 pestañas, export CSV ventas
- **Manifiesto**: filtros viaje/bus, export CSV, hint imprimir
- **Cajero venta**: modo detallado por asiento, reserva excepcional, comprobante PDF
- **Consulta detalle**: avatar empresa, mapa ruta, tarifa USD referencia
- **404 / acceso denegado**: páginas estilizadas

## React vs Flutter

| | React (`frontend/`) | Flutter Web (`mobile/`) |
|--|---------------------|-------------------------|
| Puerto dev | 5173 | 5050 |
| Stack | Vite + MUI + TS | Flutter + Material 3 |
| API | `shared/api/` | `core/api/transporte_api.dart` |
| Auth | Keycloak ROPC | Igual |
| Móvil nativo | — | Misma base (`mobile/`) |

## Notas

- Los archivos legacy en `lib/screens/` siguen presentes; el entrypoint usa `features/`.
- En Android emulator use `API_BASE=http://10.0.2.2:8080` (default sin define).
