package com.bluefields.transporte.controller;

import com.bluefields.transporte.dto.parada.ParadaCreateRequest;
import com.bluefields.transporte.dto.parada.ParadaDto;
import com.bluefields.transporte.dto.parada.ParadaUpdateRequest;
import com.bluefields.transporte.service.ParadaRutaService;
import jakarta.validation.Valid;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.time.LocalTime;
import java.util.List;

@RestController
@RequestMapping("/api/paradas")
public class ParadaController {

    private final ParadaRutaService paradaRutaService;

    public ParadaController(ParadaRutaService paradaRutaService) {
        this.paradaRutaService = paradaRutaService;
    }

    @GetMapping
    public ResponseEntity<List<ParadaDto.ParadaResponse>> listar(
            @RequestParam(required = false) String origen,
            @RequestParam(required = false) String destino,
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.TIME) LocalTime horaSalida
    ) {
        return ResponseEntity.ok(paradaRutaService.listarPorRuta(origen, destino, horaSalida));
    }

    @PostMapping
    public ResponseEntity<ParadaDto.ParadaResponse> crear(@Valid @RequestBody ParadaCreateRequest request) {
        return ResponseEntity.status(HttpStatus.CREATED).body(paradaRutaService.crear(request));
    }

    @PutMapping("/{id}")
    public ResponseEntity<ParadaDto.ParadaResponse> actualizar(
            @PathVariable Long id,
            @Valid @RequestBody ParadaUpdateRequest request
    ) {
        return ResponseEntity.ok(paradaRutaService.actualizar(id, request));
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Void> eliminar(@PathVariable Long id) {
        paradaRutaService.eliminar(id);
        return ResponseEntity.noContent().build();
    }
}
