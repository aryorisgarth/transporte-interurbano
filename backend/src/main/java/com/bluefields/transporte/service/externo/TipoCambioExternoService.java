package com.bluefields.transporte.service.externo;

import com.bluefields.transporte.dto.externo.ExchangeRateApiResponse;
import com.bluefields.transporte.dto.externo.TarifaReferenciaUsdResponse;
import com.bluefields.transporte.dto.externo.TipoCambioResponse;
import com.bluefields.transporte.exception.ExternalApiException;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.web.reactive.function.client.WebClient;
import org.springframework.web.reactive.function.client.WebClientResponseException;

import java.math.BigDecimal;
import java.math.RoundingMode;

@Service
public class TipoCambioExternoService {

    private static final Logger log = LoggerFactory.getLogger(TipoCambioExternoService.class);
    private static final String SERVICIO = "exchangerate-api";

    private final WebClient webClient;
    private final String baseUrl;

    public TipoCambioExternoService(
            WebClient.Builder webClientBuilder,
            @Value("${transporte.externo.tipo-cambio.url:https://api.exchangerate-api.com/v4/latest/NIO}") String baseUrl
    ) {
        this.webClient = webClientBuilder.baseUrl(baseUrl).build();
        this.baseUrl = baseUrl;
    }

    public TipoCambioResponse obtenerTipoCambioUsd() {
        ExchangeRateApiResponse respuesta = consultarApi();
        Double tasaUsd = respuesta.rates().get("USD");

        if (tasaUsd == null) {
            throw new ExternalApiException(SERVICIO, "La API no devolvio tasa USD para NIO");
        }

        return new TipoCambioResponse(
                "NIO",
                "USD",
                BigDecimal.valueOf(tasaUsd).setScale(6, RoundingMode.HALF_UP),
                respuesta.date(),
                SERVICIO
        );
    }

    public TarifaReferenciaUsdResponse convertirTarifaAUsd(BigDecimal montoCordobas) {
        if (montoCordobas == null || montoCordobas.compareTo(BigDecimal.ZERO) < 0) {
            throw new IllegalArgumentException("El monto debe ser mayor o igual a cero");
        }

        TipoCambioResponse tipoCambio = obtenerTipoCambioUsd();
        BigDecimal equivalente = montoCordobas
                .multiply(tipoCambio.tasa())
                .setScale(2, RoundingMode.HALF_UP);

        return new TarifaReferenciaUsdResponse(
                montoCordobas,
                tipoCambio.tasa(),
                equivalente,
                tipoCambio.fechaFuente(),
                tipoCambio.fuente()
        );
    }

    private ExchangeRateApiResponse consultarApi() {
        try {
            log.debug("Consultando tipo de cambio: {}", baseUrl);

            ExchangeRateApiResponse body = webClient.get()
                    .retrieve()
                    .bodyToMono(ExchangeRateApiResponse.class)
                    .block();

            if (body == null || body.rates() == null) {
                throw new ExternalApiException(SERVICIO, "Respuesta vacia de la API de tipo de cambio");
            }

            return body;
        } catch (WebClientResponseException ex) {
            log.warn("Error HTTP API externa status={} body={}", ex.getStatusCode(), ex.getResponseBodyAsString());
            throw new ExternalApiException(
                    SERVICIO,
                    "Error al consultar tipo de cambio: HTTP " + ex.getStatusCode().value()
            );
        } catch (ExternalApiException ex) {
            throw ex;
        } catch (Exception ex) {
            log.error("Fallo consulta API externa", ex);
            throw new ExternalApiException(
                    SERVICIO,
                    "No se pudo contactar el servicio de tipo de cambio. Intente mas tarde.",
                    ex
            );
        }
    }
}
