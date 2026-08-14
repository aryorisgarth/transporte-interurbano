package com.bluefields.transporte.service;

import com.bluefields.transporte.domain.entity.AsientoBus;
import com.bluefields.transporte.domain.entity.Bus;
import com.bluefields.transporte.domain.entity.Empresa;
import com.bluefields.transporte.dto.bus.AsientoUpdateRequest;
import com.bluefields.transporte.dto.bus.BusRequest;
import com.bluefields.transporte.dto.bus.BusResponse;
import com.bluefields.transporte.dto.bus.BusUpdateRequest;
import com.bluefields.transporte.exception.RecursoNoEncontradoException;
import com.bluefields.transporte.exception.ReglaNegocioException;
import com.bluefields.transporte.mapper.EntityMapper;
import com.bluefields.transporte.repository.AsientoBusRepository;
import com.bluefields.transporte.repository.BusRepository;
import com.bluefields.transporte.security.OperadorContext;
import com.bluefields.transporte.util.AsientoLayoutUtil;
import com.bluefields.transporte.util.CorredorUtil;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.Optional;

@Service
@Transactional
public class BusService {

    private static final Logger log = LoggerFactory.getLogger(BusService.class);

    private final BusRepository busRepository;
    private final AsientoBusRepository asientoBusRepository;
    private final EmpresaService empresaService;
    private final OperadorContext operadorContext;

    public BusService(
            BusRepository busRepository,
            AsientoBusRepository asientoBusRepository,
            EmpresaService empresaService,
            OperadorContext operadorContext
    ) {
        this.busRepository = busRepository;
        this.asientoBusRepository = asientoBusRepository;
        this.empresaService = empresaService;
        this.operadorContext = operadorContext;
    }

    public BusResponse crear(BusRequest request) {
        Long empresaId = operadorContext.resolverEmpresaId(request.empresaId());
        validarCapacidad(request.capacidad());

        Empresa empresa = empresaService.buscarEntidad(empresaId);

        Bus bus = new Bus();
        bus.setEmpresa(empresa);
        bus.setNumeroInterno(request.numeroInterno());
        bus.setPlaca(request.placa());
        bus.setCapacidad(request.capacidad());
        bus.setFilas(AsientoLayoutUtil.calcularFilas(request.capacidad()));
        bus.setAsientos(AsientoLayoutUtil.generarAsientos(bus, request.capacidad()));
        CorredorUtil.validarCiudad(request.sede());
        bus.setSede(request.sede());
        if (request.fotoUrl() != null && !request.fotoUrl().isBlank()) {
            bus.setFotoUrl(request.fotoUrl().trim());
        }

        Bus guardado = busRepository.save(bus);
        log.info("Bus creado id={} placa={} capacidad={}", guardado.getId(), guardado.getPlaca(), guardado.getCapacidad());

        return EntityMapper.toBusResponse(guardado);
    }

    public BusResponse actualizar(Long id, BusUpdateRequest request) {
        Bus bus = buscarEntidadConAsientos(id);
        operadorContext.resolverEmpresaId(bus.getEmpresa().getId());

        bus.setNumeroInterno(request.numeroInterno().trim());
        bus.setPlaca(request.placa().trim());
        CorredorUtil.validarCiudad(request.sede());
        bus.setSede(request.sede().trim());
        if (request.fotoUrl() != null) {
            bus.setFotoUrl(request.fotoUrl().isBlank() ? null : request.fotoUrl().trim());
        }
        if (request.activo() != null) {
            bus.setActivo(request.activo());
        }

        log.info("Bus actualizado id={}", id);
        return EntityMapper.toBusResponse(busRepository.save(bus));
    }

