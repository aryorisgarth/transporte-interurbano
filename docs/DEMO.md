# Guía de demostración — Entrega docente

Documento para presentar el **Sistema de Gestión de Transporte Interurbano Bluefields – Managua** en 5–10 minutos.

---

## Qué demuestra este proyecto

| Capacidad | Descripción |
|-----------|-------------|
| **Multi-tenant** | Varias cooperativas (Wendelyn, Martínez) en la misma plataforma, datos aislados |
| **Consulta pública** | Pasajero ve cupos de todas las empresas sin login; logos, paradas y mapa en detalle |
| **Venta presencial** | Cajero registra comprador (nombre + cédula), sin cuenta de pasajero |
| **Mapa de asientos** | Layout ventana/pasillo, venta de N asientos por comprador |
| **Seguridad** | Keycloak + JWT + roles; backend valida tenant en cada operación |
| **Stack profesional** | Spring Boot 3, MySQL, Liquibase, React, Docker |

---

## Arranque (Windows)

### Opción A — Script automático

```powershell
.\scripts\start-demo.ps1
```

### Opción B — Manual

```powershell
# 1. Infraestructura (esperar ~30 s Keycloak)
docker compose up -d

# 2. Backend
cd backend
$env:DB_PORT="3307"
$env:DB_PASSWORD="root"
mvn spring-boot:run

# 3. Frontend (otra terminal)
cd frontend
npm install
npm run dev
```

| Servicio | URL |
|----------|-----|
| Frontend | http://localhost:5173 |
| API / Swagger | http://localhost:8080/swagger-ui.html |
| Keycloak | http://localhost:8180/admin (admin / admin) |

---

## Usuarios de demostración

Contraseña para todos: **`password`**

| Usuario | Rol | Empresa | Uso en la demo |
|---------|-----|---------|----------------|
| *(sin login)* | — | — | Consulta pública |
| `cajero.wendelyn` | CAJERO | Wendelyn | Terminal **Bluefields** — solo salidas desde Bluefields |
| `cajero.wendelyn.mga` | CAJERO | Wendelyn | Terminal **Managua** — solo salidas desde Managua |
| `cajero.martinez` | CAJERO | Martínez | Terminal Bluefields |
| `admin.wendelyn` | ADMIN_EMPRESA | Wendelyn | Admin solo Wendelyn (sin selector) |
| `admin.martinez` | ADMIN_EMPRESA | Martínez | Admin solo Martínez |
| `admin.global` | ADMIN_GENERAL | — | Plataforma: crear cooperativas, selector de tenant, **sin venta de boletos** |

> **Importante:** `admin.global` no puede vender boletos (no tiene empresa asignada). Use la pestaña **Plataforma** para registrar cooperativas y el selector para administrar cada tenant. Para ventas use `cajero.*` o `admin.*` con empresa.

---

## Admin global — flujo recomendado

1. Iniciar sesión como `admin.global` / `password` → **Administración** → pestaña **Plataforma**
2. Ver **resumen agregado** (buses, operadores, viajes, boletos) — **sin lista de pasajeros**
3. Registrar cooperativa → **Asignar ADMIN_EMPRESA** (login Keycloak)
4. El **admin de empresa** (`admin.wendelyn`, etc.) registra **cajeros por terminal** (Bluefields o Managua)
5. Cajero solo ve viajes de **su terminal**; para ventas usar `cajero.wendelyn` (Bluefields) o `cajero.wendelyn.mga` (Managua)

### Cadena de permisos

```
ADMIN_GENERAL → crea cooperativa + ADMIN_EMPRESA
ADMIN_EMPRESA → crea CAJERO (con terminal fija)
CAJERO        → vende solo viajes que salen de su terminal
```

---

## Guión sugerido (5 minutos)

### 1. Consulta pública (1 min)

