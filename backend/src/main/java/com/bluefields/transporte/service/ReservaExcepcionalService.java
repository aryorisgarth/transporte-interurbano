package com.bluefields.transporte.service;

import com.bluefields.transporte.domain.entity.ReservaExcepcional;
import com.bluefields.transporte.domain.entity.Usuario;
import com.bluefields.transporte.domain.entity.ViajeAsiento;
import com.bluefields.transporte.domain.enums.EstadoAsientoViaje;
import com.bluefields.transporte.domain.enums.EstadoReservaExcepcional;
import com.bluefields.transporte.dto.reserva.ReservaExcepcionalDto;
import com.bluefields.transporte.exception.RecursoNoEncontradoException;
import com.bluefields.transporte.exception.ReglaNegocioException;
import com.bluefields.transporte.repository.ReservaExcepcionalRepository;
import com.bluefields.transporte.repository.ViajeAsientoRepository;
import com.bluefields.transporte.security.OperadorContext;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.GrantedAuthority;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Clock;
import java.time.Instant;
import java.time.temporal.ChronoUnit;

@Service
@Transactional
public class ReservaExcepcionalService {

    private final ReservaExcepcionalRepository reservaRepository;
    private final ViajeAsientoRepository viajeAsientoRepository;
    private final OperadorContext operadorContext;
    private final Clock clock;

    public ReservaExcepcionalService(
            ReservaExcepcionalRepository reservaRepository,
            ViajeAsientoRepository viajeAsientoRepository,
            OperadorContext operadorContext,
            Clock clock
    ) {
        this.reservaRepository = reservaRepository;
        this.viajeAsientoRepository = viajeAsientoRepository;
        this.operadorContext = operadorContext;
        this.clock = clock;
    }

    public ReservaExcepcionalDto.ReservaResponse crear(ReservaExcepcionalDto.ReservaRequest request) {
        validarPermisoReserva();

        ViajeAsiento asiento = viajeAsientoRepository.findByIdWithViaje(request.viajeAsientoId())
                .orElseThrow(() -> new RecursoNoEncontradoException(
                        "Asiento no encontrado: " + request.viajeAsientoId()
                ));

        operadorContext.resolverEmpresaId(asiento.getViaje().getEmpresa().getId());

        if (asiento.getEstado() != EstadoAsientoViaje.DISPONIBLE) {
            throw new ReglaNegocioException("El asiento no esta disponible para reserva excepcional");
        }

        Usuario operador = operadorContext.resolverOperador(null);

        int horas = request.horasExpiracion() != null && request.horasExpiracion() > 0
                ? request.horasExpiracion()
                : 24;

        ReservaExcepcional reserva = new ReservaExcepcional();
        reserva.setViajeAsiento(asiento);
        reserva.setOperador(operador);
        reserva.setCompradorNombre(request.compradorNombre().trim());
        reserva.setCompradorCedula(request.compradorCedula().trim());
        reserva.setCompradorTelefono(request.compradorTelefono());
        reserva.setMotivo(request.motivo().trim());
        reserva.setEstado(EstadoReservaExcepcional.ACTIVA);
        reserva.setFechaExpiracion(Instant.now(clock).plus(horas, ChronoUnit.HOURS));

        asiento.setEstado(EstadoAsientoViaje.RESERVADO_EXCEPCIONAL);

        ReservaExcepcional guardada = reservaRepository.save(reserva);

        return toResponse(guardada);
    }

    private void validarPermisoReserva() {
        Authentication auth = SecurityContextHolder.getContext().getAuthentication();
        if (auth == null) {
            throw new ReglaNegocioException("Debe autenticarse para reserva excepcional");
        }
        boolean permitido = auth.getAuthorities().stream()
                .map(GrantedAuthority::getAuthority)
                .anyMatch(role -> role.equals("ROLE_RESERVA_EXCEPCIONAL")
                        || role.equals("ROLE_ADMIN_EMPRESA")
                        || role.equals("ROLE_ADMIN_GENERAL"));
        if (!permitido) {
            throw new ReglaNegocioException(
                    "No tiene permiso RESERVA_EXCEPCIONAL para apartar asientos sin venta"
            );
        }
    }

    private ReservaExcepcionalDto.ReservaResponse toResponse(ReservaExcepcional r) {
        return new ReservaExcepcionalDto.ReservaResponse(
                r.getId(),
                r.getViajeAsiento().getId(),
                r.getViajeAsiento().getAsientoBus().getNumero(),
                r.getViajeAsiento().getViaje().getId(),
                r.getCompradorNombre(),
                r.getCompradorCedula(),
                r.getMotivo(),
                r.getEstado().name(),
                r.getFechaExpiracion() != null ? r.getFechaExpiracion().toString() : null
        );
    }
}
