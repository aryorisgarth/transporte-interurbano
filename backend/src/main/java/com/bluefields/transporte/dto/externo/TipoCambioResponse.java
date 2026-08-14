package com.bluefields.transporte.dto.externo;

import java.math.BigDecimal;

public record TipoCambioResponse(
        String monedaOrigen,
        String monedaDestino,
        BigDecimal tasa,
        String fechaFuente,
        String fuente
) {}
