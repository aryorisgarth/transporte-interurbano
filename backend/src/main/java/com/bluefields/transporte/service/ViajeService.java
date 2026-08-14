package com.bluefields.transporte.service;

import com.bluefields.transporte.domain.entity.*;
import com.bluefields.transporte.domain.enums.EstadoAsientoViaje;
import com.bluefields.transporte.domain.enums.EstadoViaje;
import com.bluefields.transporte.dto.consulta.ConsultaPublicaDto;
import com.bluefields.transporte.dto.viaje.ViajeRequest;
import com.bluefields.transporte.dto.viaje.ViajeResponse;
import com.bluefields.transporte.dto.viaje.ViajeUpdateRequest;
import com.bluefields.transporte.exception.RecursoNoEncontradoException;
import com.bluefields.transporte.exception.ReglaNegocioException;
import com.bluefields.transporte.mapper.EntityMapper;
import com.bluefields.transporte.repository.ViajeAsientoRepository;
import com.bluefields.transporte.repository.ViajeRepository;
import com.bluefields.transporte.security.OperadorContext;
import com.bluefields.transporte.util.CorredorUtil;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Clock;
import java.time.LocalDate;
import java.util.ArrayList;
import java.util.List;
import java.util.Optional;

@Service
@Transactional
public class ViajeService {

    private static final Logger log = LoggerFactory.getLogger(ViajeService.class);

    private final ViajeRepository viajeRepository;
    private final ViajeAsientoRepository viajeAsientoRepository;
    private final EmpresaService empresaService;
    private final BusService busService;
    private final OperadorContext operadorContext;
    private final ConsultaPublicaService consultaPublicaService;
    private final Clock clock;

    public ViajeService(
            ViajeRepository viajeRepository,
            ViajeAsientoRepository viajeAsientoRepository,
            EmpresaService empresaService,
            BusService busService,
            OperadorContext operadorContext,
            ConsultaPublicaService consultaPublicaService,
            Clock clock
    ) {
        this.viajeRepository = viajeRepository;
        this.viajeAsientoRepository = viajeAsientoRepository;
        this.empresaService = empresaService;
        this.busService = busService;
        this.operadorContext = operadorContext;
        this.consultaPublicaService = consultaPublicaService;
        this.clock = clock;
    }

    public ViajeResponse programar(ViajeRequest request) {
        Long empresaId = operadorContext.resolverEmpresaId(request.empresaId());
        log.debug("Programando viaje empresaId={} busId={} fecha={}", empresaId, request.busId(), request.fecha());

        validarFechaProgramacion(request.fecha());

        Empresa empresa = empresaService.buscarEntidad(empresaId);
        Bus bus = busService.buscarEntidad(request.busId());

        if (!bus.getEmpresa().getId().equals(empresa.getId())) {
            throw new ReglaNegocioException("El bus no pertenece a la empresa indicada");
        }

        CorredorUtil.validarPar(request.origen(), request.destino());
        if (!bus.getSede().equals(request.origen())) {
            throw new ReglaNegocioException(
                    "El bus " + bus.getNumeroInterno() + " opera desde " + bus.getSede()
                            + "; no puede salir desde " + request.origen()
            );
        }

        Viaje viaje = new Viaje();
        viaje.setEmpresa(empresa);
        viaje.setBus(bus);
        viaje.setOrigen(request.origen());
        viaje.setDestino(request.destino());
        viaje.setFecha(request.fecha());
        viaje.setHoraSalida(request.horaSalida());
        viaje.setTarifa(request.tarifa());
        viaje.setTarifaEquipajeExtra(request.tarifaEquipajeExtra());
        viaje.setEstado(EstadoViaje.PROGRAMADO);

        Viaje guardado = viajeRepository.save(viaje);
        inicializarAsientos(guardado, bus);

        log.info("Viaje programado id={} fecha={} hora={}", guardado.getId(), guardado.getFecha(), guardado.getHoraSalida());

        long disponibles = EntityMapper.contarDisponibles(viajeAsientoRepository, guardado.getId());
        return EntityMapper.toViajeResponse(guardado, disponibles);
    }

    @Transactional(readOnly = true)
    public List<ViajeResponse> listarViajesDelOperador(LocalDate fecha, String origen) {
        var operador = operadorContext.resolverOperador(null);
        if (operador.getEmpresa() == null) {
            throw new ReglaNegocioException("El usuario no tiene empresa asignada");
        }

        String origenFiltro = origen;
        if (operador.tieneRol("CAJERO") && !operador.tieneRol("ADMIN_EMPRESA")) {
            if (operador.getSede() == null || operador.getSede().isBlank()) {
                throw new ReglaNegocioException("Su usuario cajero no tiene terminal asignada");
            }
            origenFiltro = operador.getSede();
        }

        return listarPorEmpresaYFecha(operador.getEmpresa().getId(), fecha, origenFiltro);
    }

