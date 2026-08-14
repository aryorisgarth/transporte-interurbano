package com.bluefields.transporte.dto.externo;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import java.util.Map;

@JsonIgnoreProperties(ignoreUnknown = true)
public record ExchangeRateApiResponse(
        String base,
        Map<String, Double> rates,
        String date
) {}
