package com.bluefields.transporte.service;

import com.bluefields.transporte.config.KeycloakAdminProperties;
import com.bluefields.transporte.exception.ExternalApiException;
import com.fasterxml.jackson.databind.JsonNode;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.stereotype.Service;
import org.springframework.util.LinkedMultiValueMap;
import org.springframework.util.MultiValueMap;
import org.springframework.web.reactive.function.BodyInserters;
import org.springframework.web.reactive.function.client.WebClient;
import org.springframework.web.reactive.function.client.WebClientResponseException;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

@Service
public class KeycloakAdminService {

    private static final Logger log = LoggerFactory.getLogger(KeycloakAdminService.class);

    private final WebClient webClient;
    private final KeycloakAdminProperties props;

    public KeycloakAdminService(WebClient.Builder webClientBuilder, KeycloakAdminProperties props) {
        this.webClient = webClientBuilder.build();
        this.props = props;
    }

    public String crearUsuario(
            String username,
            String password,
            String nombreCompleto,
            String email,
            List<String> realmRoles
    ) {
        if (!props.isEnabled()) {
            throw new ExternalApiException("Keycloak", "Integracion Keycloak deshabilitada");
        }

        String token = obtenerTokenAdmin();
        String[] partes = dividirNombre(nombreCompleto);

        Map<String, Object> body = new HashMap<>();
        body.put("username", username);
        body.put("enabled", true);
        body.put("emailVerified", true);
        body.put("firstName", partes[0]);
        body.put("lastName", partes[1]);
        if (email != null && !email.isBlank()) {
            body.put("email", email.trim());
        }

        String userId;
        try {
            ResponseEntity<Void> response = webClient.post()
                    .uri(adminUrl("/users"))
                    .header(HttpHeaders.AUTHORIZATION, "Bearer " + token)
                    .contentType(MediaType.APPLICATION_JSON)
                    .bodyValue(body)
                    .retrieve()
                    .toBodilessEntity()
                    .block();

            if (response == null || response.getHeaders().getLocation() == null) {
                throw new ExternalApiException("Keycloak", "No se recibio ID del usuario creado");
            }

            String location = response.getHeaders().getLocation().toString();
            userId = location.substring(location.lastIndexOf('/') + 1);
        } catch (WebClientResponseException.Conflict e) {
            throw new ExternalApiException("Keycloak", "El usuario ya existe en Keycloak: " + username);
        } catch (WebClientResponseException e) {
            log.error("Error creando usuario Keycloak: {}", e.getResponseBodyAsString());
            throw new ExternalApiException("Keycloak", "No se pudo crear el usuario en Keycloak");
        }

        try {
            establecerContrasena(token, userId, password);
            asignarRoles(token, userId, realmRoles);
            return userId;
        } catch (RuntimeException ex) {
            deshabilitarUsuario(token, userId);
            throw ex;
        }
    }

    public void actualizarActivo(String keycloakId, boolean activo) {
        if (!props.isEnabled() || keycloakId == null || keycloakId.isBlank()) {
            return;
        }

        String token = obtenerTokenAdmin();
        Map<String, Object> body = Map.of("enabled", activo);

        try {
            webClient.put()
                    .uri(adminUrl("/users/" + keycloakId))
                    .header(HttpHeaders.AUTHORIZATION, "Bearer " + token)
                    .contentType(MediaType.APPLICATION_JSON)
                    .bodyValue(body)
                    .retrieve()
                    .toBodilessEntity()
                    .block();
        } catch (WebClientResponseException e) {
            log.error("Error actualizando usuario Keycloak {}: {}", keycloakId, e.getResponseBodyAsString());
            throw new ExternalApiException("Keycloak", "No se pudo actualizar el usuario en Keycloak");
        }
    }

    public void actualizarPerfil(String keycloakId, String nombreCompleto) {
        if (!props.isEnabled() || keycloakId == null || keycloakId.isBlank()) {
            return;
        }

        String token = obtenerTokenAdmin();
        String[] partes = dividirNombre(nombreCompleto);

        Map<String, Object> body = new HashMap<>();
        body.put("firstName", partes[0]);
        body.put("lastName", partes[1]);

        try {
            webClient.put()
                    .uri(adminUrl("/users/" + keycloakId))
                    .header(HttpHeaders.AUTHORIZATION, "Bearer " + token)
                    .contentType(MediaType.APPLICATION_JSON)
                    .bodyValue(body)
                    .retrieve()
                    .toBodilessEntity()
                    .block();
        } catch (WebClientResponseException e) {
            log.error("Error actualizando perfil Keycloak {}: {}", keycloakId, e.getResponseBodyAsString());
            throw new ExternalApiException("Keycloak", "No se pudo actualizar el perfil en Keycloak");
        }
    }

