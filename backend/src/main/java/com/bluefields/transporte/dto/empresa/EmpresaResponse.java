package com.bluefields.transporte.dto.empresa;

import java.math.BigDecimal;
import java.time.Instant;

public record EmpresaResponse(
        Long id,
        String nombre,
        String telefono,
        String correo,
        BigDecimal tarifaEquipajeExtra,
        String logoUrl,
        Boolean activo,
        Instant createdAt,
        Instant updatedAt
) {}
