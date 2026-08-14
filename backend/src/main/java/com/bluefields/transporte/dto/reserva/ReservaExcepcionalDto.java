package com.bluefields.transporte.dto.reserva;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;

public class ReservaExcepcionalDto {

    public record ReservaRequest(
            @NotNull Long viajeAsientoId,
            @NotBlank @Size(max = 150) String compradorNombre,
            @NotBlank @Size(min = 5, max = 30) String compradorCedula,
            @Size(max = 20) String compradorTelefono,
            @NotBlank @Size(max = 1000) String motivo,
            @NotNull Integer horasExpiracion
    ) {}

    public record ReservaResponse(
            Long id,
            Long viajeAsientoId,
            Integer numeroAsiento,
            Long viajeId,
            String compradorNombre,
            String compradorCedula,
            String motivo,
            String estado,
            String fechaExpiracion
    ) {}
}
