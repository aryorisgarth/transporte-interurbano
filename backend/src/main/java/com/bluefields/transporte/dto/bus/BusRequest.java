package com.bluefields.transporte.dto.bus;

import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;

public record BusRequest(
        @NotNull Long empresaId,
        @NotBlank String numeroInterno,
        @NotBlank String placa,
        @NotNull @Min(2) Integer capacidad,
        @NotBlank String sede,
        String fotoUrl
) {}
