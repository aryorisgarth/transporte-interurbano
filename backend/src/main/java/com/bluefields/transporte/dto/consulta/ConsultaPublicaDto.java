package com.bluefields.transporte.dto.consulta;

import com.bluefields.transporte.domain.enums.EstadoAsientoViaje;
import com.bluefields.transporte.domain.enums.PosicionAsiento;
import com.bluefields.transporte.dto.parada.ParadaDto;
import jakarta.validation.constraints.NotNull;
import java.time.LocalDate;
import java.util.List;

public class ConsultaPublicaDto {

    public record ConsultaRequest(
            String origen,
            String destino,
            @NotNull LocalDate fecha
    ) {}

    public record ViajeDisponibleResponse(
            Long viajeId,
            String empresaNombre,
            String empresaLogoUrl,
            String horaSalida,
            long asientosDisponibles,
            long capacidadTotal,
            java.math.BigDecimal tarifa
    ) {}

    public record AsientoDisponibleResponse(
            Long viajeAsientoId,
            Integer numero,
            Integer fila,
            PosicionAsiento posicion,
            EstadoAsientoViaje estado
    ) {}

    public record DetalleViajeResponse(
            Long viajeId,
            String empresaNombre,
            String empresaLogoUrl,
            String busNumeroInterno,
            String busFotoUrl,
            String origen,
            String destino,
            LocalDate fecha,
            String horaSalida,
            java.math.BigDecimal tarifa,
            java.math.BigDecimal tarifaEquipajeExtra,
            long asientosDisponibles,
            List<AsientoDisponibleResponse> asientos,
            List<ParadaDto.ParadaResponse> paradas
    ) {}
}
