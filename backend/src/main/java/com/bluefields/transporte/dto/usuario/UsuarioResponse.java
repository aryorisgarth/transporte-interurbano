package com.bluefields.transporte.dto.usuario;

import java.util.List;

public record UsuarioResponse(
        Long id,
        Long empresaId,
        String empresaNombre,
        String nombreUsuario,
        String emailLogin,
        String nombreCompleto,
        String sede,
        Boolean activo,
        List<String> roles
) {}
