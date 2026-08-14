package com.bluefields.transporte.controller;

import com.bluefields.transporte.dto.pasajero.PasajeroDto;
import com.bluefields.transporte.service.PasajeroService;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.time.LocalDate;
import java.util.List;

@RestController
@RequestMapping("/api/pasajeros")
public class PasajeroController {

    private final PasajeroService pasajeroService;

    public PasajeroController(PasajeroService pasajeroService) {
        this.pasajeroService = pasajeroService;
    }

    @GetMapping("/manifiesto")
    public ResponseEntity<List<PasajeroDto.ManifiestoPasajeroResponse>> manifiesto(
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate fecha,
            @RequestParam(required = false) Long viajeId,
            @RequestParam(required = false) Long busId,
            @RequestParam(required = false) Long empresaId
    ) {
        return ResponseEntity.ok(pasajeroService.manifiesto(fecha, viajeId, busId, empresaId));
    }
}
