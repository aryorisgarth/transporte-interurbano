# Modelo de datos (MySQL relacional)

Base de datos: **transporte_bluefields**  
Versión: **consolidada** — ver [DISENO-BD.md](DISENO-BD.md) para decisiones de diseño.

---

## Diagrama entidad-relación

```mermaid
erDiagram
    EMPRESA ||--o{ BUS : tiene
    EMPRESA ||--o{ VIAJE : programa
    EMPRESA ||--o{ USUARIO : emplea
    EMPRESA ||--o{ VENTA : registra

    BUS ||--o{ ASIENTO_BUS : contiene
    BUS ||--o{ VIAJE : asignado_a

    VIAJE ||--o{ VIAJE_ASIENTO : instancia
    ASIENTO_BUS ||--o{ VIAJE_ASIENTO : referencia

    VIAJE ||--o{ VENTA : genera
    USUARIO ||--o{ VENTA : opera
    VENTA ||--o{ BOLETO : incluye
    VENTA ||--o{ EQUIPAJE_EXTRA : opcional

    VIAJE_ASIENTO ||--o| BOLETO : ocupa
    VIAJE_ASIENTO ||--o| RESERVA_EXCEPCIONAL : permiso_especial
    USUARIO }o--o{ ROL : tiene

    EMPRESA {
        bigint id PK
        varchar nombre
        decimal tarifa_equipaje_extra
        boolean activo
    }

    BUS {
        bigint id PK
        int capacidad
        int filas
    }

    VIAJE {
        bigint id PK
        date fecha
        time hora_salida
        decimal tarifa
        decimal tarifa_equipaje_extra
    }

    VIAJE_ASIENTO {
        bigint id PK
        enum estado
        int version
    }

    VENTA {
        bigint id PK
        varchar codigo UK
        varchar comprador_cedula
        int cantidad_boletos
        decimal total
    }

    BOLETO {
        bigint id PK
        int numero_asiento
        boolean incluye_equipaje
    }
```

---

## Tablas

### Operación

| Tabla | Descripción |
|-------|-------------|
| `empresa` | Transportistas + tarifa default equipaje extra |
| `bus` | Unidad con `capacidad` par y `filas = capacidad/2` |
| `asiento_bus` | Layout fijo: número, fila, VENTANA/PASILLO |
| `viaje` | Salida con tarifa única y tarifa equipaje opcional |
| `viaje_asiento` | Estado del asiento en **ese** viaje + `version` |
| `venta` | Compra terminal: folio `codigo`, comprador, totales |
| `boleto` | 1 fila por asiento; `incluye_equipaje = true` |
| `equipaje_extra` | Cargo adicional en la misma venta |

### Seguridad

| Tabla | Descripción |
|-------|-------------|
| `usuario` | Local o Keycloak (`keycloak_id`) |
| `rol` | CAJERO, ADMIN_EMPRESA, ADMIN_GENERAL, RESERVA_EXCEPCIONAL |
| `usuario_rol` | N:M |
| `reserva_excepcional` | Solo permiso especial; estados de ciclo de vida |

### Vista

| Objeto | Descripción |
|--------|-------------|
| `v_cupos_viaje` | Cupos agregados por viaje para consulta pública |

---

## Layout de asientos

```
Fila 1:  [1 VENTANA] [2 PASILLO]
Fila 2:  [3 VENTANA] [4 PASILLO]
...
```

Constraints: `capacidad MOD 2 = 0`, `filas * 2 = capacidad`, UNIQUE `(bus_id, fila, posicion)`.

---

## Venta familiar (ejemplo)

```
VENTA codigo: V-1-1730000000123
├── comprador: Juan Pérez (cédula)
├── cantidad_boletos: 5
└── BOLETOS: asientos 1,2,3,4,5 (cada uno incluye_equipaje)
```

---

## Estados

**viaje_asiento:** `DISPONIBLE` | `VENDIDO` | `CANCELADO` | `RESERVADO_EXCEPCIONAL`

**viaje:** `PROGRAMADO` → `EN_CURSO` → `COMPLETADO` / `CANCELADO`

**reserva_excepcional:** `ACTIVA` → `CONVERTIDA` | `CANCELADA` | `EXPIRADA`

---

## Consultas típicas

**Consulta pública (vista):**
```sql
SELECT * FROM v_cupos_viaje
WHERE origen = 'Bluefields'
  AND destino = 'Managua'
  AND fecha = '2026-12-24'
  AND estado_viaje = 'PROGRAMADO'
ORDER BY hora_salida;
```

**Cupos disponibles:**
```sql
SELECT COUNT(*) FROM viaje_asiento
WHERE viaje_id = ? AND estado = 'DISPONIBLE';
```

---

## Archivos

- [database-schema.sql](database-schema.sql) — script completo
- [DISENO-BD.md](DISENO-BD.md) — decisiones y mejoras
- [VALIDACIONES.md](VALIDACIONES.md) — reglas por módulo
