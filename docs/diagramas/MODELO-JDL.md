# Modelo de dominio (JDL)

Diagrama entidad-relación derivado de [`docs/transporte.jdl`](../transporte.jdl).

> Importar el JDL en [JHipster JDL Studio](https://start.jhipster.io/jdl-studio/) para exportar PNG adicional si el docente lo solicita.

## Diagrama ER

```mermaid
erDiagram
    Empresa ||--o{ Bus : tiene
    Empresa ||--o{ Viaje : programa
    Empresa ||--o{ Venta : registra
    Empresa ||--o{ Usuario : emplea

    Bus ||--o{ AsientoBus : contiene

    Viaje ||--o{ ViajeAsiento : asigna
    AsientoBus ||--o{ ViajeAsiento : usa

    Viaje ||--o{ Venta : vende
    Venta ||--o{ Boleto : emite
    Venta ||--o{ EquipajeExtra : incluye

    ViajeAsiento ||--o| ReservaExcepcional : reserva

    Usuario ||--o{ Venta : opera
    Usuario ||--o{ ReservaExcepcional : autoriza
    Usuario }o--o{ Rol : tiene

    Empresa {
        string nombre
        decimal tarifaEquipajeExtra
        boolean activo
    }

    Bus {
        string placa
        int capacidad
        int filas
    }

    Viaje {
        string origen
        string destino
        date fecha
        time horaSalida
        decimal tarifa
        enum estado
    }

    ViajeAsiento {
        enum estado
        int version
    }

    Venta {
        string codigo
        string compradorNombre
        string compradorCedula
        decimal total
        enum estado
    }

    Boleto {
        int numeroAsiento
        decimal monto
        boolean incluyeEquipaje
    }
```

## Enums principales

| Enum | Valores |
|------|---------|
| `EstadoViaje` | PROGRAMADO, EN_CURSO, COMPLETADO, CANCELADO |
| `EstadoAsientoViaje` | DISPONIBLE, VENDIDO, CANCELADO, RESERVADO_EXCEPCIONAL |
| `EstadoVenta` | COMPLETADA, CANCELADA, PARCIALMENTE_CANCELADA |
| `PosicionAsiento` | VENTANA, PASILLO, TRASERA_1…5 |

## JDL vs implementación

| Aspecto | JDL / JHipster | Proyecto actual |
|---------|----------------|-----------------|
| Backend | Generado por JHipster | Spring Boot manual en `backend/` |
| BD | JPA auto / Liquibase JHipster | Liquibase en `db/changelog/` |
| Frontend web | React generado | React + Vite custom en `frontend/` |
| App móvil | No definida | Flutter completo en `mobile/` |
| Auth | OAuth2 | Keycloak + JWT resource server |

Documento detallado: [JDL-vs-LIQUIBASE.md](../JDL-vs-LIQUIBASE.md)
