package com.bluefields.transporte.service;

import com.bluefields.transporte.domain.entity.Empresa;
import com.bluefields.transporte.domain.entity.Usuario;
import com.bluefields.transporte.dto.empresa.DetalleCooperativaResponse;
import com.bluefields.transporte.dto.empresa.EmpresaRequest;
import com.bluefields.transporte.dto.empresa.EmpresaResponse;
import com.bluefields.transporte.dto.empresa.ResumenEmpresaResponse;
import com.bluefields.transporte.exception.RecursoNoEncontradoException;
import com.bluefields.transporte.exception.ReglaNegocioException;
import com.bluefields.transporte.mapper.EntityMapper;
import com.bluefields.transporte.repository.BoletoRepository;
import com.bluefields.transporte.repository.BusRepository;
import com.bluefields.transporte.repository.EmpresaRepository;
import com.bluefields.transporte.repository.UsuarioRepository;
import com.bluefields.transporte.repository.ViajeRepository;
import com.bluefields.transporte.security.OperadorContext;
import com.bluefields.transporte.domain.enums.EstadoBoleto;
import com.bluefields.transporte.domain.enums.EstadoVenta;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Clock;
import java.time.LocalDate;
import java.util.List;
import java.util.Optional;

@Service
@Transactional
public class EmpresaService {

    private static final Logger log = LoggerFactory.getLogger(EmpresaService.class);

    private final EmpresaRepository empresaRepository;
    private final BusRepository busRepository;
    private final UsuarioRepository usuarioRepository;
    private final ViajeRepository viajeRepository;
    private final BoletoRepository boletoRepository;
    private final OperadorContext operadorContext;
    private final Clock clock;

    public EmpresaService(
            EmpresaRepository empresaRepository,
            BusRepository busRepository,
            UsuarioRepository usuarioRepository,
            ViajeRepository viajeRepository,
            BoletoRepository boletoRepository,
            OperadorContext operadorContext,
            Clock clock
    ) {
        this.empresaRepository = empresaRepository;
        this.busRepository = busRepository;
        this.usuarioRepository = usuarioRepository;
        this.viajeRepository = viajeRepository;
        this.boletoRepository = boletoRepository;
        this.operadorContext = operadorContext;
        this.clock = clock;
    }

    public EmpresaResponse crear(EmpresaRequest request) {
        log.debug("Creando empresa: {}", request.nombre());

        Empresa empresa = new Empresa();
        aplicarDatos(empresa, request);

        Empresa guardada = empresaRepository.save(empresa);
        log.info("Empresa creada id={} nombre={}", guardada.getId(), guardada.getNombre());

        return EntityMapper.toEmpresaResponse(guardada);
    }

    public EmpresaResponse actualizar(Long id, EmpresaRequest request) {
        operadorContext.resolverEmpresaId(id);
        log.debug("Actualizando empresa id={}", id);

        Empresa empresa = buscarEntidad(id);
        aplicarDatos(empresa, request);

        Empresa guardada = empresaRepository.save(empresa);
        log.info("Empresa actualizada id={}", guardada.getId());

        return EntityMapper.toEmpresaResponse(guardada);
    }

    public void desactivar(Long id) {
        Empresa empresa = buscarEntidad(id);
        empresa.setActivo(false);
        empresaRepository.save(empresa);
        log.info("Empresa desactivada id={}", id);
    }

    @Transactional(readOnly = true)
    public List<ResumenEmpresaResponse> resumenPlataforma() {
        var operador = operadorContext.resolverOperador(null);
        if (operador.getEmpresa() != null) {
            throw new ReglaNegocioException("Solo el administrador de plataforma puede ver el resumen global");
        }

        LocalDate hoy = LocalDate.now(clock);
        return empresaRepository.findByActivoTrueOrderByNombreAsc().stream()
                .map(e -> new ResumenEmpresaResponse(
                        e.getId(),
                        e.getNombre(),
                        Boolean.TRUE.equals(e.getActivo()),
                        (int) busRepository.countByEmpresaIdAndActivoTrue(e.getId()),
                        (int) usuarioRepository.countByEmpresaIdAndActivoTrue(e.getId()),
                        (int) viajeRepository.countByEmpresaIdAndFecha(e.getId(), hoy),
                        (int) boletoRepository.countVendidosPorEmpresaYFecha(
                                e.getId(), hoy, EstadoBoleto.ACTIVO, EstadoVenta.COMPLETADA
                        )
                ))
                .toList();
    }

