# Comparativa JDL vs Liquibase / JPA

Referencia para [Sesion 7](sesiones/SESION-07.md).

## Entidades

| Entidad JDL | Tabla MySQL | Notas |
|-------------|-------------|-------|
| Empresa | `empresa` | + `tarifaEquipajeExtra` |
| Bus | `bus` | + `filas`, CHECK capacidad par |
| AsientoBus | `asiento_bus` | ENUM posicion |
| Viaje | `viaje` | + `tarifaEquipajeExtra`, `observaciones` |
| ViajeAsiento | `viaje_asiento` | + `version` optimistic lock |
| Venta | `venta` | + `codigo`, `cantidadBoletos` |
| Boleto | `boleto` | + `incluyeEquipaje`, UNIQUE asiento |
| EquipajeExtra | `equipaje_extra` | CHECK montos |
| ReservaExcepcional | `reserva_excepcional` | 1:1 con viaje_asiento |
| Usuario | `usuario` | + `keycloakId`, password nullable |
| Rol | `rol` | |
| (tabla puente) | `usuario_rol` | N:M |

## Relaciones JDL → FK

| JDL | Implementacion SQL |
|-----|------------------|
| `Empresa{bus}` → `Bus{empresa}` | `bus.empresa_id` |
| `Bus{asiento}` → `AsientoBus{bus}` | `asiento_bus.bus_id` CASCADE |
| `Viaje{viajeAsiento}` | `viaje_asiento.viaje_id` CASCADE |
| `AsientoBus{viajeAsiento}` | `viaje_asiento.asiento_bus_id` |
| `Venta{boleto}` | `boleto.venta_id` CASCADE |
| `Venta{operador}` → `Usuario` | `venta.operador_id` |
| `ViajeAsiento` 1:1 `ReservaExcepcional` | UNIQUE `viaje_asiento_id` |
| `Usuario` N:M `Rol` | `usuario_rol` |

## Enums

| JDL enum | MySQL ENUM |
|----------|------------|
| PosicionAsiento | VENTANA, PASILLO |
| EstadoAsientoViaje | DISPONIBLE, VENDIDO, CANCELADO, RESERVADO_EXCEPCIONAL |
| EstadoViaje | PROGRAMADO, EN_CURSO, COMPLETADO, CANCELADO |
| EstadoVenta | COMPLETADA, CANCELADA, PARCIALMENTE_CANCELADA |
| EstadoBoleto | ACTIVO, CANCELADO |
| EstadoReservaExcepcional | ACTIVA, CONVERTIDA, CANCELADA, EXPIRADA |

## Lo que JDL no modela (logica en Java)

Estos aspectos estan en **servicios**, no en JDL:

| Regla | Donde |
|-------|-------|
| Sin reserva por defecto | `VentaService`, `SecurityConfig` |
| Venta solo dia anterior/mismo dia | `VentaService.validarFechaVenta()` |
| Layout asientos ventana/pasillo | `AsientoLayoutUtil` |
| Compra multiple a un nombre | `VentaService.construirVenta()` |
| API externa tipo cambio | `TipoCambioExternoService` |
| Keycloak roles | `SecurityConfig` + realm JSON |

## Vista SQL (solo Liquibase)

`v_cupos_viaje` — consulta agregada de cupos; no es entidad JDL (correcto: es vista de lectura).

## Checklist de alineacion

- [x] 11 entidades JDL = 12 tablas (+ usuario_rol)
- [x] Relaciones 1:N coinciden con FK
- [x] N:M Usuario-Rol en ambos
- [x] Reserva excepcional 1:1
- [x] Campos consolidados sesion BD presentes en JDL

**Estado:** JDL alineado con esquema Liquibase consolidado (2026).
