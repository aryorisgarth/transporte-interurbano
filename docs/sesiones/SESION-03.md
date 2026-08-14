SI# Sesion 3 – Relaciones, DTOs, validaciones y ventas

## Objetivos

- Relaciones JPA **1:N** y **N:M**
- DTOs con Bean Validation
- Reglas de negocio en servicios
- Venta de boletos (compra multiple a un nombre)

## Relaciones en el proyecto

```
Empresa 1──N Bus 1──N AsientoBus
Empresa 1──N Viaje 1──N ViajeAsiento 1──1 Boleto
Venta 1──N Boleto
Venta 1──N EquipajeExtra
Usuario N──M Rol  (tabla usuario_rol)
```

## Validaciones

### Capa DTO (`@Valid`)
- `@NotBlank`, `@NotNull`, `@NotEmpty`, `@Size`, `@Email`, `@Min`, `@DecimalMin`
- Errores multiples en JSON: `{ "errores": [{ "campo", "mensaje" }] }`

### Capa Service (reglas de negocio)
- Sin reserva: solo asientos `DISPONIBLE`
- Venta solo dia anterior o mismo dia del viaje
- Operador debe ser CAJERO de la misma empresa
- Capacidad bus par (ventana/pasillo)
- Concurrencia: `@Version` en `viaje_asiento` → HTTP 409 Conflict

## Datos demo (Liquibase changeset 003)

| Recurso | Valor |
|---------|-------|
| Empresas | Wendelyn (id 1), Martinez (id 2) |
| Cajero Wendelyn | usuario id 1, `cajero.wendelyn` |
| Password demo | `password` (solo desarrollo) |

## Endpoints sesion 3

| Metodo | Ruta | Descripcion |
|--------|------|-------------|
| GET | `/api/usuarios/{id}` | Usuario + roles (N:M) |
| GET | `/api/publico/viajes?fecha=...` | Consulta cupos (solo lectura) |
| GET | `/api/publico/viajes/{id}` | Mapa de asientos |
| POST | `/api/ventas` | Vender boletos |
| GET | `/api/ventas/{id}` | Detalle venta |
| GET | `/api/ventas?viajeId=1` | Ventas de un viaje |

## Flujo de venta familiar (5 asientos)

```powershell
# 1. Ver asientos del viaje (obtener viajeAsientoIds)
curl http://localhost:8080/api/publico/viajes/1

# 2. Vender 3 asientos a un solo nombre
curl -X POST http://localhost:8080/api/ventas -H "Content-Type: application/json" -d "{\"viajeId\":1,\"operadorId\":1,\"compradorNombre\":\"Juan Perez\",\"compradorCedula\":\"001-150890-0001A\",\"compradorTelefono\":\"88887777\",\"viajeAsientoIds\":[1,2,3],\"equipajeExtra\":{\"cantidad\":1,\"montoUnitario\":150}}"

# 3. Verificar cupos bajaron
curl "http://localhost:8080/api/publico/viajes?fecha=2026-12-24"
```

Respuesta venta incluye:
- `codigo`: folio unico
- `cantidadBoletos`: 3
- `numerosAsiento`: [1, 2, 3]
- `boletos[].incluyeEquipaje`: true

## Entregable sesion 3

- [ ] GET usuario muestra roles (CAJERO)
- [ ] Consulta publica sin modificar asientos
- [ ] Venta multiple a un comprador funciona
- [ ] Validacion rechaza venta sin cedula (400 + errores)
- [ ] Segunda venta del mismo asiento falla

Anterior: [Sesion 2](SESION-02.md)  
Siguiente: [Sesion 4](SESION-04.md) – Liquibase changelogs
