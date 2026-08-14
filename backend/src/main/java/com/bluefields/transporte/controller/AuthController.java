package com.bluefields.transporte.controller;

import com.bluefields.transporte.config.KeycloakAdminProperties;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.util.LinkedMultiValueMap;
import org.springframework.util.MultiValueMap;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.reactive.function.BodyInserters;
import org.springframework.web.reactive.function.client.WebClient;
import org.springframework.web.reactive.function.client.WebClientResponseException;

import java.util.Map;

/**
 * Proxy de token Keycloak para clientes web (Flutter) que no pueden usar el proxy de Vite.
 * Evita CORS navegador → Keycloak:8080.
 */
@RestController
@RequestMapping("/api/auth")
public class AuthController {

    private static final String CLIENT_ID = "transporte-api";

    private final WebClient webClient;
    private final KeycloakAdminProperties keycloak;

    public AuthController(WebClient.Builder webClientBuilder, KeycloakAdminProperties keycloak) {
        this.webClient = webClientBuilder.build();
        this.keycloak = keycloak;
    }

    public record LoginRequest(String username, String password) {}

    @PostMapping(value = "/token", consumes = MediaType.APPLICATION_JSON_VALUE)
    public ResponseEntity<?> token(@RequestBody LoginRequest body) {
        if (body.username() == null || body.username().isBlank()
                || body.password() == null || body.password().isBlank()) {
            return ResponseEntity.badRequest().body(Map.of("message", "Usuario y contraseña son obligatorios."));
        }

        MultiValueMap<String, String> form = new LinkedMultiValueMap<>();
        form.add("client_id", CLIENT_ID);
        form.add("grant_type", "password");
        form.add("username", body.username().trim());
        form.add("password", body.password());

        String tokenUrl = keycloak.getServerUrl()
                + "/realms/" + keycloak.getRealm()
                + "/protocol/openid-connect/token";

        try {
            @SuppressWarnings("unchecked")
            Map<String, Object> response = webClient.post()
                    .uri(tokenUrl)
                    .contentType(MediaType.APPLICATION_FORM_URLENCODED)
                    .body(BodyInserters.fromFormData(form))
                    .retrieve()
                    .bodyToMono(Map.class)
                    .block();

            if (response == null || response.get("access_token") == null) {
                return ResponseEntity.status(HttpStatus.BAD_GATEWAY)
                        .body(Map.of("message", "Respuesta inválida de Keycloak."));
            }
            return ResponseEntity.ok(response);
        } catch (WebClientResponseException e) {
            String message = "Credenciales inválidas.";
            try {
                @SuppressWarnings("unchecked")
                Map<String, Object> err = e.getResponseBodyAs(Map.class);
                if (err != null) {
                    if ("invalid_grant".equals(err.get("error"))) {
                        message = "Usuario o contraseña incorrectos.";
                    } else if (err.get("error_description") != null) {
                        message = err.get("error_description").toString();
                    }
                }
            } catch (Exception ignored) {
                // usar mensaje genérico
            }
            return ResponseEntity.status(e.getStatusCode()).body(Map.of("message", message));
        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.BAD_GATEWAY)
                    .body(Map.of("message", "No se pudo conectar con Keycloak. Verifique Docker (puerto 8180)."));
        }
    }
}
