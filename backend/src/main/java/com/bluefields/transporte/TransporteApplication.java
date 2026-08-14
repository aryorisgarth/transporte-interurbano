package com.bluefields.transporte;

import com.bluefields.transporte.config.KeycloakAdminProperties;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.boot.context.properties.EnableConfigurationProperties;

@SpringBootApplication
@EnableConfigurationProperties(KeycloakAdminProperties.class)
public class TransporteApplication {

    public static void main(String[] args) {
        SpringApplication.run(TransporteApplication.class, args);
    }
}
