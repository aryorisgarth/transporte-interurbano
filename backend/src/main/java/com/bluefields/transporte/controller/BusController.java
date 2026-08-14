package com.bluefields.transporte.controller;



import com.bluefields.transporte.dto.bus.AsientoUpdateRequest;

import com.bluefields.transporte.dto.bus.BusRequest;

import com.bluefields.transporte.dto.bus.BusResponse;

import com.bluefields.transporte.dto.bus.BusUpdateRequest;

import com.bluefields.transporte.service.BusService;

import jakarta.validation.Valid;

import org.springframework.http.ResponseEntity;

import org.springframework.security.access.prepost.PreAuthorize;

import org.springframework.web.bind.annotation.*;

import org.springframework.web.servlet.support.ServletUriComponentsBuilder;



import java.net.URI;

import java.util.List;



@RestController

@RequestMapping("/api/buses")

public class BusController {



    private final BusService busService;



    public BusController(BusService busService) {

        this.busService = busService;

    }



    @PostMapping

    @PreAuthorize("hasAnyRole('ADMIN_EMPRESA', 'ADMIN_GENERAL')")

    public ResponseEntity<BusResponse> crear(@Valid @RequestBody BusRequest request) {

        BusResponse creado = busService.crear(request);



        URI location = ServletUriComponentsBuilder

                .fromCurrentRequest()

                .path("/{id}")

                .buildAndExpand(creado.id())

                .toUri();



        return ResponseEntity.created(location).body(creado);

    }



    @PutMapping("/{id}")

    @PreAuthorize("hasAnyRole('ADMIN_EMPRESA', 'ADMIN_GENERAL')")

    public ResponseEntity<BusResponse> actualizar(

            @PathVariable Long id,

            @Valid @RequestBody BusUpdateRequest request

    ) {

        return ResponseEntity.ok(busService.actualizar(id, request));

    }



    @PutMapping("/{busId}/asientos/{asientoId}")

    @PreAuthorize("hasAnyRole('ADMIN_EMPRESA', 'ADMIN_GENERAL')")

    public ResponseEntity<BusResponse.AsientoResponse> actualizarAsiento(

            @PathVariable Long busId,

            @PathVariable Long asientoId,

            @Valid @RequestBody AsientoUpdateRequest request

    ) {

        return ResponseEntity.ok(busService.actualizarAsiento(busId, asientoId, request));

    }



    @GetMapping

    public ResponseEntity<List<BusResponse>> listarPorEmpresa(

            @RequestParam Long empresaId,

            @RequestParam(required = false) String sede

    ) {

        return ResponseEntity.ok(busService.listarPorEmpresa(empresaId, sede));

    }



    @GetMapping("/mi-empresa")

    public ResponseEntity<List<BusResponse>> listarMiEmpresa(

            @RequestParam(required = false) String sede

    ) {

        return ResponseEntity.ok(busService.listarBusesDelOperador(sede));

    }



    @GetMapping("/{id}")

    public ResponseEntity<BusResponse> obtener(@PathVariable Long id) {

        return busService.buscar(id)

                .map(ResponseEntity::ok)

                .orElse(ResponseEntity.notFound().build());

    }

}

