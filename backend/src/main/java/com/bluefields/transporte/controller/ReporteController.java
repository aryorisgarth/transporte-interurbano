package com.bluefields.transporte.controller;

import com.bluefields.transporte.dto.reporte.ReporteDto;
import com.bluefields.transporte.service.ReporteService;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.time.LocalDate;
import java.util.List;

@RestController
@RequestMapping("/api/reportes")
public class ReporteController {

    private final ReporteService reporteService;

    public ReporteController(ReporteService reporteService) {
        this.reporteService = reporteService;
    }

    @GetMapping("/ocupacion")
    public ResponseEntity<List<ReporteDto.OcupacionViajeResponse>> ocupacion(
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate fecha,
            @RequestParam(required = false) Long empresaId
    ) {
        return ResponseEntity.ok(reporteService.ocupacionPorFecha(fecha, empresaId));
    }

    @GetMapping("/ingresos")
    public ResponseEntity<ReporteDto.IngresosReporteResponse> ingresos(
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate desde,
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate hasta,
            @RequestParam(required = false) Long empresaId
    ) {
        return ResponseEntity.ok(reporteService.ingresosPorPeriodo(desde, hasta, empresaId));
    }
}
