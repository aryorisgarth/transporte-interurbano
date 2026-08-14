# Validaciones del sistema

Reglas organizadas por módulo. Cada validación indica **dónde** debe aplicarse:

- **F** = Frontend (UX, formato)
- **B** = Backend Spring Boot (regla real)
- **DB** = MySQL (integridad de datos)

---

## Regla global: sin reservas

| # | Validación | F | B | DB |
|---|------------|---|---|-----|
| G1 | No existe flujo de pre-reserva para el público | ✓ | ✓ | — |
| G2 | Consulta pública es solo lectura (no modifica asientos) | ✓ | ✓ | — |
| G3 | Venta en terminal es el único camino normal a `VENDIDO` | — | ✓ | ✓ |
| G4 | Estado `RESERVADO_EXCEPCIONAL` solo con rol `RESERVA_EXCEPCIONAL` | ✓ | ✓ | ✓ |
| G5 | Venta permitida solo el **día anterior** o el **mismo día** del viaje | ✓ | ✓ | — |

---

## Módulo: Empresas

| # | Validación | F | B | DB |
|---|------------|---|---|-----|
| E1 | Nombre obligatorio | ✓ | ✓ | NOT NULL |
| E2 | Correo con formato válido (si se proporciona) | ✓ | ✓ | — |
| E3 | Solo admin general registra empresas | ✓ | ✓ | — |
| E4 | Empresa inactiva no aparece en consulta pública | — | ✓ | — |

---

## Módulo: Buses

| # | Validación | F | B | DB |
|---|------------|---|---|-----|
| BU1 | Capacidad mayor a 0 | ✓ | ✓ | CHECK |
| BU2 | Capacidad **par** (layout ventana/pasillo) | ✓ | ✓ | — |
| BU3 | Placa única en el sistema | ✓ | ✓ | UNIQUE |
| BU4 | Número interno único por empresa | ✓ | ✓ | UNIQUE compuesto |
| BU5 | Bus pertenece a la empresa del administrador | — | ✓ | FK |
| BU6 | Al crear bus se generan asientos automáticamente | — | ✓ | — |
| BU7 | Cada asiento tiene posición VENTANA o PASILLO | — | ✓ | ENUM |
| BU8 | Numeración secuencial sin duplicados por bus | — | ✓ | UNIQUE |

---

## Módulo: Viajes

| # | Validación | F | B | DB |
|---|------------|---|---|-----|
| V1 | Fecha y hora de salida obligatorias | ✓ | ✓ | NOT NULL |
| V2 | Tarifa única ≥ 0 (sin tarifa niño) | ✓ | ✓ | CHECK |
| V3 | Bus debe pertenecer a la misma empresa del viaje | — | ✓ | FK + lógica |
| V4 | Al programar viaje se crean `viaje_asiento` en estado DISPONIBLE | — | ✓ | — |
| V5 | Viaje cancelado no permite nuevas ventas | ✓ | ✓ | — |
| V6 | Temporada alta: misma hora puede tener varios buses (viajes independientes) | — | ✓ | — |
| V7 | Origen/destino por defecto Bluefields → Managua | ✓ | ✓ | DEFAULT |

---

## Módulo: Consulta pública

| # | Validación | F | B | DB |
|---|------------|---|---|-----|
| C1 | Fecha obligatoria en búsqueda | ✓ | ✓ | — |
| C2 | Solo muestra viajes en estado PROGRAMADO | — | ✓ | — |
| C3 | Muestra cantidad de asientos DISPONIBLES (no reserva) | ✓ | ✓ | — |
| C4 | Detalle de viaje muestra mapa de asientos con su estado | ✓ | ✓ | — |
| C5 | Endpoint público sin autenticación | — | ✓ | — |

---

## Módulo: Ventas (terminal)

