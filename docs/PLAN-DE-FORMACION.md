# Plan de formación – 5 semanas

**Formato:** 2 sesiones por semana × 2 horas = **20 horas totales**  
**Enfoque:** Spring Boot, JPA, Liquibase, Keycloak, APIs externas, JHipster, React, IA aplicada (Cursor/Codex) y proyecto final.

**Proyecto integrador:** Sistema de Gestión de Transporte Interurbano Bluefields – Managua.

---

## Mapa general

| Semana | Tema | Entregable en el proyecto |
|--------|------|---------------------------|
| 1 | Spring Boot + JPA básico | API REST de empresas y health check |
| 2 | JPA avanzado + Liquibase | Modelo completo BD + migraciones versionadas |
| 3 | Keycloak + APIs externas | Seguridad por roles + integración externa |
| 4 | JHipster + React | Frontend consulta pública y panel cajero |
| 5 | IA + Proyecto final | Refactor, docs, demo y presentación |

---

## SEMANA 1 – Fundamentos de Spring Boot

### Sesión 1 (2 h)

**Contenido del curso**
- Crear proyecto Spring Boot (Initializr)
- Perfiles (`dev` / `prod`)
- Logs
- Uso de `ResponseEntity`, `Optional`, `List`, `Map`
- API REST básica

**Práctica en el proyecto de transporte**

| Tarea | Detalle |
|-------|---------|
| Crear proyecto | `backend/` con Initializr: Web, JPA, Validation, MySQL, DevTools |
| Perfiles | `application-dev.yml` (local) y `application-prod.yml` (servidor) |
| Logs | Configurar nivel `DEBUG` en dev para `com.bluefields.transporte` |
| Primer endpoint | `GET /api/health` → `Map` con status del servicio |
| CRUD empresa (inicio) | `GET /api/empresas`, `GET /api/empresas/{id}` con `ResponseEntity` y `Optional` |

**Resultado esperado:** API arranca, responde health check y lista empresas.

---

### Sesión 2 (2 h)

**Contenido del curso**
- Beans y configuración
- Tipos de tiempo (`LocalDate`, `Instant`…)
- JPA básico: entidades y repositorios
- CRUD simple

**Práctica en el proyecto de transporte**

| Tarea | Detalle |
|-------|---------|
| Entidad `Empresa` | Campos: nombre, teléfono, correo, activo, timestamps con `Instant` |
| Entidad `Viaje` | Usar `LocalDate` (fecha) y `LocalTime` (hora salida) |
| Repositorio | `EmpresaRepository extends JpaRepository` |
| CRUD completo | POST, GET, PUT (opcional) para empresas |
| Config | Bean CORS para futuro frontend React |

**Resultado esperado:** CRUD de empresas funcional contra MySQL local.

---

## SEMANA 2 – JPA y Base de Datos

### Sesión 3 (2 h)

**Contenido del curso**
- Relaciones (1:N, N:M)
- DTOs
- Validaciones
- CRUD avanzado

**Práctica en el proyecto de transporte**

| Tarea | Detalle |
|-------|---------|
| Relación 1:N | `Empresa` → `Bus` → `AsientoBus` |
| Relación 1:N | `Viaje` → `ViajeAsiento` → `Boleto` |
| Relación N:M | `Usuario` ↔ `Rol` (`usuario_rol`) |
| DTOs | `EmpresaRequest`, `EmpresaResponse`, `VentaRequest`, `VentaResponse` |
| Validaciones | `@NotBlank`, `@NotNull`, `@Email`, `@Min` en DTOs |
| Reglas de negocio | Service: capacidad par del bus, tarifa única, sin reserva |

**Modelo relacional clave**

```
empresa ──< bus ──< asiento_bus
   └──< viaje ──< viaje_asiento ──< boleto >── venta
```

Ver: [MODELO-DATOS.md](MODELO-DATOS.md)

**Resultado esperado:** CRUD de buses y viajes con relaciones JPA y validaciones.

---

### Sesión 4 (2 h)

**Contenido del curso**
- Liquibase (instalación y uso)
- Changelogs YAML
- Versionado del esquema

**Práctica en el proyecto de transporte**

| Tarea | Detalle |
|-------|---------|
| Instalar Liquibase | Dependencia Maven + configuración Spring Boot |
| Changelog maestro | `db/changelog/db.changelog-master.yaml` |
| V1 – Tablas base | `empresa`, `rol`, `usuario`, `bus`, `asiento_bus` |
| V2 – Operación | `viaje`, `viaje_asiento`, `venta`, `boleto`, `equipaje_extra` |
| V3 – Datos seed | Roles: CAJERO, ADMIN_EMPRESA, ADMIN_GENERAL, RESERVA_EXCEPCIONAL |
| Versionado | Cada cambio = nuevo changeset, nunca editar uno ya aplicado |

