package com.bluefields.transporte.dto.viaje;

import com.bluefields.transporte.domain.enums.EstadoViaje;
import java.math.BigDecimal;
import java.time.Instant;
import java.time.LocalDate;
import java.time.LocalTime;

public record ViajeResponse(
        Long id,
        Long empresaId,
        String empresaNombre,
        Long busId,
        String busNumeroInterno,
        String origen,
        String destino,
        LocalDate fecha,
        LocalTime horaSalida,
        BigDecimal tarifa,
        BigDecimal tarifaEquipajeExtra,
        EstadoViaje estado,
        long asientosDisponibles,
        Instant createdAt
) {}
