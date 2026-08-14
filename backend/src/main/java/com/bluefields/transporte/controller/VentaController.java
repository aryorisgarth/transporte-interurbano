package com.bluefields.transporte.controller;

import com.bluefields.transporte.dto.venta.VentaDto;
import com.bluefields.transporte.service.VentaService;
import jakarta.validation.Valid;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.servlet.support.ServletUriComponentsBuilder;

import java.net.URI;
import java.util.List;

@RestController
@RequestMapping("/api/ventas")
public class VentaController {

    private final VentaService ventaService;

    public VentaController(VentaService ventaService) {
        this.ventaService = ventaService;
    }

    @PostMapping
    public ResponseEntity<VentaDto.VentaResponse> vender(@Valid @RequestBody VentaDto.VentaRequest request) {
        VentaDto.VentaResponse creada = ventaService.vender(request);

        URI location = ServletUriComponentsBuilder
                .fromCurrentRequest()
                .path("/{id}")
                .buildAndExpand(creada.id())
                .toUri();

        return ResponseEntity.created(location).body(creada);
    }

    @GetMapping("/{id}")
    public ResponseEntity<VentaDto.VentaResponse> obtener(@PathVariable Long id) {
        return ventaService.buscar(id)
                .map(ResponseEntity::ok)
                .orElse(ResponseEntity.notFound().build());
    }

    @GetMapping
    public ResponseEntity<List<VentaDto.VentaResponse>> listarPorViaje(@RequestParam Long viajeId) {
        return ResponseEntity.ok(ventaService.listarPorViaje(viajeId));
    }
}