**Nota:** Si el proyecto usa Flyway, migrar a Liquibase en esta sesión (eliminar Flyway, portar SQL a YAML).

**Resultado esperado:** Esquema MySQL versionado y reproducible en cualquier máquina.

---

## SEMANA 3 – Seguridad y APIs externas

### Sesión 5 (2 h)

**Contenido del curso**
- Keycloak + OAuth2
- Roles, usuarios y protección de endpoints

**Práctica en el proyecto de transporte**

| Tarea | Detalle |
|-------|---------|
| Keycloak en Docker | Realm `transporte-bluefields` |
| Roles | `CAJERO`, `ADMIN_EMPRESA`, `ADMIN_GENERAL`, `RESERVA_EXCEPCIONAL` |
| Usuarios demo | cajero@wendelyn, admin@wendelyn, admin@global |
| Endpoints públicos | `GET /api/publico/**` sin token |
| Endpoints protegidos | `POST /api/ventas` → rol CAJERO |
| Regla especial | `RESERVA_EXCEPCIONAL` → único permiso para apartar asiento |

**Matriz de acceso**

| Endpoint | Público | CAJERO | ADMIN_EMPRESA | ADMIN_GENERAL |
|----------|---------|--------|---------------|---------------|
| GET /api/publico/viajes | ✓ | ✓ | ✓ | ✓ |
| POST /api/ventas | — | ✓ | ✓ | ✓ |
| POST /api/empresas | — | — | — | ✓ |
| POST /api/viajes | — | — | ✓ | ✓ |

**Resultado esperado:** API protegida; consulta pública libre, venta solo autenticada.

---

### Sesión 6 (2 h)

**Contenido del curso**
- Consumo de APIs externas
- Uso de RestTemplate / WebClient
- Manejo de errores

**Práctica en el proyecto de transporte**

Elegir **una** integración externa según disponibilidad:

| Opción | Uso en el proyecto |
|--------|-------------------|
| **API de tipo de cambio** | Mostrar tarifa en córdobas y referencia USD en panel admin |
| **API de clima (OpenWeather)** | Alerta en consulta pública si hay condiciones adversas en ruta |
| **API de geocoding** | Validar origen/destino o mostrar mapa de terminal |
| **API SMS/email (Twilio/SendGrid)** | Confirmación de venta al teléfono del comprador (fase 2) |

**Implementación mínima**

```text
Service externo → WebClient → DTO respuesta → Controller expone /api/externo/...
GlobalExceptionHandler → errores de timeout, 404, 500 de la API externa
```

**Resultado esperado:** Al menos un endpoint propio que consume y expone datos de API externa.

---

## SEMANA 4 – JHipster, JDL y React

### Sesión 7 (2 h)

**Contenido del curso**
- JHipster: creación de proyecto
- JDL Studio: diseño de entidades

**Práctica en el proyecto de transporte**

| Tarea | Detalle |
|-------|---------|
| Diseñar JDL | Entidades: Empresa, Bus, Viaje, ViajeAsiento, Venta, Boleto, Usuario |
| Relaciones JDL | `Empresa{bus Bus}` `Viaje{viajeAsiento ViajeAsiento}` etc. |
| Comparar | JDL generado vs esquema Liquibase actual — deben coincidir |
| Opcional | Generar prototipo JHipster en carpeta aparte solo como referencia |

**Nota:** No es obligatorio reescribir todo el proyecto en JHipster. El valor está en **diseñar el dominio en JDL** y comparar con la implementación manual.

**Resultado esperado:** Archivo `transporte.jdl` documentado en `docs/`.

---

### Sesión 8 (2 h)

**Contenido del curso**
- Repaso React
- Fetch desde frontend hacia backend

**Práctica en el proyecto de transporte**

| Pantalla | Función |
|----------|---------|
| **Consulta pública** | Formulario origen/destino/fecha → lista horarios y cupos |
| **Detalle viaje** | Mapa de asientos (colores: disponible / vendido) |
| **Panel cajero** | Selección asientos + datos comprador → POST venta |

**Stack frontend:** React + Material UI + `fetch` o `axios`

```text
GET  http://localhost:8080/api/publico/viajes?fecha=2026-12-24
POST http://localhost:8080/api/ventas  (con token Keycloak)
```

**Resultado esperado:** Mini frontend React con al menos consulta pública + una acción de venta.

---

## SEMANA 5 – IA aplicada + Proyecto Final

### Sesión 9 (2 h)

