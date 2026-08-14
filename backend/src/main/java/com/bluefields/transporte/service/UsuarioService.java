package com.bluefields.transporte.service;

import com.bluefields.transporte.domain.entity.Usuario;
import com.bluefields.transporte.dto.usuario.UsuarioResponse;
import com.bluefields.transporte.exception.RecursoNoEncontradoException;
import com.bluefields.transporte.repository.UsuarioRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.Optional;

@Service
@Transactional(readOnly = true)
public class UsuarioService {

    private final UsuarioRepository usuarioRepository;

    public UsuarioService(UsuarioRepository usuarioRepository) {
        this.usuarioRepository = usuarioRepository;
    }

    public Optional<UsuarioResponse> buscar(Long id) {
        return usuarioRepository.findById(id).map(this::toResponse);
    }

    public UsuarioResponse perfilActual(Long usuarioId) {
        return usuarioRepository.findByIdWithEmpresa(usuarioId)
                .map(this::toResponse)
                .orElseThrow(() -> new RecursoNoEncontradoException("Usuario no encontrado: " + usuarioId));
    }

    public UsuarioResponse obtener(Long id) {
        return buscar(id)
                .orElseThrow(() -> new RecursoNoEncontradoException("Usuario no encontrado: " + id));
    }

    public Usuario buscarEntidad(Long id) {
        return usuarioRepository.findById(id)
                .orElseThrow(() -> new RecursoNoEncontradoException("Usuario no encontrado: " + id));
    }

    private UsuarioResponse toResponse(Usuario usuario) {
        var roles = usuario.getRoles().stream()
                .map(r -> r.getNombre())
                .sorted()
                .toList();

        Long empresaId = usuario.getEmpresa() != null ? usuario.getEmpresa().getId() : null;
        String empresaNombre = usuario.getEmpresa() != null ? usuario.getEmpresa().getNombre() : null;

        String emailLogin = usuario.getEmailLogin();
        if (emailLogin == null || emailLogin.isBlank()) {
            emailLogin = usuario.getNombreUsuario() + "@transporte.local";
        }

        return new UsuarioResponse(
                usuario.getId(),
                empresaId,
                empresaNombre,
                usuario.getNombreUsuario(),
                emailLogin,
                usuario.getNombreCompleto(),
                usuario.getSede(),
                usuario.getActivo(),
                roles
        );
    }
}
