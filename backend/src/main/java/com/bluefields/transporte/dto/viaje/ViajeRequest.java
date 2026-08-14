package com.bluefields.transporte.dto.viaje;

import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalTime;

public record ViajeRequest(
        @NotNull Long empresaId,
        @NotNull Long busId,
        @NotBlank String origen,
        @NotBlank String destino,
        @NotNull LocalDate fecha,
        @NotNull LocalTime horaSalida,
        @NotNull @DecimalMin("0.0") BigDecimal tarifa,
        @DecimalMin("0.0") BigDecimal tarifaEquipajeExtra
) {}