**Contenido del curso**
- Uso de Cursor: refactor, documentación, generación de código
- Uso de Codex/GPT: endpoints, repositorios, documentación

**Práctica en el proyecto de transporte**

| Uso de IA | Ejemplo concreto |
|-----------|------------------|
| Generar DTOs | A partir de entidades JPA |
| Documentar | Swagger descriptions, README, validaciones |
| Refactor | Extraer reglas de venta a `VentaService` |
| Tests | Generar tests unitarios de validaciones críticas |
| Revisión | Pedir revisión de concurrencia en venta de asientos |

**Regla:** Siempre revisar y entender el código generado; IA asiste, no reemplaza criterio.

**Resultado esperado:** Código refactorizado + docs actualizadas con ayuda de IA.

---

### Sesión 10 (2 h) – Presentación del Proyecto Final

## Requerimientos del proyecto final

El microservicio / sistema debe incluir:

| Requisito | Obligatorio | Evidencia |
|-----------|-------------|-----------|
| Spring Boot | ✓ | API REST funcional |
| JPA | ✓ | Entidades con relaciones 1:N y N:M |
| Liquibase | ✓ | Changelogs versionados |
| Keycloak | ✓ | Login + roles + endpoints protegidos |
| API externa | ✓ | Al menos 1 integración con WebClient/RestTemplate |
| Mini frontend React | ✓ | Consulta pública y/o panel cajero |
| IA aplicada | ✓ | Evidencia de uso en Cursor/Codex (commits o capturas) |

### Funcionalidad mínima de negocio (transporte Bluefields)

1. Multiempresa (al menos 2 empresas demo)
2. Buses con layout ventana/pasillo
3. Viajes programados con tarifa única
4. Consulta pública de cupos **sin reserva**
5. Venta en terminal: un comprador, N asientos, cédula del comprador
6. Equipaje extra opcional
7. Regla: venta solo día anterior o mismo día del viaje

Ver validaciones: [VALIDACIONES.md](VALIDACIONES.md)

---

## Guía de entrega

### 1. Repositorio Git

```
SISTEMA-DE-GESTION-TRANSPORTE/
├── backend/          Spring Boot
├── frontend/         React
├── docs/             Documentación + JDL + plan formación
├── docker-compose.yml  MySQL + Keycloak
└── README.md         Instrucciones de arranque
```

### 2. Documentos obligatorios

- [ ] README con pasos: `docker compose up`, arrancar backend, frontend
- [ ] Diagrama ER o enlace a [MODELO-DATOS.md](MODELO-DATOS.md)
- [ ] Lista de endpoints (Swagger exportado o tabla en README)
- [ ] Usuarios Keycloak de prueba y sus roles
- [ ] Descripción de la API externa consumida

### 3. Demo en vivo (10–15 min)

1. Consulta pública: buscar viaje y ver cupos
2. Login como cajero en Keycloak
3. Vender 3 boletos a un nombre con 3 asientos
4. Verificar que cupos bajan en consulta pública
5. Mostrar Liquibase aplicado / changelog
6. Mostrar llamada a API externa

### 4. Criterios de evaluación

| Criterio | Peso sugerido |
|----------|---------------|
| API REST correcta y estructurada | 20% |
| Modelo JPA + Liquibase | 20% |
| Seguridad Keycloak | 20% |
| API externa + manejo errores | 10% |
| Frontend React funcional | 15% |
| Reglas de negocio del dominio | 10% |
| Documentación y presentación | 5% |

### 5. Entregables digitales

- Repositorio Git (URL)
- Video demo opcional (3–5 min)
- Swagger UI accesible en `/swagger-ui.html`
- PDF requisitos actualizado en raíz del proyecto

---

## Calendario resumido

| Sesión | Semana | Horas | Tema |
|--------|--------|-------|------|
| 1 | 1 | 2h | Initializr, perfiles, REST básico |
| 2 | 1 | 2h | Beans, JPA, CRUD simple |
| 3 | 2 | 2h | Relaciones, DTOs, validaciones |
| 4 | 2 | 2h | Liquibase changelogs |
| 5 | 3 | 2h | Keycloak + OAuth2 |
| 6 | 3 | 2h | API externa + WebClient |
| 7 | 4 | 2h | JHipster + JDL |
| 8 | 4 | 2h | React + fetch |
| 9 | 5 | 2h | IA (Cursor/Codex) |
| 10 | 5 | 2h | **Presentación proyecto final** |

**Total: 20 horas**

---

## Documentos de referencia del proyecto

- [Arquitectura y stack](ARQUITECTURA-Y-STACK.md)
- [Modelo de datos](MODELO-DATOS.md)
- [Validaciones](VALIDACIONES.md)
- [Esquema SQL](database-schema.sql)