    @Transactional(readOnly = true)
    public List<ViajeResponse> listarPorEmpresaYFecha(Long empresaId, LocalDate fecha, String origen) {
        Long tenantId = operadorContext.resolverEmpresaId(empresaId);
        empresaService.buscarEntidad(tenantId);

        List<Viaje> viajes = origen != null && !origen.isBlank()
                ? viajeRepository.findByEmpresaAndFechaAndOrigen(tenantId, fecha, origen.trim())
                : viajeRepository.findByEmpresaAndFecha(tenantId, fecha);

        return viajes.stream()
                .map(v -> EntityMapper.toViajeResponse(
                        v,
                        EntityMapper.contarDisponibles(viajeAsientoRepository, v.getId())
                ))
                .toList();
    }

    @Transactional(readOnly = true)
    public ConsultaPublicaDto.DetalleViajeResponse detalleParaOperador(Long viajeId) {
        Viaje viaje = buscarEntidad(viajeId);
        operadorContext.resolverEmpresaId(viaje.getEmpresa().getId());
        return consultaPublicaService.detalleViaje(viajeId);
    }

    @Transactional(readOnly = true)
    public Optional<ViajeResponse> buscar(Long id) {
        return viajeRepository.findWithDetailsById(id)
                .map(v -> {
                    operadorContext.resolverEmpresaId(v.getEmpresa().getId());
                    return EntityMapper.toViajeResponse(
                            v,
                            EntityMapper.contarDisponibles(viajeAsientoRepository, v.getId())
                    );
                });
    }

    @Transactional(readOnly = true)
    public ViajeResponse obtener(Long id) {
        return buscar(id)
                .orElseThrow(() -> new RecursoNoEncontradoException("Viaje no encontrado: " + id));
    }

    public Viaje buscarEntidad(Long id) {
        return viajeRepository.findWithDetailsById(id)
                .orElseThrow(() -> new RecursoNoEncontradoException("Viaje no encontrado: " + id));
    }

    public ViajeResponse actualizar(Long id, ViajeUpdateRequest request) {
        Viaje viaje = buscarEntidad(id);
        operadorContext.resolverEmpresaId(viaje.getEmpresa().getId());

        if (viaje.getEstado() != EstadoViaje.PROGRAMADO) {
            throw new ReglaNegocioException("Solo se puede editar un viaje en estado PROGRAMADO");
        }

        long ocupados = contarAsientosOcupados(viaje.getId());

        if (request.horaSalida() != null) {
            if (ocupados > 0) {
                throw new ReglaNegocioException("No se puede cambiar la hora: ya hay asientos vendidos o reservados");
            }
            viaje.setHoraSalida(request.horaSalida());
        }
        if (request.tarifa() != null) {
            viaje.setTarifa(request.tarifa());
        }
        if (request.tarifaEquipajeExtra() != null) {
            viaje.setTarifaEquipajeExtra(request.tarifaEquipajeExtra());
        }
        if (request.observaciones() != null) {
            viaje.setObservaciones(request.observaciones().isBlank() ? null : request.observaciones().trim());
        }

        Viaje guardado = viajeRepository.save(viaje);
        log.info("Viaje actualizado id={}", id);
        return EntityMapper.toViajeResponse(
                guardado,
                EntityMapper.contarDisponibles(viajeAsientoRepository, guardado.getId())
        );
    }

    public ViajeResponse cancelar(Long id) {
        Viaje viaje = buscarEntidad(id);
        operadorContext.resolverEmpresaId(viaje.getEmpresa().getId());

        if (viaje.getEstado() == EstadoViaje.CANCELADO) {
            throw new ReglaNegocioException("El viaje ya está cancelado");
        }
        if (contarAsientosOcupados(viaje.getId()) > 0) {
            throw new ReglaNegocioException(
                    "No se puede cancelar: hay boletos vendidos o reservas activas. Gestione cancelaciones de boletos primero."
            );
        }

        viaje.setEstado(EstadoViaje.CANCELADO);
        Viaje guardado = viajeRepository.save(viaje);
        log.info("Viaje cancelado id={}", id);
        return EntityMapper.toViajeResponse(
                guardado,
                EntityMapper.contarDisponibles(viajeAsientoRepository, guardado.getId())
        );
    }

    private long contarAsientosOcupados(Long viajeId) {
        return viajeAsientoRepository.countByViajeIdAndEstado(viajeId, EstadoAsientoViaje.VENDIDO)
                + viajeAsientoRepository.countByViajeIdAndEstado(viajeId, EstadoAsientoViaje.RESERVADO_EXCEPCIONAL);
    }

    private void inicializarAsientos(Viaje viaje, Bus bus) {
        List<ViajeAsiento> asientos = new ArrayList<>();
        for (AsientoBus asientoBus : bus.getAsientos()) {
            ViajeAsiento va = new ViajeAsiento();
            va.setViaje(viaje);
            va.setAsientoBus(asientoBus);
            va.setEstado(EstadoAsientoViaje.DISPONIBLE);
            asientos.add(va);
        }
        viajeAsientoRepository.saveAll(asientos);
    }

    private void validarFechaProgramacion(LocalDate fecha) {
        LocalDate hoy = LocalDate.now(clock);
        if (fecha.isBefore(hoy)) {
            throw new ReglaNegocioException("No se puede programar un viaje en una fecha pasada");
        }
    }
}
