package com.bluefields.transporte.config;

import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.context.annotation.Primary;
import org.springframework.context.annotation.Profile;
import org.springframework.security.oauth2.core.OAuth2Error;
import org.springframework.security.oauth2.core.OAuth2TokenValidator;
import org.springframework.security.oauth2.core.OAuth2TokenValidatorResult;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.security.oauth2.jwt.JwtDecoder;
import org.springframework.security.oauth2.jwt.JwtTimestampValidator;
import org.springframework.security.oauth2.jwt.NimbusJwtDecoder;
import org.springframework.security.oauth2.core.DelegatingOAuth2TokenValidator;

import java.util.List;

/**
 * En desarrollo, Flutter Web usa 127.0.0.1:8180 y React usa localhost:8180.
 * Keycloak incluye el host usado en el claim {@code iss}; ambos deben ser validos.
 */
@Configuration
@Profile("dev")
public class DevJwtDecoderConfig {

    private static final String JWK_SET_URI =
            "http://127.0.0.1:8180/realms/transporte-bluefields/protocol/openid-connect/certs";

    private static final List<String> ISSUERS_PERMITIDOS = List.of(
            "http://127.0.0.1:8180/realms/transporte-bluefields",
            "http://localhost:8180/realms/transporte-bluefields",
            "http://10.0.2.2:8180/realms/transporte-bluefields"
    );

    @Bean
    @Primary
    JwtDecoder jwtDecoder() {
        NimbusJwtDecoder decoder = NimbusJwtDecoder.withJwkSetUri(JWK_SET_URI).build();

        OAuth2TokenValidator<Jwt> issuerValidator = jwt -> {
            String iss = jwt.getIssuer().toString();
            if (ISSUERS_PERMITIDOS.contains(iss)) {
                return OAuth2TokenValidatorResult.success();
            }
            return OAuth2TokenValidatorResult.failure(
                    new OAuth2Error("invalid_token", "Issuer no permitido: " + iss, null)
            );
        };

        decoder.setJwtValidator(new DelegatingOAuth2TokenValidator<>(
                new JwtTimestampValidator(),
                issuerValidator
        ));

        return decoder;
    }
}
