package com.bluefields.transporte.dto.empresa;

import java.util.List;

public record DetalleCooperativaResponse(
        EmpresaResponse empresa,
        MetricasCooperativa metricas,
        List<OperadorCooperativaResponse> operadores,
        List<BusCooperativaResponse> buses
) {
    public record MetricasCooperativa(
            int busesActivos,
            int busesInactivos,
            int adminsActivos,
            int adminsInactivos,
            int cajerosActivos,
            int cajerosInactivos,
            int viajesHoy,
            int boletosVendidosHoy
    ) {}

    public record OperadorCooperativaResponse(
            Long id,
            String nombreUsuario,
            String emailLogin,
            String nombreCompleto,
            String sede,
            Boolean activo,
            List<String> roles
    ) {}

    public record BusCooperativaResponse(
            Long id,
            String numeroInterno,
            String placa,
            String sede,
            int capacidad,
            Boolean activo
    ) {}
}
