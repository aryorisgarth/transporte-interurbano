package com.bluefields.transporte.dto.bus;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;

public record BusUpdateRequest(
        @NotBlank String numeroInterno,
        @NotBlank String placa,
        @NotBlank String sede,
        String fotoUrl,
        Boolean activo
) {}
