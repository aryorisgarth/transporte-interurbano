# Backend - Transporte Bluefields

API REST Spring Boot para el sistema de gestion de transporte interurbano Bluefields - Managua.

## Requisitos

- Java 17
- Maven 3.9+
- MySQL 8

## Base de datos

```bash
docker compose up -d
```

La base de datos `transporte_bluefields` se crea automaticamente. **Liquibase** aplica el esquema desde `src/main/resources/db/changelog/`.

Credenciales por defecto en `application.yml`:
- usuario: `root`
- password: `root`

## Ejecutar

```bash
cd backend
mvn spring-boot:run
```

## API principal

| Metodo | Ruta | Descripcion |
|--------|------|-------------|
| GET | `/api/health` | Estado del servicio |
| POST | `/api/empresas` | Registrar empresa |
| POST | `/api/buses` | Registrar bus con layout de asientos |
| POST | `/api/viajes` | Programar viaje |
| GET | `/api/publico/viajes` | Consulta publica de cupos |
| POST | `/api/ventas` | Venta en terminal (sin reserva) |

## Reglas de negocio implementadas

- Sin reservas: venta directa en terminal
- Compra multiple a nombre de un comprador
- Tarifa unica por boleto
- Layout 2 columnas: ventana / pasillo
- Venta solo el dia anterior o el mismo dia del viaje
- Equipaje extra opcional en la venta
