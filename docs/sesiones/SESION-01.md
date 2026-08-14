# Sesion 1 – Fundamentos Spring Boot

## Objetivos

- Proyecto con perfiles `dev` / `prod`
- Logs configurables
- `ResponseEntity`, `Optional`, `List`, `Map`
- API REST: health + CRUD empresas

## Arranque

```powershell
docker compose up -d
cd backend
mvn spring-boot:run
```

Perfil produccion:

```powershell
mvn spring-boot:run -Dspring-boot.run.profiles=prod
```

Variables prod: `DB_URL`, `DB_USER`, `DB_PASSWORD`, `CORS_ORIGINS`

## Endpoints

| Metodo | Ruta | Descripcion |
|--------|------|-------------|
| GET | `/api/health` | Estado del servicio + perfil activo |
| GET | `/api/empresas` | Listar empresas activas |
| GET | `/api/empresas/{id}` | Obtener una (404 si no existe) |
| POST | `/api/empresas` | Crear empresa |
| PUT | `/api/empresas/{id}` | Actualizar empresa |
| PATCH | `/api/empresas/{id}/desactivar` | Baja logica |

Swagger: http://localhost:8080/swagger-ui.html

## Pruebas con curl

```powershell
curl http://localhost:8080/api/health

curl -X POST http://localhost:8080/api/empresas ^
  -H "Content-Type: application/json" ^
  -d "{\"nombre\":\"Wendelyn\",\"telefono\":\"25723456\",\"correo\":\"info@wendelyn.com\",\"tarifaEquipajeExtra\":150.00}"

curl http://localhost:8080/api/empresas

curl http://localhost:8080/api/empresas/1
```

## Conceptos clave

- **ResponseEntity**: controla status HTTP (201 Created, 404 Not Found)
- **Optional**: `buscarActiva(id).map(ok).orElse(notFound)`
- **Perfiles**: configuracion distinta dev vs prod sin cambiar codigo
- **Logs**: SLF4J en service (`log.debug`, `log.info`)

## Entregable sesion 1

- [ ] API arranca con perfil `dev`
- [ ] Liquibase aplica esquema consolidado
- [ ] Health responde JSON con profiles
- [ ] CRUD empresas funcional contra MySQL

Siguiente: [Sesion 2](SESION-02.md) – Beans, JPA, tipos de tiempo, CRUD viaje.
