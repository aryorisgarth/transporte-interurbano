# Sesion 8 – Frontend React + fetch

## Objetivos

- Crear aplicacion React con Vite y Material UI
- Consumir la API REST del backend con `fetch`
- Pantalla publica de consulta de viajes y cupos
- Detalle con mapa de asientos por colores
- Panel cajero con login Keycloak y registro de venta

## Stack

| Herramienta | Uso |
|-------------|-----|
| Vite | Bundler y servidor de desarrollo |
| React 18 | UI por componentes |
| TypeScript | Tipos alineados con DTOs del backend |
| Material UI | Formularios, layout, feedback |
| React Router | Navegacion entre pantallas |

## Estructura

```
frontend/
├── src/
│   ├── api/
│   │   ├── client.ts          # Wrapper fetch + Bearer token
│   │   └── transporteApi.ts   # Endpoints tipados
│   ├── components/
│   │   └── SeatMap.tsx        # Mapa ventana/pasillo por fila
│   ├── pages/
│   │   ├── ConsultaPublica.tsx
│   │   ├── DetalleViaje.tsx
│   │   └── PanelCajero.tsx
│   ├── App.tsx
│   ├── main.tsx
│   └── theme.ts
├── vite.config.ts             # Proxy /api → localhost:8080
└── package.json
```

## Pantallas

### 1. Consulta publica (`/`)

Formulario origen / destino / fecha → `GET /api/publico/viajes`.

Lista de horarios con empresa, hora y cupos. Boton **Ver asientos** abre el detalle.

### 2. Detalle viaje (`/viaje/:id`)

`GET /api/publico/viajes/{id}` — mapa de asientos:

| Color | Estado |
|-------|--------|
| Verde | DISPONIBLE |
| Rojo | VENDIDO |
| Naranja | RESERVADO_EXCEPCIONAL |
| Gris | CANCELADO |

Opcional: referencia USD con `GET /api/externo/tarifa-referencia-usd?monto=350`.

### 3. Panel cajero (`/cajero/:id`)

1. Login contra Keycloak (password grant): `cajero.wendelyn` / `password`
2. Seleccion de asientos disponibles (toggle)
3. Datos del comprador (nombre, cedula, telefono)
4. Equipaje extra opcional
5. `POST /api/ventas` con header `Authorization: Bearer {token}`

El operador se resuelve en el backend desde el JWT (`OperadorContext`); no hace falta enviar `operadorId` en perfil `dev`.

## Arranque

```bash
# Terminal 1 – infra (MySQL + Keycloak)
docker compose up -d

# Terminal 2 – backend (perfil dev con Keycloak)
cd backend
mvn spring-boot:run

# Terminal 3 – frontend
cd frontend
npm install
npm run dev
```

Abrir: http://localhost:5173

**Sin Keycloak** (solo pruebas API): backend con `-Dspring-boot.run.profiles=local` y ventas sin token (requiere `operadorId` en el body).

## Proxy y CORS

- Vite proxy: peticiones a `/api/*` se reenvian a `http://localhost:8080`
- Keycloak token: peticion directa a `http://localhost:8180/.../token` (cliente `transporte-api`)
- Backend ya permite CORS desde `http://localhost:5173` (`WebConfig`)

## Demo rapida (datos seed)

Liquibase changeset `004-datos-viajes-demo` carga:

| Empresa | Bus | Viaje |
|---------|-----|-------|
| Wendelyn | W-01, 20 asientos | Bluefields→Managua hoy 06:00 y manana 14:00 |
| Martinez | M-01, 20 asientos | Bluefields→Managua hoy 07:30; Managua→Bluefields hoy 15:00 |

Tarifa: **C$ 350**. El frontend usa la fecha de **hoy** por defecto.

### Si ya tenias la BD con changesets 001-003

Solo reinicia el backend; Liquibase aplica el 004 automaticamente.

### Reset completo (Docker MySQL puerto 3307)

```bash
mysql -h 127.0.0.1 -P 3307 -u root -proot -e "DROP DATABASE IF EXISTS transporte_bluefields; CREATE DATABASE transporte_bluefields CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;"
cd backend && mvn spring-boot:run
```

## Flujo de demo (Sesion 8)

1. Buscar **Bluefields → Managua**, fecha **hoy** (ya viene por defecto)
2. Abrir un viaje y revisar mapa de asientos
3. Ir a **Panel cajero**, iniciar sesion
4. Seleccionar 2–3 asientos, completar comprador, registrar venta
5. Volver a consulta y confirmar que cupos bajaron

## Ejercicios propuestos

1. Mostrar mensaje cuando no hay viajes para la fecha
2. Deshabilitar venta si el token expiro (401)
3. Pagina `/cajero` sin viaje preseleccionado: elegir viaje desde lista
4. Mostrar subtotal boletos vs equipaje usando campos de `VentaResponse`

## Siguiente sesion

**Sesion 9** – IA aplicada al desarrollo (Cursor, prompts, revision de codigo).
