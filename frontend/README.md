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

## Modo demo (Vercel / estático)

Para desplegar sin backend ni Keycloak, configure en Vercel (o en `.env.local`):

```bash
VITE_USE_MOCK=true
```

Con esto:
- La autenticación se simula (usuario demo: `demo@transporte.com`, rol admin plataforma).
- Las APIs devuelven datos de `src/mocks/mockData.ts` (empresas, buses, viajes, asientos, ventas, reportes).
- El flujo real con Keycloak se mantiene cuando `VITE_USE_MOCK` no está definida o es `false`.

Build demo local:

```bash
VITE_USE_MOCK=true npm run build
npm run preview
```
