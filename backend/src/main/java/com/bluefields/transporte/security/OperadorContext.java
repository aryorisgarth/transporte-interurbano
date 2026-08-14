package com.bluefields.transporte.security;

import com.bluefields.transporte.domain.entity.Usuario;
import com.bluefields.transporte.exception.ReglaNegocioException;
import com.bluefields.transporte.repository.UsuarioRepository;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.stereotype.Component;

@Component
public class OperadorContext {

    private final UsuarioRepository usuarioRepository;
    private final boolean securityEnabled;

    public OperadorContext(
            UsuarioRepository usuarioRepository,
            @Value("${transporte.security.enabled:true}") boolean securityEnabled
    ) {
        this.usuarioRepository = usuarioRepository;
        this.securityEnabled = securityEnabled;
    }

    public Usuario resolverOperador(Long operadorIdFallback) {
        if (!securityEnabled) {
            return resolverPorId(operadorIdFallback);
        }

        Authentication auth = SecurityContextHolder.getContext().getAuthentication();
        if (auth != null && auth.getPrincipal() instanceof Jwt jwt) {
            String username = jwt.getClaimAsString("preferred_username");
            if (username == null) {
                username = jwt.getSubject();
            }
            final String resolvedUsername = username;
            return usuarioRepository.findByNombreUsuarioWithEmpresa(resolvedUsername)
                    .filter(u -> Boolean.TRUE.equals(u.getActivo()))
                    .orElseThrow(() -> new ReglaNegocioException(
                            "Usuario autenticado no registrado en el sistema: " + resolvedUsername
                    ));
        }

        return resolverPorId(operadorIdFallback);
    }

    /**
     * Admin general (sin empresa) puede operar cualquier tenant.
     * Cajero / admin empresa solo su cooperativa.
     */
    /**
     * Admin general (sin empresa en BD): usa el empresaId del request.
     * Admin/cajero de empresa: solo su tenant; ignora intentos de cruzar datos.
     */
    public Long resolverEmpresaId(Long empresaIdRequest) {
        Usuario operador = resolverOperador(null);
        if (operador.getEmpresa() == null) {
            if (empresaIdRequest == null) {
                throw new ReglaNegocioException("Debe indicar empresaId");
            }
            return empresaIdRequest;
        }
        Long tenantId = operador.getEmpresa().getId();
        if (empresaIdRequest != null && !empresaIdRequest.equals(tenantId)) {
            throw new ReglaNegocioException(
                    "Acceso denegado: no puede operar sobre otra empresa (tenant aislado)"
            );
        }
        return tenantId;
    }

    public void validarAccesoEmpresa(Long empresaId) {
        if (!securityEnabled || empresaId == null) {
            return;
        }
        Usuario operador = resolverOperador(null);
        if (operador.getEmpresa() == null) {
            return;
        }
        if (!operador.getEmpresa().getId().equals(empresaId)) {
            throw new ReglaNegocioException(
                    "No tiene permiso para operar sobre la empresa id=" + empresaId
            );
        }
    }

    private Usuario resolverPorId(Long operadorId) {
        if (operadorId == null) {
            throw new ReglaNegocioException("Debe indicar operadorId o autenticarse con Keycloak");
        }
        return usuarioRepository.findByIdWithEmpresa(operadorId)
                .filter(u -> Boolean.TRUE.equals(u.getActivo()))
                .orElseThrow(() -> new ReglaNegocioException("Operador no encontrado: " + operadorId));
    }
}
