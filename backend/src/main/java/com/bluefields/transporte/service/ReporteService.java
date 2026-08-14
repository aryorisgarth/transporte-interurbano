package com.bluefields.transporte.service;

import com.bluefields.transporte.domain.entity.Viaje;
import com.bluefields.transporte.domain.enums.EstadoAsientoViaje;
import com.bluefields.transporte.domain.enums.EstadoVenta;
import com.bluefields.transporte.dto.reporte.ReporteDto;
import com.bluefields.transporte.exception.ReglaNegocioException;
import com.bluefields.transporte.repository.VentaRepository;
import com.bluefields.transporte.repository.ViajeAsientoRepository;
import com.bluefields.transporte.repository.ViajeRepository;
import com.bluefields.transporte.security.OperadorContext;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.Instant;
import java.time.LocalDate;
import java.time.LocalTime;
import java.util.List;

@Service
@Transactional(readOnly = true)
public class ReporteService {

    private static final int MAX_DIAS_REPORTE = 93;

    private final ViajeRepository viajeRepository;
    private final ViajeAsientoRepository viajeAsientoRepository;
    private final VentaRepository ventaRepository;
    private final OperadorContext operadorContext;

    public ReporteService(
            ViajeRepository viajeRepository,
            ViajeAsientoRepository viajeAsientoRepository,
            VentaRepository ventaRepository,
            OperadorContext operadorContext
    ) {
        this.viajeRepository = viajeRepository;
        this.viajeAsientoRepository = viajeAsientoRepository;
        this.ventaRepository = ventaRepository;
        this.operadorContext = operadorContext;
    }

    public List<ReporteDto.OcupacionViajeResponse> ocupacionPorFecha(
            LocalDate fecha,
            Long empresaIdRequest
    ) {
        Long empresaId = operadorContext.resolverEmpresaId(empresaIdRequest);

        return viajeRepository.findByEmpresaAndFecha(empresaId, fecha).stream()
                .map(this::toOcupacion)
                .toList();
    }

    public ReporteDto.IngresosReporteResponse ingresosPorPeriodo(
            LocalDate desde,
            LocalDate hasta,
            Long empresaIdRequest
    ) {
        validarPeriodo(desde, hasta);
        Long empresaId = operadorContext.resolverEmpresaId(empresaIdRequest);
        EstadoVenta estado = EstadoVenta.COMPLETADA;

        Object[] totales = unwrapRow(
                ventaRepository.sumarIngresosPorPeriodo(empresaId, desde, hasta, estado)
        );
        ReporteDto.IngresosResumen resumen = toResumen(totales);

        List<ReporteDto.IngresosPorDia> porDia = ventaRepository
                .ingresosAgrupadosPorDia(empresaId, desde, hasta, estado)
                .stream()
                .map(row -> toPorDia(unwrapRow(row)))
                .toList();

        List<ReporteDto.IngresosPorViaje> porViaje = ventaRepository
                .ingresosAgrupadosPorViaje(empresaId, desde, hasta, estado)
                .stream()
                .map(row -> toPorViaje(unwrapRow(row)))
                .toList();

        List<ReporteDto.IngresosPorCajero> porCajero = ventaRepository
                .ingresosAgrupadosPorCajero(empresaId, desde, hasta, estado)
                .stream()
                .map(row -> toPorCajero(unwrapRow(row)))
                .toList();

        List<ReporteDto.IngresosPorTerminal> porTerminal = ventaRepository
                .ingresosAgrupadosPorTerminal(empresaId, desde, hasta, estado)
                .stream()
                .map(row -> toPorTerminal(unwrapRow(row)))
                .toList();

        List<ReporteDto.IngresosVentaDetalle> ventas = ventaRepository
                .listarVentasIngresos(empresaId, desde, hasta, estado)
                .stream()
                .map(row -> toVentaDetalle(unwrapRow(row)))
                .toList();

        return new ReporteDto.IngresosReporteResponse(
                desde,
                hasta,
                resumen,
                porDia,
                porViaje,
                porCajero,
                porTerminal,
                ventas
        );
    }

    private void validarPeriodo(LocalDate desde, LocalDate hasta) {
        if (desde == null || hasta == null) {
            throw new ReglaNegocioException("Las fechas desde y hasta son obligatorias.");
        }
        if (desde.isAfter(hasta)) {
            throw new ReglaNegocioException("La fecha inicial no puede ser posterior a la final.");
        }
        if (desde.plusDays(MAX_DIAS_REPORTE).isBefore(hasta)) {
            throw new ReglaNegocioException(
                    "El período máximo del reporte es de " + MAX_DIAS_REPORTE + " días."
            );
        }
    }

    private Object[] unwrapRow(Object[] row) {
        if (row != null && row.length == 1 && row[0] instanceof Object[] nested) {
            return nested;
        }
        return row;
    }

    private ReporteDto.IngresosResumen toResumen(Object[] row) {
        BigDecimal total = toBigDecimal(row[0]);
        BigDecimal boletos = toBigDecimal(row[1]);
        BigDecimal equipaje = toBigDecimal(row[2]);
        long ventas = toLong(row[3]);
        long cantBoletos = toLong(row[4]);
        BigDecimal promedio = ventas > 0
                ? total.divide(BigDecimal.valueOf(ventas), 2, RoundingMode.HALF_UP)
                : BigDecimal.ZERO;

        return new ReporteDto.IngresosResumen(total, boletos, equipaje, ventas, cantBoletos, promedio);
    }

