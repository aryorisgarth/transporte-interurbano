package com.bluefields.transporte.service;

import com.bluefields.transporte.domain.entity.Empresa;
import com.bluefields.transporte.domain.entity.Rol;
import com.bluefields.transporte.domain.entity.Usuario;
import com.bluefields.transporte.dto.usuario.ActualizarOperadorRequest;
import com.bluefields.transporte.dto.usuario.CrearOperadorRequest;
import com.bluefields.transporte.dto.usuario.UsuarioResponse;
import com.bluefields.transporte.exception.RecursoNoEncontradoException;
import com.bluefields.transporte.exception.ReglaNegocioException;
import com.bluefields.transporte.repository.RolRepository;
import com.bluefields.transporte.repository.UsuarioRepository;
import com.bluefields.transporte.security.OperadorContext;
import com.bluefields.transporte.util.CorredorUtil;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.HashSet;
import java.util.List;
import java.util.Locale;
import java.util.Set;
import java.util.stream.Collectors;

@Service
@Transactional
public class OperadorService {

    private static final Logger log = LoggerFactory.getLogger(OperadorService.class);

    private static final Set<String> ROLES_PERMITIDOS = Set.of(
            "CAJERO", "ADMIN_EMPRESA", "RESERVA_EXCEPCIONAL"
    );

    private static final Set<String> ROLES_OPERATIVOS = Set.of("CAJERO", "ADMIN_EMPRESA");

    private final UsuarioRepository usuarioRepository;
    private final RolRepository rolRepository;
    private final EmpresaService empresaService;
    private final OperadorContext operadorContext;
    private final KeycloakAdminService keycloakAdminService;

    public OperadorService(
            UsuarioRepository usuarioRepository,
            RolRepository rolRepository,
            EmpresaService empresaService,
            OperadorContext operadorContext,
            KeycloakAdminService keycloakAdminService
    ) {
        this.usuarioRepository = usuarioRepository;
        this.rolRepository = rolRepository;
        this.empresaService = empresaService;
        this.operadorContext = operadorContext;
        this.keycloakAdminService = keycloakAdminService;
    }

    @Transactional(readOnly = true)
    public List<UsuarioResponse> listarPorEmpresa(Long empresaIdRequest) {
        Long empresaId = operadorContext.resolverEmpresaId(empresaIdRequest);
        return usuarioRepository.findByEmpresaIdOrderByNombreCompletoAsc(empresaId).stream()
                .map(this::toResponse)
                .toList();
    }

    public UsuarioResponse crear(CrearOperadorRequest request) {
        Usuario operadorActual = operadorContext.resolverOperador(null);
        boolean esGlobal = operadorActual.getEmpresa() == null;

        Long empresaId = operadorContext.resolverEmpresaId(request.empresaId());
        Empresa empresa = empresaService.buscarEntidad(empresaId);

        String username = request.nombreUsuario().trim().toLowerCase(Locale.ROOT);
        if (usuarioRepository.existsByNombreUsuario(username)) {
            throw new ReglaNegocioException("Ya existe un operador con ese nombre de usuario");
        }

        List<String> rolesSolicitados = normalizarRoles(request.roles());
        validarRoles(rolesSolicitados, esGlobal);

        String sede = request.sede() != null ? request.sede().trim() : null;
        if (rolesSolicitados.contains("CAJERO")) {
            if (sede == null || sede.isBlank()) {
                throw new ReglaNegocioException("Debe indicar la terminal (sede) del cajero");
            }
            CorredorUtil.validarCiudad(sede);
        } else {
            sede = null;
        }

        String email = request.email();
        if (email == null || email.isBlank()) {
            email = username + "@transporte.local";
        }

        String keycloakId = keycloakAdminService.crearUsuario(
                username,
                request.password(),
                request.nombreCompleto().trim(),
                email,
                rolesSolicitados
        );

        Usuario usuario = new Usuario();
        usuario.setEmpresa(empresa);
        usuario.setKeycloakId(keycloakId);
        usuario.setNombreUsuario(username);
        usuario.setNombreCompleto(request.nombreCompleto().trim());
        usuario.setEmailLogin(email.trim());
        usuario.setSede(sede);
        usuario.setActivo(true);
        usuario.setRoles(new HashSet<>(cargarRoles(rolesSolicitados)));

        Usuario guardado = usuarioRepository.save(usuario);
        log.info("Operador creado id={} username={} empresaId={}", guardado.getId(), username, empresaId);

        return toResponse(guardado);
    }

