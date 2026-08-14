# Sesion 2 – Beans, JPA y tipos de tiempo

## Objetivos

- Beans de configuracion (`Clock`, Jackson)
- Tipos de tiempo: `LocalDate`, `LocalTime`, `Instant`
- Entidades JPA + repositorios
- CRUD: empresa, bus, viaje

## Beans creados

| Clase | Bean | Proposito |
|-------|------|-----------|
| `TimeConfig` | `Clock` | Fecha/hora en zona `America/Managua` (testeable) |
| `JacksonConfig` | customizer | JSON ISO: `"fecha":"2026-12-24"`, `"horaSalida":"23:00:00"` |
| `WebConfig` | CORS | Origenes desde `application-dev.yml` |

## Tipos de tiempo en el proyecto

| Tipo | Uso | Tabla/campo |
|------|-----|-------------|
| `LocalDate` | Dia del viaje | `viaje.fecha` |
| `LocalTime` | Hora de salida | `viaje.hora_salida` |
| `Instant` | Auditoria UTC | `empresa.created_at`, `venta.fecha_venta` |

## Endpoints nuevos / mejorados

### Buses
| Metodo | Ruta |
|--------|------|
| POST | `/api/buses` |
| GET | `/api/buses?empresaId=1` |
| GET | `/api/buses/{id}` |

### Viajes
| Metodo | Ruta |
|--------|------|
| POST | `/api/viajes` |
| GET | `/api/viajes?empresaId=1&fecha=2026-12-24` |
| GET | `/api/viajes/{id}` |

Al programar viaje se crean automaticamente los `viaje_asiento` desde el layout del bus.

## Flujo de prueba completo

```powershell
# 1. Empresa
curl -X POST http://localhost:8080/api/empresas -H "Content-Type: application/json" -d "{\"nombre\":\"Wendelyn\",\"telefono\":\"25723456\",\"correo\":\"info@wendelyn.com\"}"

# 2. Bus (capacidad par)
curl -X POST http://localhost:8080/api/buses -H "Content-Type: application/json" -d "{\"empresaId\":1,\"numeroInterno\":\"01\",\"placa\":\"ABC123\",\"capacidad\":50}"

# 3. Viaje (LocalDate + LocalTime en JSON)
curl -X POST http://localhost:8080/api/viajes -H "Content-Type: application/json" -d "{\"empresaId\":1,\"busId\":1,\"fecha\":\"2026-12-24\",\"horaSalida\":\"23:00:00\",\"tarifa\":500.00}"

# 4. Listar viajes del dia
curl "http://localhost:8080/api/viajes?empresaId=1&fecha=2026-12-24"
```

## Conceptos clave

- **@Configuration + @Bean**: Spring crea e inyecta `Clock` en servicios
- **JpaRepository**: metodos derivados + `@Query` con JOIN FETCH
- **LocalDate.now(clock)**: no usar `new Date()`; zona horaria explicita
- **Optional en servicio**: `buscar(id).map(...).orElse(404)` en controller

## Entregable sesion 2

- [ ] Crear empresa, bus y viaje en cadena
- [ ] JSON muestra fecha/hora en formato ISO
- [ ] GET viajes por empresa + fecha devuelve lista con cupos
- [ ] Logs DEBUG en consola al crear bus/viaje

Anterior: [Sesion 1](SESION-01.md)  
Siguiente: [Sesion 3](../PLAN-DE-FORMACION.md) – Relaciones, DTOs, validaciones avanzadas
