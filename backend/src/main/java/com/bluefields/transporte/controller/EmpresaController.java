package com.bluefields.transporte.controller;

import com.bluefields.transporte.dto.empresa.DetalleCooperativaResponse;
import com.bluefields.transporte.dto.empresa.EmpresaRequest;
import com.bluefields.transporte.dto.empresa.EmpresaResponse;
import com.bluefields.transporte.dto.empresa.ResumenEmpresaResponse;
import com.bluefields.transporte.service.EmpresaService;
import jakarta.validation.Valid;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.servlet.support.ServletUriComponentsBuilder;

import java.net.URI;
import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/empresas")
public class EmpresaController {

    private final EmpresaService empresaService;

    public EmpresaController(EmpresaService empresaService) {
        this.empresaService = empresaService;
    }

    @PostMapping
    @PreAuthorize("hasRole('ADMIN_GENERAL')")
    public ResponseEntity<EmpresaResponse> crear(@Valid @RequestBody EmpresaRequest request) {
        EmpresaResponse creada = empresaService.crear(request);

        URI location = ServletUriComponentsBuilder
                .fromCurrentRequest()
                .path("/{id}")
                .buildAndExpand(creada.id())
                .toUri();

        return ResponseEntity.created(location).body(creada);
    }

    @GetMapping("/resumen-plataforma")
    @PreAuthorize("hasRole('ADMIN_GENERAL')")
    public ResponseEntity<List<ResumenEmpresaResponse>> resumenPlataforma() {
        return ResponseEntity.ok(empresaService.resumenPlataforma());
    }

    @GetMapping("/{id}/detalle-plataforma")
    @PreAuthorize("hasRole('ADMIN_GENERAL')")
    public ResponseEntity<DetalleCooperativaResponse> detallePlataforma(@PathVariable Long id) {
        return ResponseEntity.ok(empresaService.detallePlataforma(id));
    }

    @GetMapping("/mi-empresa")
    public ResponseEntity<EmpresaResponse> miEmpresa() {
        return ResponseEntity.ok(empresaService.miEmpresa());
    }

    @GetMapping
    @PreAuthorize("hasRole('ADMIN_GENERAL')")
    public ResponseEntity<List<EmpresaResponse>> listar() {
        return ResponseEntity.ok(empresaService.listarTodasActivas());
    }

    @GetMapping("/{id}")
    public ResponseEntity<EmpresaResponse> obtener(@PathVariable Long id) {
        return empresaService.buscarActiva(id)
                .map(ResponseEntity::ok)
                .orElse(ResponseEntity.notFound().build());
    }

    @PutMapping("/{id}")
    public ResponseEntity<EmpresaResponse> actualizar(
            @PathVariable Long id,
            @Valid @RequestBody EmpresaRequest request
    ) {
        return ResponseEntity.ok(empresaService.actualizar(id, request));
    }

    @PatchMapping("/{id}/desactivar")
    @PreAuthorize("hasRole('ADMIN_GENERAL')")
    public ResponseEntity<Map<String, String>> desactivar(@PathVariable Long id) {
        empresaService.desactivar(id);
        return ResponseEntity.ok(Map.of("message", "Empresa desactivada", "id", id.toString()));
    }
}
