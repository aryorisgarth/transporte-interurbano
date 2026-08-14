package com.bluefields.transporte.controller;

import com.bluefields.transporte.dto.consulta.ConsultaPublicaDto;
import com.bluefields.transporte.dto.parada.ParadaDto;
import com.bluefields.transporte.service.ConsultaPublicaService;
import com.bluefields.transporte.service.ParadaRutaService;
import jakarta.validation.constraints.NotNull;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.http.ResponseEntity;
import org.springframework.validation.annotation.Validated;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDate;
import java.time.LocalTime;
import java.util.List;

@RestController
@RequestMapping("/api/publico")
@Validated
public class ConsultaPublicaController {

    private final ConsultaPublicaService consultaPublicaService;
    private final ParadaRutaService paradaRutaService;

    public ConsultaPublicaController(
            ConsultaPublicaService consultaPublicaService,
            ParadaRutaService paradaRutaService
    ) {
        this.consultaPublicaService = consultaPublicaService;
        this.paradaRutaService = paradaRutaService;
    }

    @GetMapping("/viajes")
    public ResponseEntity<List<ConsultaPublicaDto.ViajeDisponibleResponse>> buscarViajes(
            @RequestParam(required = false) String origen,
            @RequestParam(required = false) String destino,
            @RequestParam @NotNull(message = "La fecha es obligatoria")
            @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate fecha
    ) {
        return ResponseEntity.ok(consultaPublicaService.buscarViajes(origen, destino, fecha));
    }

    @GetMapping("/viajes/{id}")
    public ResponseEntity<ConsultaPublicaDto.DetalleViajeResponse> detalleViaje(@PathVariable Long id) {
        return ResponseEntity.ok(consultaPublicaService.detalleViaje(id));
    }

    @GetMapping("/paradas")
    public ResponseEntity<List<ParadaDto.ParadaResponse>> paradas(
            @RequestParam(required = false) String origen,
            @RequestParam(required = false) String destino,
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.TIME) LocalTime horaSalida
    ) {
        return ResponseEntity.ok(paradaRutaService.listarPorRuta(origen, destino, horaSalida));
    }
}
