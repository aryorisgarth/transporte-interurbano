# Diseño consolidado de base de datos

Documento de decisiones de diseño. Script ejecutable: [database-schema.sql](database-schema.sql).

---

## Principios aplicados

1. **Una sola fuente de verdad** — el esquema vive en Liquibase (`db/changelog/`).
2. **Integridad en MySQL** — FK, UNIQUE y CHECK donde el motor lo permite.
3. **Reglas de negocio en backend** — fechas de venta, permisos, concurrencia.
4. **Sin reserva por defecto** — estado `RESERVADO_EXCEPCIONAL` solo vía permiso y tabla `reserva_excepcional`.
5. **Preparado para Keycloak** — `usuario.keycloak_id` nullable; auth local u OAuth.

---

## Mejoras respecto al esquema inicial

| Área | Antes | Ahora |
|------|-------|-------|
| Bus | Solo `capacidad` | `filas` + CHECK capacidad par |
| Asientos | UNIQUE por número | + UNIQUE `(bus_id, fila, posicion)` |
| Viaje | Solo tarifa boleto | + `tarifa_equipaje_extra` opcional por viaje |
| Empresa | — | `tarifa_equipaje_extra` default por empresa |
| Venta | Sin folio | `codigo` UNIQUE + `cantidad_boletos` |
| Boleto | — | `incluye_equipaje` (1 equipaje por boleto) |
| Viaje_asiento | Sin concurrencia | `version` (@Version JPA) + `updated_at` |
| Reserva excepcional | Sin estado | ENUM `ACTIVA/CONVERTIDA/CANCELADA/EXPIRADA` |
| Usuario | password obligatorio | password **o** keycloak_id |
| Consulta pública | Query manual | Vista `v_cupos_viaje` |
| Totales venta | Solo app | CHECK `total = subtotal_boletos + subtotal_equipaje` |
| Equipaje extra | — | CHECK `monto_total = monto_unitario * cantidad` |

---

## Tablas (12)

```
empresa
rol ── usuario_rol ── usuario
bus ── asiento_bus
viaje ── viaje_asiento ── boleto ── venta ── equipaje_extra
              └── reserva_excepcional
v_cupos_viaje (vista)
```

---

## Reglas de negocio ↔ columnas

| Regla | Implementación en BD |
|-------|----------------------|
| Sin reserva normal | No hay estado `RESERVADO` en flujo estándar |
| Compra múltiple a un nombre | `venta` (comprador) + N filas en `boleto` |
| Tarifa única | `viaje.tarifa`; CHECK `monto >= 0` en boleto |
| 1 equipaje por boleto | `boleto.incluye_equipaje = TRUE` |
| Equipaje extra de pago | Tabla `equipaje_extra` ligada a `venta` |
| Layout ventana/pasillo | `asiento_bus.posicion` ENUM + capacidad par |
| Un asiento = una venta activa | UNIQUE `boleto.viaje_asiento_id` |
| Dos cajeros, mismo asiento | `viaje_asiento.version` (optimistic lock) |

---

## Vista `v_cupos_viaje`

Agrega cupos por viaje para consulta pública sin lógica repetida en Java:

- `asientos_disponibles`
- `asientos_vendidos`
- `asientos_reservados`

Filtra empresas activas. Solo viajes con asientos instanciados.

---

## Tarifa de equipaje extra (jerarquía)

```
1. viaje.tarifa_equipaje_extra  (si no es NULL)
2. empresa.tarifa_equipaje_extra (default 100.00)
```

El backend resuelve esto en `VentaService` si el cajero no envía monto unitario.

---

## Folio de venta

`venta.codigo` — UNIQUE, generado en backend (ej. `V-{empresaId}-{timestamp}`).

Impresión de boleto: **codigo + comprador + lista de asientos**.

---

## Migraciones Liquibase

| Archivo | Contenido |
|---------|-----------|
| `db/changelog/db.changelog-master.yaml` | Changelog maestro |
| `db/changelog/changes/001-schema-consolidado.sql` | DDL completo + vista |
| `db/changelog/changes/002-changelog-roles.yaml` | Roles (YAML) |
| `db/changelog/changes/003-datos-demo.sql` | Datos demo |

**Importante:** si ya aplicaste Flyway o un esquema anterior, resetea la BD:

```sql
DROP DATABASE transporte_bluefields;
CREATE DATABASE transporte_bluefields;
```

Luego `mvn spring-boot:run` — Liquibase aplica todos los changesets.

Ver [Sesion 4 – Liquibase](sesiones/SESION-04.md).

---

## Próximo paso (Semana 1 del plan)

Con la BD consolidada, iniciar desarrollo por capas:

1. CRUD `empresa` validado contra este esquema
2. CRUD `bus` con generación de `asiento_bus`
3. Health + Swagger

Ver [PLAN-DE-FORMACION.md](PLAN-DE-FORMACION.md) sesión 1.