1. Abrir http://localhost:5173
2. Ir a **Consultar**
3. Buscar Bluefields → Managua, fecha de hoy
4. Mostrar **dos empresas** con horarios distintos y **logo** de cada cooperativa
5. Notar barra de ocupación (Wendelyn 6:00 AM ya tiene 2 asientos vendidos de demo)
6. Entrar al detalle de un viaje → **paradas en ruta**, mapa Google Maps, foto del bus, mapa de asientos

**Mensaje:** *“Como en una terminal física: el pasajero ve todas las cooperativas, pero no compra en línea.”*

### 2. Venta cajero Wendelyn (2 min)

1. **Acceso personal** → login `cajero.wendelyn`
2. Panel cajero → viajes de **hoy de Wendelyn**
3. **Vender boletos** → seleccionar 2 asientos
4. Datos comprador: nombre + cédula (sin cuenta)
5. Confirmar → **comprobante** (descargar PDF o imprimir)
6. Volver a consulta pública → cupos reducidos

**Mensaje:** *“El cajero solo opera su cooperativa; el backend rechaza ventas cruzadas.”*

### 3. Aislamiento multi-tenant (1 min)

1. Cerrar sesión
2. Login `cajero.martinez`
3. Mostrar que solo ve viajes de Martínez
4. (Opcional) Intentar URL de venta de Wendelyn → error de acceso

**Mensaje:** *“Mismo modelo que aerolíneas/trenes: back-office aislado por operador.”*

### 4. Administración (1 min)

1. Login `admin.wendelyn` → `/admin`
2. Mostrar **chip con nombre cooperativa** (sin dropdown)
3. Registrar bus (con foto URL opcional) o programar viaje
4. Tab **Operadores** → crear cajero demo en vivo (opcional)
5. Tab **Ruta / Paradas** → itinerario estimado según hora de salida
6. Cerrar sesión → `admin.global` → `/admin`
7. Mostrar **selector de cooperativa** (super-admin plataforma)

## Arquitectura multi-tenant (resumen)

```
┌─────────────────────────────────────────────────────────┐
│  CONSULTA PÚBLICA — todas las empresas (tablero terminal)│
└─────────────────────────────────────────────────────────┘
                            │
        ┌───────────────────┼───────────────────┐
        ▼                   ▼                   ▼
   Wendelyn              Martínez           (futuras)
   tenant aislado        tenant aislado
   cajero + admin        cajero + admin
        │                   │
        └─────────┬─────────┘
                  ▼
         ADMIN GENERAL (plataforma)
```

---

## Solución de problemas

| Problema | Solución |
|----------|----------|
| Login falla | Esperar Keycloak (~30 s tras `docker compose up`) |
| MySQL connection refused | Verificar puerto 3307 y `DB_PASSWORD=root` |
| Tablas vacías | Arrancar backend (Liquibase crea y carga datos) |
| Puerto 8080 ocupado | Cerrar instancia anterior de Spring Boot |
| Selector de empresa como admin Wendelyn | Cerrar sesión; usar `admin.wendelyn`, no `admin.global` |

---

## Alcance y fases futuras

**Implementado:** consulta (logos, paradas, mapa), venta multi-pasajero con **comprobante PDF**, reserva excepcional, admin buses/viajes/perfil/ocupación/paradas, multi-tenant, Keycloak, API USD referencia, **app Flutter completa** (público + cajero + admin), tests unitarios + CI.

**Fuera de alcance (documentado):** pagos en línea, upload de archivos (solo URL), GPS tiempo real.

**Material docente:** [ENTREGA-DOCENTE.md](ENTREGA-DOCENTE.md) · [diagramas/](diagramas/)

---

## Referencias técnicas

- [README](../README.md) — instalación
- [ENTREGA-DOCENTE.md](ENTREGA-DOCENTE.md) — diagramas y material de evaluación
- [Arquitectura y stack](ARQUITECTURA-Y-STACK.md)
- [Diagramas Mermaid](diagramas/ARQUITECTURA.md)
- [Validaciones](VALIDACIONES.md)
- PDF requisitos: `Sistema de Gestion de Transporte Interurbano Bluefields.pdf`
