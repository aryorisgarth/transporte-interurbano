package com.bluefields.transporte.service;

import com.bluefields.transporte.domain.entity.*;
import com.bluefields.transporte.domain.enums.EstadoAsientoViaje;
import com.bluefields.transporte.domain.enums.EstadoBoleto;
import com.bluefields.transporte.domain.enums.EstadoViaje;
import com.bluefields.transporte.dto.venta.VentaDto;
import com.bluefields.transporte.exception.RecursoNoEncontradoException;
import com.bluefields.transporte.exception.ReglaNegocioException;
import com.bluefields.transporte.mapper.EntityMapper;
import com.bluefields.transporte.repository.VentaRepository;
import com.bluefields.transporte.repository.ViajeAsientoRepository;
import com.bluefields.transporte.security.OperadorContext;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.time.Clock;
import java.time.LocalDate;
import java.util.List;
import java.util.Optional;

@Service
@Transactional
public class VentaService {

    private static final Logger log = LoggerFactory.getLogger(VentaService.class);

    private final VentaRepository ventaRepository;
    private final ViajeAsientoRepository viajeAsientoRepository;
    private final ViajeService viajeService;
    private final OperadorContext operadorContext;
    private final Clock clock;

    public VentaService(
            VentaRepository ventaRepository,
            ViajeAsientoRepository viajeAsientoRepository,
            ViajeService viajeService,
            OperadorContext operadorContext,
            Clock clock
    ) {
        this.ventaRepository = ventaRepository;
        this.viajeAsientoRepository = viajeAsientoRepository;
        this.viajeService = viajeService;
        this.operadorContext = operadorContext;
        this.clock = clock;
    }

    public VentaDto.VentaResponse vender(VentaDto.VentaRequest request) {
        log.debug("Iniciando venta viajeId={} asientos={}", request.viajeId(), request.viajeAsientoIds().size());

        Viaje viaje = viajeService.buscarEntidad(request.viajeId());
        validarFechaVenta(viaje);
        validarViajeActivo(viaje);

        Usuario operador = operadorContext.resolverOperador(request.operadorId());

        if (operador.getEmpresa() == null || !operador.getEmpresa().getId().equals(viaje.getEmpresa().getId())) {
            throw new ReglaNegocioException("El operador no pertenece a la empresa del viaje");
        }

        if (operador.tieneRol("CAJERO") && !operador.tieneRol("ADMIN_EMPRESA")) {
            if (operador.getSede() == null || !operador.getSede().equals(viaje.getOrigen())) {
                throw new ReglaNegocioException(
                        "Solo puede vender viajes que salen desde su terminal: " + operador.getSede()
                );
            }
        }

        List<Long> idsUnicos = request.viajeAsientoIds().stream().distinct().toList();
        if (idsUnicos.size() != request.viajeAsientoIds().size()) {
            throw new ReglaNegocioException("No se permiten asientos duplicados en la misma venta");
        }

        List<ViajeAsiento> asientos = viajeAsientoRepository.findByViajeIdAndIdIn(viaje.getId(), idsUnicos);
        if (asientos.size() != idsUnicos.size()) {
            throw new ReglaNegocioException("Uno o mas asientos no pertenecen al viaje indicado");
        }

        validarAsientosDisponibles(asientos);
        validarPasajeros(request, idsUnicos);

        Venta venta = construirVenta(request, viaje, operador, asientos);
        Venta guardada = ventaRepository.save(venta);

        log.info("Venta registrada codigo={} boletos={}", guardada.getCodigo(), guardada.getCantidadBoletos());

        return EntityMapper.toVentaResponse(guardada);
    }

    @Transactional(readOnly = true)
    public Optional<VentaDto.VentaResponse> buscar(Long id) {
        return ventaRepository.findWithDetailsById(id)
                .map(v -> {
                    operadorContext.resolverEmpresaId(v.getEmpresa().getId());
                    return EntityMapper.toVentaResponse(v);
                });
    }

    @Transactional(readOnly = true)
    public VentaDto.VentaResponse obtener(Long id) {
        return buscar(id)
                .orElseThrow(() -> new RecursoNoEncontradoException("Venta no encontrada: " + id));
    }

    @Transactional(readOnly = true)
    public List<VentaDto.VentaResponse> listarPorViaje(Long viajeId) {
        Viaje viaje = viajeService.buscarEntidad(viajeId);
        operadorContext.resolverEmpresaId(viaje.getEmpresa().getId());
        return ventaRepository.findByViajeIdOrderByFechaVentaDesc(viajeId).stream()
                .map(EntityMapper::toVentaResponse)
                .toList();
    }

