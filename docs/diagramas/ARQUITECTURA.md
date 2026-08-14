# Diagrama de arquitectura

Vista de capas del **Sistema de Gestión de Transporte Interurbano Bluefields – Managua**.

## Arquitectura general

```mermaid
flowchart TB
    subgraph clientes["Clientes"]
        WEB["React + Vite + MUI<br/>Back-office web"]
        MOB["Flutter<br/>Consulta + Cajero + Admin"]
        PUB["Consulta pública<br/>sin login"]
    end

    subgraph auth["Autenticación"]
        KC["Keycloak<br/>OAuth2 / OIDC"]
    end

    subgraph backend["Backend Spring Boot 3"]
        API["REST API<br/>Controllers"]
        SVC["Servicios<br/>Venta, Viaje, Bus…"]
        SEC["OperadorContext<br/>Multi-tenant"]
        API --> SVC
        SVC --> SEC
    end

    subgraph datos["Persistencia"]
        MYSQL[("MySQL 8")]
        LB["Liquibase<br/>Migraciones"]
    end

    PUB --> WEB
    PUB --> MOB
    WEB -->|"JWT Bearer"| API
    MOB -->|"JWT Bearer"| API
    WEB --> KC
    MOB --> KC
    SVC --> MYSQL
    LB --> MYSQL
```

## Flujo de venta (cajero)

```mermaid
sequenceDiagram
    actor Cajero
    participant React as React / Flutter
    participant KC as Keycloak
    participant API as VentaController
    participant SVC as VentaService
    participant DB as MySQL

    Cajero->>React: Login
    React->>KC: OAuth2 password / PKCE
    KC-->>React: JWT (roles CAJERO)
    Cajero->>React: Selecciona asientos + comprador
    React->>API: POST /api/ventas (Bearer JWT)
    API->>SVC: vender(request)
    SVC->>SVC: validar fecha, tenant, asientos
    SVC->>DB: INSERT venta + boletos
    DB-->>SVC: OK
    SVC-->>React: VentaResponse
    React-->>Cajero: Comprobante PDF / imprimir
```

## Multi-tenant

```mermaid
flowchart LR
    subgraph publico["Consulta pública"]
        Q["GET /api/publico/*"]
    end

    subgraph wendelyn["Tenant Wendelyn"]
        CW["cajero.wendelyn"]
        AW["admin.wendelyn"]
    end

    subgraph martinez["Tenant Martínez"]
        CM["cajero.martinez"]
        AM["admin.martinez"]
    end

    AG["admin.global<br/>ADMIN_GENERAL"]

    Q --> ALL["Todas las empresas"]
    CW --> W["Solo empresa_id=1"]
    AW --> W
    CM --> M["Solo empresa_id=2"]
    AM --> M
    AG --> ALL
```

## Despliegue demo (local)

```mermaid
flowchart LR
    DC["docker compose"]
    DC --> MYSQL["MySQL :3307"]
    DC --> KC["Keycloak :8180"]
    SB["mvn spring-boot:run<br/>:8080"]
    FE["npm run dev<br/>:5173"]
    FL["flutter run"]
    SB --> MYSQL
    FE --> SB
    FE --> KC
    FL --> SB
    FL --> KC
```

## Relación con JDL

El dominio está documentado en [`transporte.jdl`](../transporte.jdl). El proyecto **no** usa un monolito JHipster generado; el JDL sirve como contrato de diseño comparado con Liquibase.

Ver también: [MODELO-JDL.md](./MODELO-JDL.md)
