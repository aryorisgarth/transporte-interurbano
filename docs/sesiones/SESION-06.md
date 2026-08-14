# Sesion 6 – API externa + WebClient

## Objetivos

- Consumir API externa con **WebClient**
- Exponer datos utiles al frontend
- Manejar errores HTTP, timeout y respuestas vacias

## Integracion elegida

**ExchangeRate-API** (gratuita, sin API key):
- URL: `https://api.exchangerate-api.com/v4/latest/NIO`
- Uso: mostrar referencia en **USD** de la tarifa en cordobas

Ejemplo: tarifa C$ 500 → ~USD 13.50 (tasa variable)

## Endpoints propios

| Metodo | Ruta | Descripcion |
|--------|------|-------------|
| GET | `/api/externo/tipo-cambio/usd` | Tasa NIO → USD del dia |
| GET | `/api/externo/tarifa-referencia-usd?monto=500` | Convierte tarifa a USD |

Acceso **publico** (sin token), util para consulta de pasajeros.

## Probar

```powershell
curl http://localhost:8080/api/externo/tipo-cambio/usd

curl "http://localhost:8080/api/externo/tarifa-referencia-usd?monto=500"
```

Respuesta ejemplo:
```json
{
  "montoCordobas": 500,
  "tasaNioUsd": 0.0272,
  "equivalenteUsd": 13.60,
  "fechaFuente": "2026-06-25",
  "fuente": "exchangerate-api"
}
```

## Manejo de errores

| Situacion | HTTP | Respuesta |
|-----------|------|-----------|
| API externa caida | 502 Bad Gateway | `{ "servicio": "exchangerate-api", "message": "..." }` |
| Timeout (5s) | 502 | Mismo formato |
| HTTP 4xx/5xx externo | 502 | Incluye codigo HTTP |

Implementacion: `ExternalApiException` + `GlobalExceptionHandler`

## Archivos clave

| Archivo | Rol |
|---------|-----|
| `config/WebClientConfig.java` | Bean WebClient + timeout |
| `service/externo/TipoCambioExternoService.java` | Llamada HTTP |
| `controller/ExternoController.java` | Expone `/api/externo/**` |
| `exception/ExternalApiException.java` | Error de integracion |

## Configuracion

`application-dev.yml`:
```yaml
transporte:
  externo:
    tipo-cambio:
      url: https://api.exchangerate-api.com/v4/latest/NIO
    timeout-segundos: 5
```

## Entregable sesion 6

- [ ] GET tipo-cambio devuelve tasa NIO/USD
- [ ] GET tarifa-referencia convierte monto correctamente
- [ ] Timeout/ error externo retorna 502 con mensaje claro
- [ ] WebClient configurado con bean reutilizable

Anterior: [Sesion 5](SESION-05.md)  
Siguiente: [Sesion 7](SESION-07.md) – JHipster + JDL
