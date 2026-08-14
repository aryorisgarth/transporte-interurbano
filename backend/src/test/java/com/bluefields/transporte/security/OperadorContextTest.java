package com.bluefields.transporte.security;

import com.bluefields.transporte.domain.entity.Empresa;
import com.bluefields.transporte.domain.entity.Usuario;
import com.bluefields.transporte.exception.ReglaNegocioException;
import com.bluefields.transporte.repository.UsuarioRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.security.oauth2.server.resource.authentication.JwtAuthenticationToken;

import java.util.Optional;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class OperadorContextTest {

    @Mock
    private UsuarioRepository usuarioRepository;

    private OperadorContext operadorContext;

    @BeforeEach
    void setUp() {
        operadorContext = new OperadorContext(usuarioRepository, true);
        SecurityContextHolder.clearContext();
    }

    @Test
    void adminEmpresa_soloPuedeOperarSuTenant() {
        autenticarComo("admin.wendelyn");
        Usuario u = usuarioConEmpresa(1L, "Wendelyn");
        when(usuarioRepository.findByNombreUsuarioWithEmpresa("admin.wendelyn"))
                .thenReturn(Optional.of(u));

        assertEquals(1L, operadorContext.resolverEmpresaId(null));
        assertEquals(1L, operadorContext.resolverEmpresaId(1L));

        ReglaNegocioException ex = assertThrows(
                ReglaNegocioException.class,
                () -> operadorContext.resolverEmpresaId(2L)
        );
        assertTrue(ex.getMessage().contains("tenant aislado"));
    }

    @Test
    void adminGlobal_puedeOperarCualquierTenant() {
        autenticarComo("admin.global");
        Usuario u = new Usuario();
        u.setActivo(true);
        u.setNombreUsuario("admin.global");
        when(usuarioRepository.findByNombreUsuarioWithEmpresa("admin.global"))
                .thenReturn(Optional.of(u));

        assertEquals(2L, operadorContext.resolverEmpresaId(2L));
    }

    private static Usuario usuarioConEmpresa(Long id, String nombre) {
        Empresa e = new Empresa();
        e.setId(id);
        e.setNombre(nombre);
        e.setActivo(true);
        Usuario u = new Usuario();
        u.setActivo(true);
        u.setEmpresa(e);
        return u;
    }

    private static void autenticarComo(String username) {
        Jwt jwt = Jwt.withTokenValue("test")
                .header("alg", "none")
                .claim("preferred_username", username)
                .build();
        SecurityContextHolder.getContext().setAuthentication(new JwtAuthenticationToken(jwt));
    }
}
