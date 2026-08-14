package com.bluefields.transporte.controller;

import com.bluefields.transporte.dto.consulta.ConsultaPublicaDto;
import com.bluefields.transporte.dto.viaje.ViajeRequest;
import com.bluefields.transporte.dto.viaje.ViajeResponse;
import com.bluefields.transporte.dto.viaje.ViajeUpdateRequest;
import com.bluefields.transporte.service.ViajeService;
import jakarta.validation.Valid;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.servlet.support.ServletUriComponentsBuilder;

import java.net.URI;
import java.time.Clock;
import java.time.LocalDate;
import java.util.List;

@RestController
@RequestMapping("/api/viajes")
public class ViajeController {

    private final ViajeService viajeService;
    private final Clock clock;

    public ViajeController(ViajeService viajeService, Clock clock) {
        this.viajeService = viajeService;
        this.clock = clock;
    }

    @PostMapping
    public ResponseEntity<ViajeResponse> programar(@Valid @RequestBody ViajeRequest request) {
        ViajeResponse creado = viajeService.programar(request);

        URI location = ServletUriComponentsBuilder
                .fromCurrentRequest()
                .path("/{id}")
                .buildAndExpand(creado.id())
                .toUri();

        return ResponseEntity.created(location).body(creado);
    }

    @GetMapping
    public ResponseEntity<List<ViajeResponse>> listar(
            @RequestParam Long empresaId,
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate fecha,
            @RequestParam(required = false) String origen
    ) {
        return ResponseEntity.ok(viajeService.listarPorEmpresaYFecha(empresaId, fecha, origen));
    }

    @GetMapping("/mi-empresa")
    public ResponseEntity<List<ViajeResponse>> listarMiEmpresa(
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate fecha,
            @RequestParam(required = false) String origen
    ) {
        LocalDate dia = fecha != null ? fecha : LocalDate.now(clock);
        return ResponseEntity.ok(viajeService.listarViajesDelOperador(dia, origen));
    }

    @GetMapping("/{id}/detalle-operador")
    public ResponseEntity<ConsultaPublicaDto.DetalleViajeResponse> detalleOperador(@PathVariable Long id) {
        return ResponseEntity.ok(viajeService.detalleParaOperador(id));
    }

    @GetMapping("/{id}")
    public ResponseEntity<ViajeResponse> obtener(@PathVariable Long id) {
        return viajeService.buscar(id)
                .map(ResponseEntity::ok)
                .orElse(ResponseEntity.notFound().build());
    }

    @PutMapping("/{id}")
    public ResponseEntity<ViajeResponse> actualizar(
            @PathVariable Long id,
            @Valid @RequestBody ViajeUpdateRequest request
    ) {
        return ResponseEntity.ok(viajeService.actualizar(id, request));
    }

    @PatchMapping("/{id}/cancelar")
    public ResponseEntity<ViajeResponse> cancelar(@PathVariable Long id) {
        return ResponseEntity.ok(viajeService.cancelar(id));
    }
}
