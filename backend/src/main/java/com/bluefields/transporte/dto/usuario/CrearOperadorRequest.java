package com.bluefields.transporte.dto.usuario;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotEmpty;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;

import java.util.List;

public record CrearOperadorRequest(
        @NotNull Long empresaId,
        @NotBlank @Size(max = 50) String nombreUsuario,
        @NotBlank @Size(max = 150) String nombreCompleto,
        @NotBlank @Size(min = 6, max = 100) String password,
        @NotEmpty List<@NotBlank String> roles,
        @Size(max = 120) String email,
        @Size(max = 100) String sede
) {}
