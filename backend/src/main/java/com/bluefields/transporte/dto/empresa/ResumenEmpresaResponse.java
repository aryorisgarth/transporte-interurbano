package com.bluefields.transporte.dto.empresa;

public record ResumenEmpresaResponse(
        Long id,
        String nombre,
        boolean activo,
        int busesActivos,
        int operadoresActivos,
        int viajesHoy,
        int boletosVendidosHoy
) {}
