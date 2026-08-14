package com.bluefields.transporte.controller;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.core.env.Environment;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

import java.time.Instant;
import java.util.Arrays;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

@RestController
public class HealthController {

    private final Environment environment;

    @Value("${spring.application.name}")
    private String applicationName;

    public HealthController(Environment environment) {
        this.environment = environment;
    }

    @GetMapping("/api/health")
    public ResponseEntity<Map<String, Object>> health() {
        List<String> perfiles = Arrays.asList(environment.getActiveProfiles());

        Map<String, Object> body = new LinkedHashMap<>();
        body.put("status", "UP");
        body.put("service", applicationName);
        body.put("profiles", perfiles.isEmpty() ? List.of("default") : perfiles);
        body.put("timestamp", Instant.now().toString());

        return ResponseEntity.ok(body);
    }
}
