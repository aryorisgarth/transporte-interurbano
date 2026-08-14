# Frontend – Transporte Bluefields

Aplicación **React + Vite + Material UI** que consume la API del backend.

## Requisitos

- Node.js 18+
- Backend en `http://localhost:8080`
- Keycloak en `http://localhost:8180` (para ventas con cajero)

## Instalación

```bash
cd frontend
npm install
npm run dev
```

Abrir http://localhost:5173

## Pantallas

| Ruta | Descripción |
|------|-------------|
| `/` | Inicio — presentación del sistema |
| `/consulta` | Consulta pública de viajes y cupos |
| `/consulta/viaje/:id` | Detalle, paradas, mapa y asientos |
| `/acceso` | Acceso personal (cajero / admin) |
| `/acceso/login` | Login Keycloak |
| `/cajero` | Panel cajero — viajes del día |
| `/cajero/venta/:id` | Venta presencial |
| `/admin` | Administración de cooperativa (incl. tab Operadores) |

Guía de demostración: [docs/DEMO.md](../docs/DEMO.md)

## API consumida

- `GET /api/publico/viajes?origen=&destino=&fecha=`
- `GET /api/publico/viajes/{id}`
- `GET /api/externo/tarifa-referencia-usd?monto=`
- `POST /api/ventas` (Bearer JWT cajero)

Swagger: http://localhost:8080/swagger-ui.html

## Usuarios demo

Contraseña para todos: `password`

- `cajero.wendelyn`, `cajero.martinez` — venta
- `admin.wendelyn`, `admin.martinez` — admin empresa
- `admin.global` — admin plataforma

## Build producción

```bash
npm run build
npm run preview
```

Variable opcional: `VITE_API_URL` (URL base del backend si no usa proxy).