    private ReporteDto.IngresosPorDia toPorDia(Object[] row) {
        return new ReporteDto.IngresosPorDia(
                (LocalDate) row[0],
                toBigDecimal(row[1]),
                toBigDecimal(row[2]),
                toBigDecimal(row[3]),
                toLong(row[4]),
                toLong(row[5])
        );
    }

    private ReporteDto.IngresosPorViaje toPorViaje(Object[] row) {
        LocalTime hora = toLocalTime(row[2]);
        return new ReporteDto.IngresosPorViaje(
                (Long) row[0],
                (LocalDate) row[1],
                hora != null ? hora.toString() : "",
                (String) row[3],
                (String) row[4],
                (String) row[5],
                toBigDecimal(row[6]),
                toBigDecimal(row[7]),
                toBigDecimal(row[8]),
                toLong(row[9]),
                toLong(row[10])
        );
    }

    private ReporteDto.IngresosPorCajero toPorCajero(Object[] row) {
        return new ReporteDto.IngresosPorCajero(
                (Long) row[0],
                (String) row[1],
                row[2] != null ? (String) row[2] : "—",
                toBigDecimal(row[3]),
                toBigDecimal(row[4]),
                toBigDecimal(row[5]),
                toLong(row[6]),
                toLong(row[7])
        );
    }

    private ReporteDto.IngresosPorTerminal toPorTerminal(Object[] row) {
        return new ReporteDto.IngresosPorTerminal(
                (String) row[0],
                toBigDecimal(row[1]),
                toLong(row[2]),
                toLong(row[3])
        );
    }

    private ReporteDto.IngresosVentaDetalle toVentaDetalle(Object[] row) {
        Instant fechaVenta = toInstant(row[2]);
        LocalTime hora = toLocalTime(row[12]);
        return new ReporteDto.IngresosVentaDetalle(
                (Long) row[0],
                (String) row[1],
                fechaVenta != null ? fechaVenta.toString() : "",
                toBigDecimal(row[3]),
                toBigDecimal(row[4]),
                toBigDecimal(row[5]),
                row[6] != null ? ((Number) row[6]).intValue() : 0,
                (String) row[7],
                row[8] != null ? (String) row[8] : "—",
                (String) row[9],
                (String) row[10],
                (LocalDate) row[11],
                hora != null ? hora.toString() : ""
        );
    }

    private BigDecimal toBigDecimal(Object value) {
        if (value == null) {
            return BigDecimal.ZERO;
        }
        if (value instanceof BigDecimal bd) {
            return bd;
        }
        if (value instanceof Integer i) {
            return BigDecimal.valueOf(i.longValue());
        }
        if (value instanceof Long l) {
            return BigDecimal.valueOf(l);
        }
        if (value instanceof Double d) {
            return BigDecimal.valueOf(d);
        }
        if (value instanceof Float f) {
            return BigDecimal.valueOf(f.doubleValue());
        }
        if (value instanceof Number n) {
            return BigDecimal.valueOf(n.doubleValue());
        }
        return new BigDecimal(value.toString());
    }

    private LocalTime toLocalTime(Object value) {
        if (value == null) {
            return null;
        }
        if (value instanceof LocalTime lt) {
            return lt;
        }
        if (value instanceof java.sql.Time t) {
            return t.toLocalTime();
        }
        return LocalTime.parse(value.toString());
    }

    private Instant toInstant(Object value) {
        if (value == null) {
            return null;
        }
        if (value instanceof Instant instant) {
            return instant;
        }
        if (value instanceof java.sql.Timestamp ts) {
            return ts.toInstant();
        }
        if (value instanceof java.util.Date d) {
            return d.toInstant();
        }
        return Instant.parse(value.toString());
    }

    private long toLong(Object value) {
        if (value == null) {
            return 0L;
        }
        if (value instanceof Number n) {
            return n.longValue();
        }
        return Long.parseLong(value.toString());
    }

    private ReporteDto.OcupacionViajeResponse toOcupacion(Viaje viaje) {
        int vendidos = (int) viajeAsientoRepository.countByViajeIdAndEstado(
                viaje.getId(), EstadoAsientoViaje.VENDIDO
        );
        int reservados = (int) viajeAsientoRepository.countByViajeIdAndEstado(
                viaje.getId(), EstadoAsientoViaje.RESERVADO_EXCEPCIONAL
        );
        int disponibles = (int) viajeAsientoRepository.countByViajeIdAndEstado(
                viaje.getId(), EstadoAsientoViaje.DISPONIBLE
        );
        int capacidad = viaje.getBus().getCapacidad();
        int ocupados = vendidos + reservados;

        BigDecimal porcentaje = capacidad > 0
                ? BigDecimal.valueOf(ocupados * 100.0 / capacidad).setScale(1, RoundingMode.HALF_UP)
                : BigDecimal.ZERO;

        return new ReporteDto.OcupacionViajeResponse(
                viaje.getId(),
                viaje.getFecha(),
                viaje.getHoraSalida().toString(),
                viaje.getOrigen(),
                viaje.getDestino(),
                viaje.getBus().getNumeroInterno(),
                viaje.getBus().getPlaca(),
                capacidad,
                vendidos,
                reservados,
                disponibles,
                porcentaje
        );
    }
}
