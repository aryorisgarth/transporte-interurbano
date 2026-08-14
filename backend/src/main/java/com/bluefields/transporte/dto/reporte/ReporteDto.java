package com.bluefields.transporte.dto.reporte;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.List;

public class ReporteDto {

    public record OcupacionViajeResponse(
            Long viajeId,
            LocalDate fecha,
            String horaSalida,
            String origen,
            String destino,
            String busNumeroInterno,
            String busPlaca,
            int capacidadTotal,
            int asientosVendidos,
            int asientosReservados,
            int asientosDisponibles,
            BigDecimal porcentajeOcupacion
    ) {}

    public record IngresosResumen(
            BigDecimal totalIngresos,
            BigDecimal subtotalBoletos,
            BigDecimal subtotalEquipaje,
            long cantidadVentas,
            long cantidadBoletos,
            BigDecimal ticketPromedio
    ) {}

    public record IngresosPorDia(
            LocalDate fecha,
            BigDecimal totalIngresos,
            BigDecimal subtotalBoletos,
            BigDecimal subtotalEquipaje,
            long cantidadVentas,
            long cantidadBoletos
    ) {}

    public record IngresosPorViaje(
            Long viajeId,
            LocalDate fecha,
            String horaSalida,
            String origen,
            String destino,
            String busNumeroInterno,
            BigDecimal totalIngresos,
            BigDecimal subtotalBoletos,
            BigDecimal subtotalEquipaje,
            long cantidadVentas,
            long cantidadBoletos
    ) {}

    public record IngresosPorCajero(
            Long operadorId,
            String operadorNombre,
            String sede,
            BigDecimal totalIngresos,
            BigDecimal subtotalBoletos,
            BigDecimal subtotalEquipaje,
            long cantidadVentas,
            long cantidadBoletos
    ) {}

    public record IngresosPorTerminal(
            String terminal,
            BigDecimal totalIngresos,
            long cantidadVentas,
            long cantidadBoletos
    ) {}

    public record IngresosVentaDetalle(
            Long ventaId,
            String codigo,
            String fechaVenta,
            BigDecimal total,
            BigDecimal subtotalBoletos,
            BigDecimal subtotalEquipaje,
            int cantidadBoletos,
            String operadorNombre,
            String operadorSede,
            String origen,
            String destino,
            LocalDate fechaViaje,
            String horaSalida
    ) {}

    public record IngresosReporteResponse(
            LocalDate desde,
            LocalDate hasta,
            IngresosResumen resumen,
            List<IngresosPorDia> porDia,
            List<IngresosPorViaje> porViaje,
            List<IngresosPorCajero> porCajero,
            List<IngresosPorTerminal> porTerminal,
            List<IngresosVentaDetalle> ventas
    ) {}
}
