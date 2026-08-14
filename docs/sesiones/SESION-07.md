# Sesion 7 – JHipster + JDL Studio

## Objetivos

- Disenar el dominio en **JDL** (JHipster Domain Language)
- Visualizar entidades y relaciones en JDL Studio
- Comparar JDL vs esquema **Liquibase** actual
- Entender que JHipster es herramienta de **generacion**, no reemplazo obligatorio del backend manual

## Archivo JDL del proyecto

**Ruta:** [docs/transporte.jdl](../transporte.jdl)

Importar en: https://start.jhipster.io/jdl-studio/

---

## Pasos en JDL Studio (2 h)

### 1. Importar JDL (15 min)

1. Abrir JDL Studio
2. Copiar contenido de `docs/transporte.jdl`
3. Pegar en el editor → ver diagrama de entidades
4. Verificar relaciones 1:N, N:M, 1:1

### 2. Explorar el diagrama (20 min)

Identificar en el canvas:

```
Empresa ──< Bus ──< AsientoBus
   │         └──< Viaje ──< ViajeAsiento ──< Boleto
   │                              │
   └──< Venta >───────────────────┘
              └── EquipajeExtra

Usuario >──< Rol
ViajeAsiento ── ReservaExcepcional (1:1)
```

### 3. Comparar con Liquibase (30 min)

Usar tabla de correspondencia:

| JDL | Liquibase / JPA | Coincide |
|-----|-----------------|----------|
| `Empresa.tarifaEquipajeExtra` | `empresa.tarifa_equipaje_extra` | Si |
| `Bus.filas` | `bus.filas` | Si |
| `Venta.codigo` | `venta.codigo` UNIQUE | Si |
| `Venta.cantidadBoletos` | `venta.cantidad_boletos` | Si |
| `Boleto.incluyeEquipaje` | `boleto.incluye_equipaje` | Si |
| `ViajeAsiento.version` | `viaje_asiento.version` | Si |
| `ReservaExcepcional` | `reserva_excepcional` | Si |
| `Usuario.keycloakId` | `usuario.keycloak_id` | Si |

Ver detalle completo: [JDL-vs-LIQUIBASE.md](JDL-vs-LIQUIBASE.md)

### 4. Exportar / documentar (15 min)

- Exportar PNG del diagrama desde JDL Studio (opcional)
- Anotar diferencias si las hay
- No regenerar el proyecto completo salvo experimento en carpeta aparte

### 5. Opcional: prototipo JHipster (40 min)

Solo como referencia, en carpeta **fuera** del repo principal:

```powershell
mkdir C:\temp\transporte-jhipster-prototype
cd C:\temp\transporte-jhipster-prototype
# Requiere Node.js + JHipster CLI instalado
jhipster jdl C:\Users\ADMIN\Desktop\SISTEMA-DE-GESTION-TRANSPORTE\docs\transporte.jdl
```

Comparar codigo generado vs `backend/src/main/java/com/bluefields/transporte/`.

---

## Que aporta JHipster vs nuestro backend manual

| Aspecto | Backend manual (actual) | JHipster generado |
|---------|-------------------------|-------------------|
| Control del codigo | Total | Parcial (regeneracion) |
| Reglas de negocio | `VentaService`, validaciones custom | Hay que adaptar lo generado |
| Keycloak | Configurado a medida | OAuth2 incluido en JDL |
| Liquibase | Changelogs YAML/SQL propios | Generados desde JDL |
| Curva aprendizaje | Spring Boot puro | JDL + convenciones JHipster |
| **Valor en el curso** | Implementacion real del proyecto | **Modelar dominio antes de codear** |

**Conclusion del curso:** usar JDL para **disenar y validar** el modelo; implementar en Spring Boot manual como ya hicimos en sesiones 1-6.

---

## Bloque `application` en el JDL

El JDL incluye configuracion de app de referencia:

```jdl
application {
  config {
    baseName transporte
    applicationType monolith
    authenticationType oauth2
    databaseType sql
    devDatabaseType mysql
    clientFramework react
    nativeLanguage es
  }
}
```

Esto indica como se veria un monolito JHipster con React + OAuth2 + MySQL — alineado con el plan del proyecto final.

---

## Entregable sesion 7

- [ ] JDL importado en JDL Studio sin errores
- [ ] Diagrama revisado con todas las entidades
- [ ] Tabla comparativa JDL vs Liquibase completada
- [ ] Entendido: JDL = diseno, backend/ = implementacion real

Anterior: [Sesion 6](SESION-06.md)  
Siguiente: [Sesion 8](SESION-08.md) – React + fetch al backend
