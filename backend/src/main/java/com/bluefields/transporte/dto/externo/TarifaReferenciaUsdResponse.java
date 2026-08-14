package com.bluefields.transporte.dto.externo;

import java.math.BigDecimal;

public record TarifaReferenciaUsdResponse(
        BigDecimal montoCordobas,
        BigDecimal tasaNioUsd,
        BigDecimal equivalenteUsd,
        String fechaFuente,
        String fuente
) {}
