package com.bluefields.transporte.dto.bus;

import com.bluefields.transporte.domain.enums.PosicionAsiento;
import java.util.List;

public record BusResponse(
        Long id,
        Long empresaId,
        String numeroInterno,
        String placa,
        Integer capacidad,
        Integer filas,
        Boolean activo,
        String fotoUrl,
        String sede,
        List<AsientoResponse> asientos
) {
    public record AsientoResponse(
            Long id,
            Integer numero,
            Integer fila,
            PosicionAsiento posicion
    ) {}
}