    public UsuarioResponse actualizar(Long id, ActualizarOperadorRequest request) {
        Usuario usuario = usuarioRepository.findByIdWithEmpresa(id)
                .orElseThrow(() -> new RecursoNoEncontradoException("Operador no encontrado: " + id));

        operadorContext.validarAccesoEmpresa(
                usuario.getEmpresa() != null ? usuario.getEmpresa().getId() : null
        );

        if (usuario.getEmpresa() == null) {
            throw new ReglaNegocioException("No puede modificar usuarios de plataforma desde este panel");
        }

        boolean esCajero = usuario.tieneRol("CAJERO") && !usuario.tieneRol("ADMIN_EMPRESA");

        if (request.nombreCompleto() != null && !request.nombreCompleto().isBlank()) {
            usuario.setNombreCompleto(request.nombreCompleto().trim());
            keycloakAdminService.actualizarPerfil(usuario.getKeycloakId(), usuario.getNombreCompleto());
        }

        if (request.sede() != null) {
            if (!esCajero) {
                throw new ReglaNegocioException("La terminal solo aplica a cajeros");
            }
            CorredorUtil.validarCiudad(request.sede().trim());
            usuario.setSede(request.sede().trim());
        }

        if (request.activo() != null) {
            usuario.setActivo(request.activo());
            keycloakAdminService.actualizarActivo(usuario.getKeycloakId(), request.activo());
        }

        if (request.reservaExcepcional() != null) {
            boolean tiene = usuario.tieneRol("RESERVA_EXCEPCIONAL");
            if (request.reservaExcepcional() && !tiene) {
                usuario.getRoles().addAll(cargarRoles(List.of("RESERVA_EXCEPCIONAL")));
                keycloakAdminService.asignarRolReservaExcepcional(usuario.getKeycloakId(), true);
            } else if (!request.reservaExcepcional() && tiene) {
                usuario.getRoles().removeIf(r -> "RESERVA_EXCEPCIONAL".equals(r.getNombre()));
                keycloakAdminService.asignarRolReservaExcepcional(usuario.getKeycloakId(), false);
            }
        }

        return toResponse(usuarioRepository.save(usuario));
    }

    /** @deprecated use actualizar */
    public UsuarioResponse actualizarActivo(Long id, ActualizarOperadorRequest request) {
        return actualizar(id, request);
    }

    private List<String> normalizarRoles(List<String> roles) {
        return roles.stream()
                .map(r -> r.trim().toUpperCase(Locale.ROOT))
                .distinct()
                .toList();
    }

    private void validarRoles(List<String> roles, boolean esGlobal) {
        for (String rol : roles) {
            if (!ROLES_PERMITIDOS.contains(rol)) {
                throw new ReglaNegocioException("Rol no permitido: " + rol);
            }
        }

        if (esGlobal) {
            if (roles.contains("CAJERO") || roles.contains("RESERVA_EXCEPCIONAL")) {
                throw new ReglaNegocioException(
                        "El admin de plataforma solo puede asignar ADMIN_EMPRESA. "
                                + "Los cajeros los registra el administrador de cada cooperativa."
                );
            }
            if (!roles.contains("ADMIN_EMPRESA")) {
                throw new ReglaNegocioException("Debe asignar rol ADMIN_EMPRESA al dar acceso a una cooperativa");
            }
            return;
        }

        boolean tieneOperativo = roles.stream().anyMatch(ROLES_OPERATIVOS::contains);
        if (!tieneOperativo) {
            throw new ReglaNegocioException("Debe asignar al menos CAJERO o ADMIN_EMPRESA");
        }
    }

    private Set<Rol> cargarRoles(List<String> nombres) {
        List<Rol> roles = rolRepository.findByNombreIn(nombres);
        if (roles.size() != nombres.size()) {
            Set<String> encontrados = roles.stream().map(Rol::getNombre).collect(Collectors.toSet());
            String faltantes = nombres.stream()
                    .filter(n -> !encontrados.contains(n))
                    .collect(Collectors.joining(", "));
            throw new ReglaNegocioException("Roles no registrados en el sistema: " + faltantes);
        }
        return new HashSet<>(roles);
    }

    private UsuarioResponse toResponse(Usuario usuario) {
        var roles = usuario.getRoles().stream()
                .map(Rol::getNombre)
                .sorted()
                .toList();

        Long empresaId = usuario.getEmpresa() != null ? usuario.getEmpresa().getId() : null;
        String empresaNombre = usuario.getEmpresa() != null ? usuario.getEmpresa().getNombre() : null;

        return new UsuarioResponse(
                usuario.getId(),
                empresaId,
                empresaNombre,
                usuario.getNombreUsuario(),
                usuario.getEmailLogin(),
                usuario.getNombreCompleto(),
                usuario.getSede(),
                usuario.getActivo(),
                roles
        );
    }
}
