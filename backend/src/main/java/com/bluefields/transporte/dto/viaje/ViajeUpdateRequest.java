package com.bluefields.transporte.dto.viaje;

import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.Size;

import java.math.BigDecimal;
import java.time.LocalTime;

public record ViajeUpdateRequest(
        LocalTime horaSalida,
        @DecimalMin("0.0") BigDecimal tarifa,
        @DecimalMin("0.0") BigDecimal tarifaEquipajeExtra,
        @Size(max = 500) String observaciones
) {}
