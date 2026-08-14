# Entrega docente — Material de apoyo

Documentación visual y técnica para la presentación del proyecto **Sistema de Gestión de Transporte Interurbano Bluefields – Managua**.

---

## Guía rápida de demo

Siga el guión paso a paso en **[DEMO.md](./DEMO.md)** (5–10 minutos).

---

## Diagramas (Mermaid)

Estos archivos se renderizan en GitHub, VS Code (extensión Mermaid) o cualquier visor Markdown compatible.

| Documento | Contenido |
|-----------|-----------|
| [diagramas/ARQUITECTURA.md](./diagramas/ARQUITECTURA.md) | Capas, flujo de venta, multi-tenant, despliegue |
| [diagramas/MODELO-JDL.md](./diagramas/MODELO-JDL.md) | Diagrama ER del dominio |

### Exportar a PNG (opcional)

1. **JDL Studio:** abrir [`transporte.jdl`](./transporte.jdl) en https://start.jhipster.io/jdl-studio/ → exportar diagrama.
2. **Mermaid Live:** copiar bloques ` ```mermaid ` de los archivos anteriores a https://mermaid.live → Export PNG/SVG.

---

## Qué incluye el proyecto

| Componente | Tecnología | Roles |
|------------|------------|-------|
| API REST | Spring Boot 3 + MySQL + Liquibase | — |
| Web back-office | React + MUI + Vite | Público, cajero, admin |
| App móvil | Flutter | Público, cajero, admin |
| Auth | Keycloak OAuth2 | CAJERO, ADMIN_EMPRESA, ADMIN_GENERAL |

---

## Funcionalidades destacadas para evaluación

1. **Multi-tenant:** cooperativas Wendelyn y Martínez con datos aislados (`OperadorContext`).
2. **Consulta pública:** tablero tipo terminal sin login (web + móvil).
3. **Venta presencial:** mapa Yutong 50 asientos, comprobante **PDF descargable** e impresión.
4. **Seguridad:** JWT + roles; backend valida tenant en cada operación.
5. **Calidad:** tests unitarios backend + CI GitHub Actions (Maven, npm build, Flutter test).

---

## Referencias

- [README](../README.md) — instalación
- [ARQUITECTURA-Y-STACK.md](./ARQUITECTURA-Y-STACK.md) — stack detallado
- [VALIDACIONES.md](./VALIDACIONES.md) — reglas de negocio
- [mobile/README.md](../mobile/README.md) — app Flutter
- PDF requisitos en la raíz del repositorio

---

## CI / tests

Pipeline en `.github/workflows/ci.yml`:

- `mvn test` — backend (OperadorContext, VentaService, AsientoLayoutUtil)
- `npm run build` — frontend TypeScript + Vite
- `flutter test` — app móvil

Ejecutar localmente:

```powershell
cd backend && mvn test
cd frontend && npm install && npm run build
cd mobile && flutter test
```
