package com.bluefields.transporte.dto.empresa;

import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import java.math.BigDecimal;

public record EmpresaRequest(
        @NotBlank(message = "El nombre es obligatorio") String nombre,
        String telefono,
        @Email(message = "Correo invalido") String correo,
        @DecimalMin(value = "0.0", message = "La tarifa de equipaje extra no puede ser negativa")
        BigDecimal tarifaEquipajeExtra,
        String logoUrl
) {}
