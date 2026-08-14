package com.bluefields.transporte.dto.parada;

import jakarta.validation.constraints.DecimalMax;
import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;

import java.math.BigDecimal;

public record ParadaCreateRequest(
        @NotBlank @Size(max = 100) String origen,
        @NotBlank @Size(max = 100) String destino,
        @NotBlank @Size(max = 120) String nombre,
        @NotNull @Min(0) Integer minutosDesdeSalida,
        @NotNull @DecimalMin("-90.0") @DecimalMax("90.0") BigDecimal latitud,
        @NotNull @DecimalMin("-180.0") @DecimalMax("180.0") BigDecimal longitud
) {}
