package com.bluefields.transporte.config;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.web.servlet.config.annotation.CorsRegistry;
import org.springframework.web.servlet.config.annotation.WebMvcConfigurer;

@Configuration
public class WebConfig {

    @Value("${transporte.cors.allowed-origins:}")
    private String allowedOrigins;

    @Value("${transporte.cors.allowed-origin-patterns:}")
    private String allowedOriginPatterns;

    @Bean
    public WebMvcConfigurer corsConfigurer() {
        return new WebMvcConfigurer() {
            @Override
            public void addCorsMappings(CorsRegistry registry) {
                var mapping = registry.addMapping("/api/**")
                        .allowedMethods("GET", "POST", "PUT", "PATCH", "DELETE", "OPTIONS")
                        .allowedHeaders("*");

                if (allowedOriginPatterns != null && !allowedOriginPatterns.isBlank()) {
                    mapping.allowedOriginPatterns(allowedOriginPatterns.trim().split("\\s*,\\s*"));
                } else if (allowedOrigins != null && !allowedOrigins.isBlank()) {
                    mapping.allowedOrigins(allowedOrigins.trim().split("\\s*,\\s*"));
                }
            }
        };
    }
}
