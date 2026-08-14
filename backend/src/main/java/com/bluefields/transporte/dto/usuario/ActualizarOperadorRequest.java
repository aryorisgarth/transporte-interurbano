package com.bluefields.transporte.dto.usuario;

import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;

public record ActualizarOperadorRequest(
        Boolean activo,
        @Size(max = 150) String nombreCompleto,
        @Size(max = 100) String sede,
        Boolean reservaExcepcional
) {
    /** Compatibilidad: solo activo */
    public ActualizarOperadorRequest(@NotNull Boolean activo) {
        this(activo, null, null, null);
    }
}