    public void asignarRolReservaExcepcional(String keycloakId, boolean activo) {
        if (!props.isEnabled() || keycloakId == null || keycloakId.isBlank()) {
            return;
        }

        String token = obtenerTokenAdmin();
        String roleName = "RESERVA_EXCEPCIONAL";

        JsonNode role = webClient.get()
                .uri(adminUrl("/roles/" + roleName))
                .header(HttpHeaders.AUTHORIZATION, "Bearer " + token)
                .retrieve()
                .bodyToMono(JsonNode.class)
                .block();

        if (role == null) {
            throw new ExternalApiException("Keycloak", "Rol no encontrado: " + roleName);
        }

        Map<String, Object> roleMap = Map.of(
                "id", role.get("id").asText(),
                "name", role.get("name").asText()
        );

        try {
            if (activo) {
                webClient.post()
                        .uri(adminUrl("/users/" + keycloakId + "/role-mappings/realm"))
                        .header(HttpHeaders.AUTHORIZATION, "Bearer " + token)
                        .contentType(MediaType.APPLICATION_JSON)
                        .bodyValue(List.of(roleMap))
                        .retrieve()
                        .toBodilessEntity()
                        .block();
            } else {
                webClient.method(org.springframework.http.HttpMethod.DELETE)
                        .uri(adminUrl("/users/" + keycloakId + "/role-mappings/realm"))
                        .header(HttpHeaders.AUTHORIZATION, "Bearer " + token)
                        .contentType(MediaType.APPLICATION_JSON)
                        .bodyValue(List.of(roleMap))
                        .retrieve()
                        .toBodilessEntity()
                        .block();
            }
        } catch (WebClientResponseException e) {
            log.error("Error rol reserva Keycloak {}: {}", keycloakId, e.getResponseBodyAsString());
            throw new ExternalApiException("Keycloak", "No se pudo actualizar el rol en Keycloak");
        }
    }

    private void establecerContrasena(String token, String userId, String password) {
        Map<String, Object> body = Map.of(
                "type", "password",
                "value", password,
                "temporary", false
        );

        webClient.put()
                .uri(adminUrl("/users/" + userId + "/reset-password"))
                .header(HttpHeaders.AUTHORIZATION, "Bearer " + token)
                .contentType(MediaType.APPLICATION_JSON)
                .bodyValue(body)
                .retrieve()
                .toBodilessEntity()
                .block();
    }

    private void asignarRoles(String token, String userId, List<String> realmRoles) {
        List<Map<String, Object>> roles = new ArrayList<>();
        for (String roleName : realmRoles) {
            JsonNode role = webClient.get()
                    .uri(adminUrl("/roles/" + roleName))
                    .header(HttpHeaders.AUTHORIZATION, "Bearer " + token)
                    .retrieve()
                    .bodyToMono(JsonNode.class)
                    .block();

            if (role == null) {
                throw new ExternalApiException("Keycloak", "Rol no encontrado: " + roleName);
            }

            Map<String, Object> roleMap = new HashMap<>();
            roleMap.put("id", role.get("id").asText());
            roleMap.put("name", role.get("name").asText());
            roles.add(roleMap);
        }

        if (!roles.isEmpty()) {
            webClient.post()
                    .uri(adminUrl("/users/" + userId + "/role-mappings/realm"))
                    .header(HttpHeaders.AUTHORIZATION, "Bearer " + token)
                    .contentType(MediaType.APPLICATION_JSON)
                    .bodyValue(roles)
                    .retrieve()
                    .toBodilessEntity()
                    .block();
        }
    }

    private void deshabilitarUsuario(String token, String userId) {
        try {
            webClient.put()
                    .uri(adminUrl("/users/" + userId))
                    .header(HttpHeaders.AUTHORIZATION, "Bearer " + token)
                    .contentType(MediaType.APPLICATION_JSON)
                    .bodyValue(Map.of("enabled", false))
                    .retrieve()
                    .toBodilessEntity()
                    .block();
        } catch (Exception e) {
            log.warn("No se pudo revertir usuario Keycloak {}: {}", userId, e.getMessage());
        }
    }

    private String obtenerTokenAdmin() {
        MultiValueMap<String, String> form = new LinkedMultiValueMap<>();
        form.add("grant_type", "password");
        form.add("client_id", props.getAdminClientId());
        form.add("username", props.getAdminUsername());
        form.add("password", props.getAdminPassword());

        try {
            JsonNode response = webClient.post()
                    .uri(props.getServerUrl() + "/realms/" + props.getAdminRealm() + "/protocol/openid-connect/token")
                    .contentType(MediaType.APPLICATION_FORM_URLENCODED)
                    .body(BodyInserters.fromFormData(form))
                    .retrieve()
                    .bodyToMono(JsonNode.class)
                    .block();

            if (response == null || !response.has("access_token")) {
                throw new ExternalApiException("Keycloak", "No se obtuvo token de administrador");
            }
            return response.get("access_token").asText();
        } catch (WebClientResponseException e) {
            log.error("Error autenticando admin Keycloak: {}", e.getResponseBodyAsString());
            throw new ExternalApiException(
                    "Keycloak",
                    "No se pudo conectar con Keycloak. Verifique que el servicio este activo."
            );
        }
    }

    private String adminUrl(String path) {
        return props.getServerUrl() + "/admin/realms/" + props.getRealm() + path;
    }

    private static String[] dividirNombre(String nombreCompleto) {
        String trimmed = nombreCompleto.trim();
        int space = trimmed.indexOf(' ');
        if (space <= 0) {
            return new String[]{trimmed, "-"};
        }
        return new String[]{trimmed.substring(0, space), trimmed.substring(space + 1).trim()};
    }
}
