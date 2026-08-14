package com.bluefields.transporte.config;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.core.convert.converter.Converter;
import org.springframework.security.authentication.AbstractAuthenticationToken;
import org.springframework.security.config.annotation.method.configuration.EnableMethodSecurity;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.config.annotation.web.configuration.EnableWebSecurity;
import org.springframework.security.config.http.SessionCreationPolicy;
import org.springframework.security.core.GrantedAuthority;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.security.oauth2.server.resource.authentication.JwtAuthenticationConverter;
import org.springframework.security.web.SecurityFilterChain;

import java.util.Collection;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

@Configuration
@EnableWebSecurity
@EnableMethodSecurity
public class SecurityConfig {

    @Bean
    public SecurityFilterChain securityFilterChain(
            HttpSecurity http,
            @Value("${transporte.security.enabled:true}") boolean securityEnabled
    ) throws Exception {
        http.csrf(csrf -> csrf.disable());
        http.sessionManagement(s -> s.sessionCreationPolicy(SessionCreationPolicy.STATELESS));

        if (!securityEnabled) {
            http.authorizeHttpRequests(auth -> auth.anyRequest().permitAll());
            return http.build();
        }

        http.authorizeHttpRequests(auth -> auth
                .requestMatchers(
                        "/api/health",
                        "/api/auth/**",
                        "/api/publico/**",
                        "/api/externo/**",
                        "/swagger-ui/**",
                        "/swagger-ui.html",
                        "/v3/api-docs/**",
                        "/api-docs/**"
                ).permitAll()
                .requestMatchers(org.springframework.http.HttpMethod.POST, "/api/empresas")
                .hasRole("ADMIN_GENERAL")
                .requestMatchers(org.springframework.http.HttpMethod.PUT, "/api/empresas/**")
                .hasAnyRole("ADMIN_GENERAL", "ADMIN_EMPRESA")
                .requestMatchers(org.springframework.http.HttpMethod.PATCH, "/api/empresas/**")
                .hasAnyRole("ADMIN_GENERAL", "ADMIN_EMPRESA")
                .requestMatchers(org.springframework.http.HttpMethod.PUT, "/api/buses/**")
                .hasAnyRole("ADMIN_EMPRESA", "ADMIN_GENERAL")
                .requestMatchers(org.springframework.http.HttpMethod.POST, "/api/buses")
                .hasAnyRole("ADMIN_EMPRESA", "ADMIN_GENERAL")
                .requestMatchers(org.springframework.http.HttpMethod.POST, "/api/ventas")
                .hasAnyRole("CAJERO", "ADMIN_EMPRESA", "ADMIN_GENERAL")
                .requestMatchers("/api/pasajeros/**")
                .hasAnyRole("CAJERO", "ADMIN_EMPRESA", "ADMIN_GENERAL")
                .requestMatchers(org.springframework.http.HttpMethod.POST, "/api/reservas-excepcionales")
                .hasAnyRole("RESERVA_EXCEPCIONAL", "ADMIN_EMPRESA", "ADMIN_GENERAL")
                .requestMatchers(org.springframework.http.HttpMethod.POST, "/api/usuarios")
                .hasAnyRole("ADMIN_EMPRESA", "ADMIN_GENERAL")
                .requestMatchers(org.springframework.http.HttpMethod.PATCH, "/api/usuarios/**")
                .hasAnyRole("ADMIN_EMPRESA", "ADMIN_GENERAL")
                .requestMatchers(org.springframework.http.HttpMethod.GET, "/api/usuarios")
                .hasAnyRole("ADMIN_EMPRESA", "ADMIN_GENERAL")
                .requestMatchers(org.springframework.http.HttpMethod.POST, "/api/paradas")
                .hasAnyRole("ADMIN_EMPRESA", "ADMIN_GENERAL")
                .requestMatchers(org.springframework.http.HttpMethod.PUT, "/api/paradas/**")
                .hasAnyRole("ADMIN_EMPRESA", "ADMIN_GENERAL")
                .requestMatchers(org.springframework.http.HttpMethod.DELETE, "/api/paradas/**")
                .hasAnyRole("ADMIN_EMPRESA", "ADMIN_GENERAL")
                .requestMatchers("/api/reportes/**")
                .hasAnyRole("CAJERO", "ADMIN_EMPRESA", "ADMIN_GENERAL")
                .requestMatchers("/api/paradas/**")
                .hasAnyRole("CAJERO", "ADMIN_EMPRESA", "ADMIN_GENERAL")
                .requestMatchers(
                        "/api/buses/**",
                        "/api/viajes/**",
                        "/api/ventas/**",
                        "/api/reservas-excepcionales/**",
                        "/api/paradas/**",
                        "/api/usuarios/**",
                        "/api/empresas/**"
                ).authenticated()
                .anyRequest().authenticated()
        );

        http.oauth2ResourceServer(oauth2 -> oauth2
                .jwt(jwt -> jwt.jwtAuthenticationConverter(keycloakJwtConverter()))
        );

        return http.build();
    }

    private Converter<Jwt, AbstractAuthenticationToken> keycloakJwtConverter() {
        JwtAuthenticationConverter converter = new JwtAuthenticationConverter();
        converter.setJwtGrantedAuthoritiesConverter(this::extractKeycloakRoles);
        return converter;
    }

    @SuppressWarnings("unchecked")
    private Collection<GrantedAuthority> extractKeycloakRoles(Jwt jwt) {
        Map<String, Object> realmAccess = jwt.getClaim("realm_access");
        if (realmAccess == null || realmAccess.get("roles") == null) {
            return List.of();
        }

        List<String> roles = (List<String>) realmAccess.get("roles");
        return roles.stream()
                .map(role -> (GrantedAuthority) new SimpleGrantedAuthority("ROLE_" + role))
                .collect(Collectors.toList());
    }
}
