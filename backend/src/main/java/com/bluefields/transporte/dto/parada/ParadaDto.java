package com.bluefields.transporte.dto.parada;

public class ParadaDto {

    public record ParadaResponse(
            Long id,
            String nombre,
            Integer orden,
            Integer minutosDesdeSalida,
            String horaEstimada,
            Double latitud,
            Double longitud
    ) {}
}
