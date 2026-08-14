# Diseño funcional — Cajero y Admin empresa

Documento de referencia para entrega docente y evolución del sistema.

---

## 1. Operador / Cajero — Estado actual vs requerido

| Capacidad | ¿Lo hace hoy? | Cómo funciona ahora | Mejora propuesta |
|-----------|---------------|---------------------|------------------|
| Registrar venta | **Sí** | `/cajero` → elegir viaje → mapa asientos → nombre + cédula → confirmar | Formulario multi-pasajero (ver §5) |
| Asignar asientos | **Sí** | `SeatMap` en `PanelCajero.tsx`; 1 clic = 1 asiento | Vincular cada asiento a un pasajero |
| Consultar pasajeros | **No** | No hay pantalla ni API de listado | Nueva pestaña **Pasajeros** (ver §4) |
| Gestionar viajes del día | **Parcial** | Solo lista viajes de **hoy** fijo | Filtro por **fecha**, **bus**, estado |
| Cancelar viajes | **No** (correcto) | Cajero no cancela viajes | Mantener fuera del cajero |
| Cancelar boletos | **No** | Schema preparado (`CA1–CA3`) | Fase posterior; solo admin |
| Reserva excepcional | **No** | Tabla + rol en BD; sin UI ni API | Formulario aparte (ver §3) |
| Exportar Excel/PDF | **No** | — | Desde listado pasajeros (ver §4) |

### Flujo actual del cajero

```
Login (Keycloak)
    → Panel cajero (/cajero)
        → Viajes de HOY de su empresa
        → Botón "Vender boletos"
    → Panel venta (/cajero/venta/:id)
        → Mapa asientos (solo su empresa, API autenticada)
        → 1 comprador (nombre + cédula) para N asientos
        → Equipaje extra opcional
        → Comprobante imprimible
```

**Lo que falta en UX:** tabs (Ventas | Pasajeros | Viajes), filtro de fecha, ver manifest por viaje.

---

## 2. Administrador de empresa — Estado actual vs requerido

| Capacidad | ¿Lo hace hoy? | Detalle |
|-----------|---------------|---------|
| Crear buses | **Sí** | Tab Buses en `/admin` |
| Programar viajes | **Sí** | Tab Viajes; origen/destino fijos Bluefields–Managua |
| Gestionar operadores | **Sí** | Tab **Operadores** en `/admin`: alta en Keycloak + MySQL |
| Consultar reportes | **No** | Sin pantalla de ventas |
| Estadísticas de ocupación | **No** | Vista `v_cupos_viaje` existe en BD; sin UI |
| Perfil empresa (logo, teléfono) | **Sí** | Tab **Mi empresa** + URL logo con preview |
| Foto del bus | **Sí** | URL opcional al crear/editar bus en tab Flota |
| Permisos especiales | **Parcial** | Roles Keycloak; sin UI para asignar `RESERVA_EXCEPCIONAL` |

### Admin propuesto (pestañas)

```
/admin
├── Mi empresa      → logo, teléfono, correo, tarifa equipaje
├── Flota           → buses (+ foto opcional fase 2)
├── Viajes          → programar + filtro fecha
├── Operadores      → listar cajeros de la empresa (solo lectura Keycloak o CRUD simple)
├── Pasajeros       → mismo listado que cajero, con más filtros
└── Reportes        → ocupación %, ventas del día, exportar
```

---

## 3. Reserva excepcional — ¿Formulario aparte o el mismo?

**Recomendación: formulario aparte**, no modificar el de venta normal.

| Aspecto | Venta normal | Reserva excepcional |
|---------|--------------|---------------------|
| Quién | Cualquier cajero | Solo rol `RESERVA_EXCEPCIONAL` o admin |
| Para quién | Público en terminal | Funcionario gobierno, empleado empresa, casos autorizados |
| Pago | Inmediato | **Sin pago**; asiento queda `RESERVADO_EXCEPCIONAL` |
| Datos | Comprador + asientos | Nombre, cédula, **motivo obligatorio**, fecha expiración |
| Conversión | — | Luego se convierte en venta o expira |

### UX propuesta

En `PanelCajero`, botón secundario **"Reserva excepcional"** (visible solo si `hasRole(RESERVA_EXCEPCIONAL)`):

1. Mismo mapa de asientos (asientos ya reservados/vendidos bloqueados)
2. Campos: nombre, cédula, teléfono, **motivo** (textarea), expira en X horas
3. No pide pago ni equipaje
4. Asiento pasa a naranja en mapa (`RESERVADO_EXCEPCIONAL`)

**Backend:** `POST /api/reservas-excepcionales` (nuevo servicio; entidad ya existe).

**Quién tiene el rol en demo:** asignar a `admin.wendelyn` o crear `supervisor.wendelyn` en Keycloak.

---

## 4. Lista de pasajeros + exportación

### Fuente de datos

Cada **boleto** = 1 fila en el manifiesto (asiento + pasajero).

Hoy `boleto` no tiene nombre propio; hereda `venta.comprador_nombre`. Con multi-pasajero (§5), cada boleto tendrá su propio nombre/cédula.

### API propuesta

```
GET /api/pasajeros/manifiesto?fecha=2026-06-25&viajeId=3&busId=
```

Respuesta por fila:

| Campo | Ejemplo |
|-------|---------|
| viajeId, hora, origen, destino | — |
| numeroAsiento | 12 |
| pasajeroNombre | Juan Pérez |
| pasajeroCedula | 001-120678-0001A |
| esMenor | false |
| codigoVenta | V-1-173... |
| estadoBoleto | ACTIVO |
| operador | cajero.wendelyn |

### Pantalla cajero — tab **Pasajeros**

- Filtros: **fecha** (default hoy), **viaje** (dropdown), **bus** (opcional)
- Tabla sorteable
- Botones: **Exportar Excel** (CSV/SheetJS), **Exportar PDF** (jsPDF o imprimir HTML)

### Regla de listado

| Modo compra | Cómo aparece en lista |
|-------------|----------------------|
| 2 boletos, 1 comprador (actual) | **2 filas** mismo nombre/cédula, asientos distintos |
| 2 boletos, 2 pasajeros (nuevo) | **2 filas** nombres/cédulas distintos |
| Reserva excepcional | 1 fila estado "Reservado" sin venta |

---

## 5. Múltiples pasajeros — diseño de datos

### Problema actual

Una venta = un `comprador_nombre` + N boletos. La lista no distingue quién va en cada asiento.

### Solución recomendada (mínimo cambio BD)

Agregar a tabla `boleto`:

```sql
ALTER TABLE boleto ADD COLUMN pasajero_nombre VARCHAR(150) NULL;
ALTER TABLE boleto ADD COLUMN pasajero_cedula VARCHAR(30) NULL;
ALTER TABLE boleto ADD COLUMN es_menor BOOLEAN NOT NULL DEFAULT FALSE;
ALTER TABLE boleto ADD COLUMN edad INT NULL;
```

- Si no se llenan → copiar de `venta.comprador_*` (compatibilidad)
- `venta.comprador_*` = **adulto responsable / pagador** (obligatorio si hay menores)

### Formulario de venta — dos modos

**Modo simple (default):** como ahora — un nombre para todos los asientos.

**Modo detallado:** toggle *"Registrar cada pasajero"*:

```
Asiento 12 → [Nombre] [Cédula] [ ] Menor de 18
Asiento 13 → [Nombre] [Cédula] [x] Menor de 18  Edad: 14
─────────────────────────────────────────────
Responsable / pagador: [Nombre adulto] [Cédula]
Total: C$ 700 (2 boletos)
```

Validación: cantidad de filas pasajero = cantidad de asientos seleccionados.

---

## 6. Hora Nicaragua (12 horas)

Nicaragua usa reloj de **12 h con AM/PM**:

| BD (24h) | Mostrar |
|----------|---------|
| 06:00 | 6:00 AM |
| 12:00 | 12:00 PM (mediodía) |
| 13:00 | 1:00 PM |
| 00:30 | 12:30 AM |

**Implementado en:** `frontend/src/utils/formato.ts` → `formatearHoraNicaragua()`.

En formularios de programar viaje: selector 12h o input con AM/PM; el backend sigue guardando `TIME` en 24h.

---

## 7. Paradas, ETA y Google Maps

| Funcionalidad | Complejidad | Recomendación |
|---------------|-------------|---------------|
| Paradas en ruta (El Rama, Nueva Guinea…) | Media | Fase 2: tabla `parada`, `viaje_parada` con orden y hora estimada |
| "Próxima parada" en consulta pública | Media | Fase 3; requiere viaje `EN_CURSO` + GPS o horario fijo |
| Google Maps tiempo real | **Alta** | Fase 4; costo API, GPS en bus, no necesario para MVP entrega docente |

**Para el docente:** documentar como *"roadmap"* — el MVP cubre venta terminal; tracking es extensión natural tipo FlixBus.

Alternativa económica fase 2: paradas **fijas con horario estimado** (sin GPS), calculado al programar el viaje.

---

## 8. Prioridad de implementación (entrega docente)

### Fase A — Antes de presentar (1–2 días)
- [x] Hora 12h Nicaragua en toda la UI
- [x] Filtro fecha en panel cajero
- [x] Tab Pasajeros + manifiesto básico (API + tabla)
- [x] Export CSV (Excel abre CSV)
- [x] PDF / imprimir manifiesto
- [x] Admin: editar perfil empresa (Mi empresa)

### Fase B — Impresiona al evaluador (2–3 días)
- [x] Multi-pasajero en formulario venta
- [x] Admin: reporte ocupación simple (% vendido por viaje)
- [x] Reserva excepcional (formulario + API)

### Fase C — Post-entrega
- [x] Logo empresa (URL + preview en admin)
- [x] Foto bus (URL opcional)
- [x] Paradas fijas Bluefields–Managua (5 paradas, horarios estimados)
- [x] Google Maps (enlace + iframe embed en consulta y admin)
- [x] Gestión operadores UI
- [ ] PDF manifiesto profesional
- [ ] GPS en tiempo real

---

## 9. Cancelaciones — política

| Actor | Puede cancelar |
|-------|----------------|
| Cajero | **No** viajes; opcionalmente anular boleto mismo día (fase B) |
| Admin empresa | Cancelar viaje (solo si 0 ventas) o anular boletos |
| Público | Nunca en línea |

Coherente con regla de negocio: *no hay reservas online* → cancelaciones son operación interna supervisada.