    private Venta construirVenta(VentaDto.VentaRequest request, Viaje viaje, Usuario operador, List<ViajeAsiento> asientos) {
        Venta venta = new Venta();
        venta.setCodigo(generarCodigoVenta(viaje.getEmpresa().getId()));
        venta.setEmpresa(viaje.getEmpresa());
        venta.setViaje(viaje);
        venta.setOperador(operador);
        venta.setCompradorNombre(request.compradorNombre().trim());
        venta.setCompradorCedula(request.compradorCedula().trim());
        venta.setCompradorTelefono(request.compradorTelefono());
        venta.setCantidadBoletos(asientos.size());

        BigDecimal tarifa = viaje.getTarifa();
        BigDecimal subtotalBoletos = tarifa.multiply(BigDecimal.valueOf(asientos.size()));
        venta.setSubtotalBoletos(subtotalBoletos);

        BigDecimal subtotalEquipaje = procesarEquipajeExtra(request, viaje, venta, asientos.size());
        venta.setSubtotalEquipaje(subtotalEquipaje);
        venta.setTotal(subtotalBoletos.add(subtotalEquipaje));

        var pasajerosPorAsiento = mapaPasajeros(request);

        for (ViajeAsiento asiento : asientos) {
            asiento.setEstado(EstadoAsientoViaje.VENDIDO);

            Boleto boleto = new Boleto();
            boleto.setVenta(venta);
            boleto.setViajeAsiento(asiento);
            boleto.setNumeroAsiento(asiento.getAsientoBus().getNumero());
            boleto.setMonto(tarifa);
            boleto.setIncluyeEquipaje(true);
            boleto.setEstado(EstadoBoleto.ACTIVO);

            var pasajero = pasajerosPorAsiento.get(asiento.getId());
            if (pasajero != null) {
                boleto.setPasajeroNombre(pasajero.pasajeroNombre().trim());
                boleto.setPasajeroCedula(pasajero.pasajeroCedula().trim());
                boleto.setEsMenor(Boolean.TRUE.equals(pasajero.esMenor()));
                boleto.setEdad(pasajero.edad());
            } else {
                boleto.setPasajeroNombre(request.compradorNombre().trim());
                boleto.setPasajeroCedula(request.compradorCedula().trim());
                boleto.setEsMenor(false);
            }

            venta.getBoletos().add(boleto);
        }

        return venta;
    }

    private java.util.Map<Long, VentaDto.PasajeroBoletoRequest> mapaPasajeros(VentaDto.VentaRequest request) {
        if (request.pasajeros() == null || request.pasajeros().isEmpty()) {
            return java.util.Map.of();
        }
        return request.pasajeros().stream()
                .collect(java.util.stream.Collectors.toMap(
                        VentaDto.PasajeroBoletoRequest::viajeAsientoId,
                        p -> p,
                        (a, b) -> a
                ));
    }

    private void validarPasajeros(VentaDto.VentaRequest request, List<Long> idsUnicos) {
        if (request.pasajeros() == null || request.pasajeros().isEmpty()) {
            return;
        }
        if (request.pasajeros().size() != idsUnicos.size()) {
            throw new ReglaNegocioException(
                    "Debe registrar un pasajero por cada asiento seleccionado"
            );
        }
        for (VentaDto.PasajeroBoletoRequest p : request.pasajeros()) {
            if (!idsUnicos.contains(p.viajeAsientoId())) {
                throw new ReglaNegocioException(
                        "Pasajero con asiento id=" + p.viajeAsientoId() + " no coincide con la seleccion"
                );
            }
            if (Boolean.TRUE.equals(p.esMenor()) && p.edad() == null) {
                throw new ReglaNegocioException(
                        "Indique la edad del menor en asiento id=" + p.viajeAsientoId()
                );
            }
        }
    }

    private BigDecimal procesarEquipajeExtra(VentaDto.VentaRequest request, Viaje viaje, Venta venta, int boletos) {
        if (request.equipajeExtra() == null || request.equipajeExtra().cantidad() == null) {
            return BigDecimal.ZERO;
        }

        var eq = request.equipajeExtra();
        if (eq.cantidad() <= 0) {
            return BigDecimal.ZERO;
        }

        BigDecimal montoUnitario = eq.montoUnitario() != null
                ? eq.montoUnitario()
                : resolverTarifaEquipajeExtra(viaje);
        BigDecimal subtotal = montoUnitario.multiply(BigDecimal.valueOf(eq.cantidad()));

        EquipajeExtra equipaje = new EquipajeExtra();
        equipaje.setVenta(venta);
        equipaje.setCantidad(eq.cantidad());
        equipaje.setMontoUnitario(montoUnitario);
        equipaje.setMontoTotal(subtotal);
        equipaje.setDescripcion(
                eq.descripcion() != null ? eq.descripcion() : "Equipaje adicional (incluidos: " + boletos + ")"
        );
        venta.getEquipajeExtra().add(equipaje);

        return subtotal;
    }

    private void validarAsientosDisponibles(List<ViajeAsiento> asientos) {
        for (ViajeAsiento asiento : asientos) {
            if (asiento.getEstado() != EstadoAsientoViaje.DISPONIBLE) {
                throw new ReglaNegocioException(
                        "El asiento " + asiento.getAsientoBus().getNumero() + " no esta disponible"
                );
            }
        }
    }

    private void validarFechaVenta(Viaje viaje) {
        LocalDate hoy = LocalDate.now(clock);
        LocalDate fechaViaje = viaje.getFecha();
        if (fechaViaje.isBefore(hoy.minusDays(1))) {
            throw new ReglaNegocioException("Solo se puede vender para el dia del viaje o el dia anterior");
        }
        if (fechaViaje.isAfter(hoy.plusDays(1))) {
            throw new ReglaNegocioException("No se puede vender con mas de un dia de anticipacion");
        }
    }

    private void validarViajeActivo(Viaje viaje) {
        if (viaje.getEstado() == EstadoViaje.CANCELADO) {
            throw new ReglaNegocioException("El viaje esta cancelado");
        }
    }

    private String generarCodigoVenta(Long empresaId) {
        return "V-" + empresaId + "-" + System.currentTimeMillis();
    }

    private BigDecimal resolverTarifaEquipajeExtra(Viaje viaje) {
        if (viaje.getTarifaEquipajeExtra() != null) {
            return viaje.getTarifaEquipajeExtra();
        }
        return viaje.getEmpresa().getTarifaEquipajeExtra();
    }
}
