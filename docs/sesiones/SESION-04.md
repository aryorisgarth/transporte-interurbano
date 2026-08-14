# Sesion 4 – Liquibase y versionado del esquema

## Objetivos

- Migrar de **Flyway** a **Liquibase**
- Changelog maestro YAML
- Changesets SQL + YAML (inserts)
- Versionado reproducible del esquema

## Estructura Liquibase

```
backend/src/main/resources/db/changelog/
├── db.changelog-master.yaml      ← punto de entrada
└── changes/
    ├── 001-schema-consolidado.sql
    ├── 002-changelog-roles.yaml  ← inserts en YAML puro
    └── 003-datos-demo.sql
```

## Changelog maestro

```yaml
databaseChangeLog:
  - changeSet:
      id: 001-schema-consolidado
      author: transporte
      changes:
        - sqlFile:
            path: changes/001-schema-consolidado.sql
            relativeToChangelogFile: true
            splitStatements: true
  - include:
      file: changes/002-changelog-roles.yaml
      relativeToChangelogFile: true
  - changeSet:
      id: 003-datos-demo
      author: transporte
      changes:
        - sqlFile:
            path: changes/003-datos-demo.sql
            relativeToChangelogFile: true
```

## Configuracion Spring Boot

`application.yml`:
```yaml
spring:
  liquibase:
    change-log: classpath:db/changelog/db.changelog-master.yaml
```

Maven: dependencia `liquibase-core` (Flyway eliminado).

## Tablas de control Liquibase

| Tabla | Proposito |
|-------|-----------|
| `DATABASECHANGELOG` | Historial de changesets aplicados |
| `DATABASECHANGELOGLOCK` | Bloqueo durante migracion |

## Reglas de versionado

1. **Nunca editar** un changeset ya aplicado en produccion
2. Cada cambio = **nuevo changeset** (004, 005...)
3. `id` + `author` deben ser unicos
4. SQL complejo → archivo `.sql` referenciado desde YAML
5. Datos pequenos → YAML `insert` (como roles)

## Ejemplo: agregar columna en el futuro

Crear `changes/004-agregar-codigo-empresa.yaml`:

```yaml
databaseChangeLog:
  - changeSet:
      id: 004-empresa-codigo
      author: tu_nombre
      changes:
        - addColumn:
            tableName: empresa
            columns:
              - column:
                  name: codigo_interno
                  type: varchar(20)
                  constraints:
                    nullable: true
```

Incluir en `db.changelog-master.yaml`:
```yaml
  - include:
      file: changes/004-agregar-codigo-empresa.yaml
      relativeToChangelogFile: true
```

## Reset base de datos (desarrollo)

Si venias de Flyway o el esquema cambio:

```sql
DROP DATABASE IF EXISTS transporte_bluefields;
CREATE DATABASE transporte_bluefields;
```

Luego:
```powershell
cd backend
mvn spring-boot:run
```

Liquibase aplica los 3 changesets automaticamente.

## Verificar migracion

```sql
SELECT id, author, filename, dateexecuted
FROM DATABASECHANGELOG
ORDER BY dateexecuted;
```

Debe mostrar:
- `001-schema-consolidado`
- `002-01-rol-cajero` ... `002-04-rol-reserva-excepcional`
- `003-datos-demo`

## Entregable sesion 4

- [ ] Proyecto usa Liquibase (no Flyway)
- [ ] `db.changelog-master.yaml` incluye SQL + YAML
- [ ] Arranque aplica esquema en BD vacia
- [ ] Tabla `DATABASECHANGELOG` tiene registros

Anterior: [Sesion 4](SESION-04.md)  
Siguiente: [Sesion 5](SESION-05.md) – Keycloak + OAuth2
