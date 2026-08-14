package com.bluefields.transporte.config;

import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

import java.time.Clock;
import java.time.ZoneId;

@Configuration
public class TimeConfig {

    public static final ZoneId ZONA_NICARAGUA = ZoneId.of("America/Managua");

    @Bean
    public Clock clock() {
        return Clock.system(ZONA_NICARAGUA);
    }
}