    public BusResponse.AsientoResponse actualizarAsiento(Long busId, Long asientoId, AsientoUpdateRequest request) {
        Bus bus = buscarEntidadConAsientos(busId);
        operadorContext.resolverEmpresaId(bus.getEmpresa().getId());

        AsientoBus asiento = asientoBusRepository.findByIdAndBusId(asientoId, busId)
                .orElseThrow(() -> new RecursoNoEncontradoException("Asiento no encontrado en el bus"));

        AsientoLayoutUtil.validarCoherenciaNumeroPosicion(request.numero(), request.fila(), request.posicion());

        if (asientoBusRepository.existsByBusIdAndNumeroAndIdNot(busId, request.numero(), asientoId)) {
            throw new ReglaNegocioException("Ya existe otro asiento con el número " + request.numero());
        }
        if (asientoBusRepository.existsByBusIdAndFilaAndPosicionAndIdNot(
                busId, request.fila(), request.posicion(), asientoId)) {
            throw new ReglaNegocioException("Ya existe un asiento en fila " + request.fila() + " posición " + request.posicion());
        }

        asiento.setNumero(request.numero());
        asiento.setFila(request.fila());
        asiento.setPosicion(request.posicion());

        AsientoBus guardado = asientoBusRepository.save(asiento);
        log.info("Asiento busId={} asientoId={} actualizado a numero={} fila={} posicion={}",
                busId, asientoId, request.numero(), request.fila(), request.posicion());

        return new BusResponse.AsientoResponse(
                guardado.getId(),
                guardado.getNumero(),
                guardado.getFila(),
                guardado.getPosicion()
        );
    }

    @Transactional(readOnly = true)
    public List<BusResponse> listarBusesDelOperador(String sede) {
        var operador = operadorContext.resolverOperador(null);
        if (operador.getEmpresa() == null) {
            throw new ReglaNegocioException("Seleccione empresaId; el admin general debe usar listarPorEmpresa");
        }
        return listarPorEmpresa(operador.getEmpresa().getId(), sede);
    }

    @Transactional(readOnly = true)
    public List<BusResponse> listarPorEmpresa(Long empresaId, String sede) {
        Long tenantId = operadorContext.resolverEmpresaId(empresaId);
        empresaService.buscarEntidad(tenantId);

        var buses = sede != null && !sede.isBlank()
                ? busRepository.findByEmpresaIdAndSedeAndActivoTrue(tenantId, sede.trim())
                : busRepository.findByEmpresaIdOrderByNumeroInternoAsc(tenantId);

        return buses.stream().map(EntityMapper::toBusResponse).toList();
    }

    @Transactional(readOnly = true)
    public Optional<BusResponse> buscar(Long id) {
        return busRepository.findWithAsientosById(id)
                .filter(b -> Boolean.TRUE.equals(b.getActivo()))
                .map(b -> {
                    operadorContext.resolverEmpresaId(b.getEmpresa().getId());
                    return EntityMapper.toBusResponse(b);
                });
    }

    @Transactional(readOnly = true)
    public BusResponse obtener(Long id) {
        return buscar(id)
                .orElseThrow(() -> new RecursoNoEncontradoException("Bus no encontrado: " + id));
    }

    public Bus buscarEntidad(Long id) {
        return busRepository.findWithAsientosById(id)
                .orElseThrow(() -> new RecursoNoEncontradoException("Bus no encontrado: " + id));
    }

    private Bus buscarEntidadConAsientos(Long id) {
        return busRepository.findWithAsientosById(id)
                .orElseThrow(() -> new RecursoNoEncontradoException("Bus no encontrado: " + id));
    }

    private void validarCapacidad(int capacidad) {
        if (capacidad <= 0) {
            throw new ReglaNegocioException("La capacidad debe ser mayor a 0");
        }
        if (capacidad != AsientoLayoutUtil.CAPACIDAD_ESTANDAR && capacidad % 2 != 0) {
            throw new ReglaNegocioException(
                    "Use capacidad " + AsientoLayoutUtil.CAPACIDAD_ESTANDAR
                            + " (layout interurbano) o un número par para layout simple"
            );
        }
    }
}