    @Transactional(readOnly = true)
    public DetalleCooperativaResponse detallePlataforma(Long id) {
        var operador = operadorContext.resolverOperador(null);
        if (operador.getEmpresa() != null) {
            throw new ReglaNegocioException("Solo el administrador de plataforma puede ver el detalle global");
        }

        Empresa empresa = buscarEntidad(id);
        LocalDate hoy = LocalDate.now(clock);

        var operadores = usuarioRepository.findByEmpresaIdOrderByNombreCompletoAsc(id);
        int adminsActivos = 0;
        int adminsInactivos = 0;
        int cajerosActivos = 0;
        int cajerosInactivos = 0;

        var operadoresDto = new java.util.ArrayList<DetalleCooperativaResponse.OperadorCooperativaResponse>();
        for (Usuario u : operadores) {
            boolean esAdmin = u.tieneRol("ADMIN_EMPRESA");
            boolean esCajero = u.tieneRol("CAJERO") && !esAdmin;
            boolean activo = Boolean.TRUE.equals(u.getActivo());
            if (esAdmin) {
                if (activo) adminsActivos++;
                else adminsInactivos++;
            }
            if (esCajero) {
                if (activo) cajerosActivos++;
                else cajerosInactivos++;
            }
            var roles = u.getRoles().stream().map(r -> r.getNombre()).sorted().toList();
            String emailLogin = u.getEmailLogin();
            if (emailLogin == null || emailLogin.isBlank()) {
                emailLogin = u.getNombreUsuario() + "@transporte.local";
            }
            operadoresDto.add(new DetalleCooperativaResponse.OperadorCooperativaResponse(
                    u.getId(),
                    u.getNombreUsuario(),
                    emailLogin,
                    u.getNombreCompleto(),
                    u.getSede(),
                    u.getActivo(),
                    roles
            ));
        }

        var buses = busRepository.findByEmpresaIdOrderByNumeroInternoAsc(id).stream()
                .map(b -> new DetalleCooperativaResponse.BusCooperativaResponse(
                        b.getId(),
                        b.getNumeroInterno(),
                        b.getPlaca(),
                        b.getSede(),
                        b.getCapacidad(),
                        b.getActivo()
                ))
                .toList();

        var metricas = new DetalleCooperativaResponse.MetricasCooperativa(
                (int) busRepository.countByEmpresaIdAndActivoTrue(id),
                (int) busRepository.countByEmpresaIdAndActivoFalse(id),
                adminsActivos,
                adminsInactivos,
                cajerosActivos,
                cajerosInactivos,
                (int) viajeRepository.countByEmpresaIdAndFecha(id, hoy),
                (int) boletoRepository.countVendidosPorEmpresaYFecha(
                        id, hoy, EstadoBoleto.ACTIVO, EstadoVenta.COMPLETADA
                )
        );

        return new DetalleCooperativaResponse(
                EntityMapper.toEmpresaResponse(empresa),
                metricas,
                operadoresDto,
                buses
        );
    }

    @Transactional(readOnly = true)
    public List<EmpresaResponse> listarTodasActivas() {
        var operador = operadorContext.resolverOperador(null);
        if (operador.getEmpresa() != null) {
            throw new ReglaNegocioException(
                    "Use GET /api/empresas/mi-empresa — su usuario solo puede ver su cooperativa"
            );
        }
        return empresaRepository.findByActivoTrueOrderByNombreAsc().stream()
                .map(EntityMapper::toEmpresaResponse)
                .toList();
    }

    @Transactional(readOnly = true)
    public List<EmpresaResponse> listarActivas() {
        return listarTodasActivas();
    }

    @Transactional(readOnly = true)
    public EmpresaResponse miEmpresa() {
        var operador = operadorContext.resolverOperador(null);
        if (operador.getEmpresa() == null) {
            throw new ReglaNegocioException("Su usuario no pertenece a una empresa (use modo admin global)");
        }
        return EntityMapper.toEmpresaResponse(operador.getEmpresa());
    }

    @Transactional(readOnly = true)
    public Optional<EmpresaResponse> buscarActiva(Long id) {
        operadorContext.resolverEmpresaId(id);
        return empresaRepository.findByIdAndActivoTrue(id)
                .map(EntityMapper::toEmpresaResponse);
    }

    @Transactional(readOnly = true)
    public EmpresaResponse obtener(Long id) {
        return buscarActiva(id)
                .orElseThrow(() -> new RecursoNoEncontradoException("Empresa no encontrada: " + id));
    }

    public Empresa buscarEntidad(Long id) {
        return empresaRepository.findById(id)
                .filter(e -> Boolean.TRUE.equals(e.getActivo()))
                .orElseThrow(() -> new RecursoNoEncontradoException("Empresa no encontrada: " + id));
    }

    private void aplicarDatos(Empresa empresa, EmpresaRequest request) {
        empresa.setNombre(request.nombre().trim());
        empresa.setTelefono(request.telefono());
        empresa.setCorreo(request.correo());
        if (request.tarifaEquipajeExtra() != null) {
            empresa.setTarifaEquipajeExtra(request.tarifaEquipajeExtra());
        }
        if (request.logoUrl() != null) {
            empresa.setLogoUrl(request.logoUrl().isBlank() ? null : request.logoUrl().trim());
        }
    }
}
