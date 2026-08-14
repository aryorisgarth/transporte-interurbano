package com.bluefields.transporte.dto.bus;

import com.bluefields.transporte.domain.enums.PosicionAsiento;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotNull;

public record AsientoUpdateRequest(
        @NotNull @Min(1) Integer numero,
        @NotNull @Min(1) Integer fila,
        @NotNull PosicionAsiento posicion
) {}
