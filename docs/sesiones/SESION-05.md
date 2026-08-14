# Sesion 5 – Keycloak + OAuth2

## Objetivos

- Keycloak en Docker con realm `transporte-bluefields`
- Spring Boot como **OAuth2 Resource Server** (JWT)
- Endpoints publicos vs protegidos por rol

## Arranque

```powershell
docker compose up -d
# Esperar ~30s a que Keycloak importe el realm
cd backend
mvn spring-boot:run
```

Keycloak Admin: http://localhost:8180 (admin / admin)

Sin Keycloak (modo rapido):
```powershell
mvn spring-boot:run -Dspring-boot.run.profiles=local
```
Requiere `operadorId` en POST /api/ventas.

## Usuarios demo Keycloak

| Usuario | Password | Rol |
|---------|----------|-----|
| cajero.wendelyn | password | CAJERO |
| cajero.martinez | password | CAJERO |
| admin.global | password | ADMIN_GENERAL |

Deben existir tambien en tabla `usuario` (Liquibase changeset 003).

## Obtener token JWT

```powershell
curl -X POST "http://localhost:8180/realms/transporte-bluefields/protocol/openid-connect/token" ^
  -H "Content-Type: application/x-www-form-urlencoded" ^
  -d "client_id=transporte-api" ^
  -d "grant_type=password" ^
  -d "username=cajero.wendelyn" ^
  -d "password=password"
```

Copiar `access_token` de la respuesta.

## Matriz de acceso

| Endpoint | Auth | Rol |
|----------|------|-----|
| GET `/api/publico/**` | No | Publico |
| GET `/api/health` | No | - |
| POST `/api/ventas` | Si | CAJERO, ADMIN_EMPRESA, ADMIN_GENERAL |
| POST `/api/empresas` | Si | ADMIN_GENERAL |
| POST `/api/buses`, `/api/viajes` | Si | Autenticado |

## Probar venta con token

```powershell
$token = "PEGAR_ACCESS_TOKEN"

curl -X POST http://localhost:8080/api/ventas ^
  -H "Authorization: Bearer $token" ^
  -H "Content-Type: application/json" ^
  -d "{\"viajeId\":1,\"compradorNombre\":\"Juan Perez\",\"compradorCedula\":\"001-150890-0001A\",\"viajeAsientoIds\":[1,2]}"
```

El operador se resuelve desde JWT (`preferred_username` → tabla `usuario`).

## Swagger

http://localhost:8080/swagger-ui.html → boton **Authorize** → pegar token Bearer.

## Archivos clave

| Archivo | Funcion |
|---------|---------|
| `infra/keycloak/transporte-bluefields-realm.json` | Realm importado |
| `config/SecurityConfig.java` | Reglas HTTP + roles Keycloak |
| `security/OperadorContext.java` | JWT → usuario BD |

## Entregable sesion 5

- [ ] Keycloak arranca con realm importado
- [ ] Consulta publica sin token
- [ ] POST ventas rechaza sin token (401)
- [ ] POST ventas funciona con token CAJERO
- [ ] POST empresas solo ADMIN_GENERAL (403 para cajero)

Anterior: [Sesion 4](SESION-04.md)  
Siguiente: [Sesion 6](SESION-06.md) – API externa + WebClient
