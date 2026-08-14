package com.bluefields.transporte.dto.pasajero;

import java.time.LocalDate;

public class PasajeroDto {

    public record ManifiestoPasajeroResponse(
            Long boletoId,
            Long viajeId,
            LocalDate fechaViaje,
            String horaSalida,
            String origen,
            String destino,
            String busNumeroInterno,
            String busPlaca,
            Integer numeroAsiento,
            String pasajeroNombre,
            String pasajeroCedula,
            String pasajeroTelefono,
            String codigoVenta,
            String operadorNombre,
            String estadoBoleto,
            Boolean esMenor
    ) {}
}
