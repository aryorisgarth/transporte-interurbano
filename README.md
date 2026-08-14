# Sistema de Gestión de Transporte Interurbano

Plataforma **multi-tenant** para cooperativas de bus en la ruta **Bluefields – Managua** (Nicaragua).

- Consulta pública de cupos (sin login)
- Venta presencial en terminal (cajero)
- Administración por cooperativa con aislamiento de datos
- Stack: **Spring Boot 3 · MySQL · Liquibase · Keycloak · React · Flutter · MUI / Material**

```
SISTEMA-DE-GESTION-TRANSPORTE/
├── backend/          API REST + reglas de negocio
├── frontend/         React + Vite + Material UI (web original)
├── mobile/           Flutter — web completa + móvil (consulta/cajero/admin)
├── docs/             Arquitectura, demo, validaciones, FLUTTER-WEB.md
├── infra/keycloak/   Realm importable
├── scripts/          Utilidades (start-demo.ps1)
└── docker-compose.yml
```

---

## Inicio rápido

### Con script (Windows)

```powershell
.\scripts\start-demo.ps1
```

### Manual

1. **Docker** (MySQL 3307 + Keycloak 8180):
   ```powershell
   docker compose up -d
   ```
2. **Backend**:
   ```powershell
   cd backend
   $env:DB_PORT="3307"
   $env:DB_PASSWORD="root"
   mvn spring-boot:run
   ```
3. **Frontend**:
   ```powershell
   cd frontend
   npm install
   npm run dev
   ```
4. **Web Flutter** (alternativa modular a React — misma API):
   ```powershell
   .\scripts\flutter-web.ps1
   ```
5. **Web React** (versión original):
   ```powershell
   cd frontend
   npm install
   npm run dev
   ```

| URL | Descripción |
|-----|-------------|
| http://localhost:5173 | Aplicación web React |
| http://127.0.0.1:5050 | Aplicación web Flutter |
| http://localhost:8080/swagger-ui.html | API Swagger |
| http://localhost:8180/admin | Keycloak (admin/admin) |

---

## Usuarios demo

Contraseña: **`password`**

| Usuario | Rol | Alcance |
|---------|-----|---------|
| *(público)* | — | Consulta cupos de todas las empresas |
| `cajero.wendelyn` | CAJERO | Venta solo Wendelyn |
| `cajero.martinez` | CAJERO | Venta solo Martínez |
| `admin.wendelyn` | ADMIN_EMPRESA | Admin solo Wendelyn (sin selector) |
| `admin.martinez` | ADMIN_EMPRESA | Admin solo Martínez |
| `admin.global` | ADMIN_GENERAL | Super-admin plataforma (con selector) |

**Guía de presentación docente:** [docs/DEMO.md](docs/DEMO.md)

---

## Modelo multi-tenant

| Capa | Quién | Qué ve |
|------|-------|--------|
| Consulta pública | Pasajero | Todas las cooperativas (tablero terminal) |
| Cajero / Admin empresa | Personal Wendelyn o Martínez | Solo su tenant |
| Admin global | Operador plataforma | Todas las cooperativas |

El backend valida tenant en cada operación (`OperadorContext`). Un cajero de Wendelyn **no puede** vender ni consultar viajes de Martínez.

---

## Reglas de negocio

- Sin reserva online; venta día anterior o mismo día en terminal
- Comprador sin cuenta (nombre + cédula)
- Tarifa única por viaje; N asientos por comprador
- Equipaje extra opcional
- Asientos ventana/pasillo; capacidad par

---

## Documentación

| Documento | Contenido |
|-----------|-----------|
| [ENTREGA-DOCENTE.md](docs/ENTREGA-DOCENTE.md) | **Material docente** (diagramas, CI, export PNG) |
| [DEMO.md](docs/DEMO.md) | **Guía entrega docente** (guión 5 min) |
| [diagramas/ARQUITECTURA.md](docs/diagramas/ARQUITECTURA.md) | Diagramas Mermaid (capas, flujos) |
| [diagramas/MODELO-JDL.md](docs/diagramas/MODELO-JDL.md) | Modelo ER desde JDL |
| [ARQUITECTURA-Y-STACK.md](docs/ARQUITECTURA-Y-STACK.md) | Stack y capas |
| [mobile/README.md](../mobile/README.md) | App Flutter (todos los roles) |
| [GUIA-FLUTTER.md](docs/GUIA-FLUTTER.md) | **Aprender Flutter** con este proyecto |
| [VALIDACIONES.md](docs/VALIDACIONES.md) | Reglas validadas |
| [DISENO-BD.md](docs/DISENO-BD.md) | Esquema consolidado |
| PDF raíz | Requisitos del proyecto |

---

## Variables de entorno

**Backend** (`application-dev.yml`):

| Variable | Default | Descripción |
|----------|---------|-------------|
| `DB_PORT` | 3307 | Puerto MySQL |
| `DB_PASSWORD` | root | Clave MySQL |

**Frontend** — copiar `frontend/.env.example` → `frontend/.env`:

| Variable | Default |
|----------|---------|
| `VITE_API_URL` | *(vacío en dev)* |
| `VITE_KEYCLOAK_URL` | http://localhost:8180/realms/transporte-bluefields |

---

## Tecnologías

| Capa | Versión |
|------|---------|
| Java | 17 |
| Spring Boot | 3.2.x |
| MySQL | 8 |
| Keycloak | 24 |
| React | 18 |
| Vite | 5 |