| # | Validación | F | B | DB |
|---|------------|---|---|-----|
| VE1 | Comprador: nombre y cédula obligatorios | ✓ | ✓ | NOT NULL |
| VE2 | Teléfono opcional | ✓ | — | — |
| VE3 | Al menos un asiento seleccionado | ✓ | ✓ | — |
| VE4 | No permitir asientos duplicados en la misma venta | ✓ | ✓ | — |
| VE5 | Todos los asientos deben estar en estado DISPONIBLE | — | ✓ | — |
| VE6 | Asientos deben pertenecer al viaje indicado | — | ✓ | FK |
| VE7 | Operador debe pertenecer a la empresa del viaje | — | ✓ | — |
| VE8 | Venta es transaccional: falla si algún asiento ya fue vendido | — | ✓ | — |
| VE9 | Un comprador puede comprar N boletos a su nombre | ✓ | ✓ | — |
| VE10 | Tarifa por boleto = tarifa del viaje (sin descuentos ni niños) | — | ✓ | — |
| VE11 | Total = (tarifa × cantidad boletos) + equipaje extra | ✓ | ✓ | — |
| VE12 | Tras venta exitosa: asiento pasa a VENDIDO | — | ✓ | ✓ |

---

## Módulo: Equipaje

| # | Validación | F | B | DB |
|---|------------|---|---|-----|
| EQ1 | Cada boleto incluye 1 equipaje mediano/pequeño (información en boleto) | ✓ | — | — |
| EQ2 | Equipaje adicional genera cargo extra en la venta | ✓ | ✓ | — |
| EQ3 | Cantidad de equipaje extra > 0 | ✓ | ✓ | CHECK |
| EQ4 | Monto unitario del equipaje extra ≥ 0 | ✓ | ✓ | — |

---

## Módulo: Usuarios y permisos

| # | Validación | F | B | DB |
|---|------------|---|---|-----|
| U1 | Nombre de usuario único | ✓ | ✓ | UNIQUE |
| U2 | Cajero solo ve/opera datos de su empresa | — | ✓ | — |
| U3 | Admin empresa gestiona solo su empresa | — | ✓ | — |
| U4 | Admin general accede a todas las empresas | ✓ | ✓ | — |
| U5 | Rol RESERVA_EXCEPCIONAL requerido para apartar sin venta | — | ✓ | ✓ |
| U6 | Admin global solo asigna ADMIN_EMPRESA; cajeros los crea admin empresa | ✓ | ✓ | — |
| U7 | Cajero tiene terminal (sede) fija; solo ve/vende salidas desde ahí | ✓ | ✓ | — |
| U8 | Admin global no consulta manifiesto con datos personales de pasajeros | ✓ | ✓ | — |

---

## Concurrencia (temporada alta)

Escenario crítico: dos cajeros intentan vender el asiento 12 al mismo tiempo.

| # | Validación | F | B | DB |
|---|------------|---|---|-----|
| X1 | Verificar estado del asiento dentro de transacción | — | ✓ | — |
| X2 | UNIQUE en boleto.viaje_asiento_id evita doble venta | — | ✓ | ✓ |
| X3 | Si falla, devolver error claro: "Asiento no disponible" | ✓ | ✓ | — |
| X4 | Frontend refresca mapa de asientos tras error | ✓ | — | — |

---

## Cancelaciones (fase MVP+)

| # | Validación | F | B | DB |
|---|------------|---|---|-----|
| CA1 | Boleto cancelado libera asiento a DISPONIBLE o CANCELADO | — | ✓ | ✓ |
| CA2 | Venta parcialmente cancelada si quedan boletos activos | — | ✓ | ENUM |
| CA3 | Solo operador autorizado puede cancelar | — | ✓ | — |

---

## Resumen por capa

```
┌─────────────────────────────────────────────────────┐
│  FRONTEND                                           │
│  Formatos, campos obligatorios, mensajes al usuario │
└──────────────────────┬──────────────────────────────┘
                       │
┌──────────────────────▼──────────────────────────────┐
│  BACKEND (Spring Boot)                              │
│  Reglas de negocio, permisos, transacciones         │
└──────────────────────┬──────────────────────────────┘
                       │
┌──────────────────────▼──────────────────────────────┐
│  MySQL                                              │
│  FK, UNIQUE, CHECK, ENUM — última línea de defensa  │
└─────────────────────────────────────────────────────┘
```

**Principio:** nunca confiar solo en el frontend. Las reglas críticas (sin reserva, fecha de venta, asiento disponible) **siempre** se validan en el backend.

---

## Documentos relacionados

- [Arquitectura y stack](ARQUITECTURA-Y-STACK.md)
- [Modelo de datos](MODELO-DATOS.md)
