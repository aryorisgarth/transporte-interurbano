package com.bluefields.transporte.controller;

import com.bluefields.transporte.dto.reserva.ReservaExcepcionalDto;
import com.bluefields.transporte.service.ReservaExcepcionalService;
import jakarta.validation.Valid;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.servlet.support.ServletUriComponentsBuilder;

import java.net.URI;

@RestController
@RequestMapping("/api/reservas-excepcionales")
public class ReservaExcepcionalController {

    private final ReservaExcepcionalService reservaService;

    public ReservaExcepcionalController(ReservaExcepcionalService reservaService) {
        this.reservaService = reservaService;
    }

    @PostMapping
    public ResponseEntity<ReservaExcepcionalDto.ReservaResponse> crear(
            @Valid @RequestBody ReservaExcepcionalDto.ReservaRequest request
    ) {
        ReservaExcepcionalDto.ReservaResponse creada = reservaService.crear(request);

        URI location = ServletUriComponentsBuilder
                .fromCurrentRequest()
                .path("/{id}")
                .buildAndExpand(creada.id())
                .toUri();

        return ResponseEntity.created(location).body(creada);
    }
}
