package com.bluefields.transporte.service;

import com.bluefields.transporte.domain.entity.Boleto;
import com.bluefields.transporte.domain.entity.ReservaExcepcional;
import com.bluefields.transporte.domain.enums.EstadoBoleto;
import com.bluefields.transporte.domain.enums.EstadoReservaExcepcional;
import com.bluefields.transporte.domain.enums.EstadoVenta;
import com.bluefields.transporte.dto.pasajero.PasajeroDto;
import com.bluefields.transporte.exception.ReglaNegocioException;
import com.bluefields.transporte.repository.BoletoRepository;
import com.bluefields.transporte.repository.ReservaExcepcionalRepository;
import com.bluefields.transporte.security.OperadorContext;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDate;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.List;

@Service
@Transactional(readOnly = true)
public class PasajeroService {

    private final BoletoRepository boletoRepository;
    private final ReservaExcepcionalRepository reservaRepository;
    private final OperadorContext operadorContext;

    public PasajeroService(
            BoletoRepository boletoRepository,
            ReservaExcepcionalRepository reservaRepository,
            OperadorContext operadorContext
    ) {
        this.boletoRepository = boletoRepository;
        this.reservaRepository = reservaRepository;
        this.operadorContext = operadorContext;
    }

    public List<PasajeroDto.ManifiestoPasajeroResponse> manifiesto(
            LocalDate fecha,
            Long viajeId,
            Long busId,
            Long empresaIdRequest
    ) {
        var operador = operadorContext.resolverOperador(null);
        if (operador.getEmpresa() == null) {
            throw new ReglaNegocioException(
                    "El administrador de plataforma no puede consultar datos personales de pasajeros"
            );
        }

        Long empresaId = operador.getEmpresa().getId();
        if (empresaIdRequest != null && !empresaIdRequest.equals(empresaId)) {
            throw new ReglaNegocioException("Acceso denegado: no puede consultar pasajeros de otra empresa");
        }

        List<PasajeroDto.ManifiestoPasajeroResponse> filas = new ArrayList<>();

        boletoRepository.findManifiesto(
                empresaId,
                fecha,
                viajeId,
                busId,
                EstadoBoleto.ACTIVO,
                EstadoVenta.COMPLETADA
        ).stream()
                .map(this::toManifiestoBoleto)
                .forEach(filas::add);

        reservaRepository.findActivasPorFiltros(
                empresaId,
                fecha,
                viajeId,
                busId,
                EstadoReservaExcepcional.ACTIVA
        ).stream()
                .map(this::toManifiestoReserva)
                .forEach(filas::add);

        filas.sort(Comparator
                .comparing(PasajeroDto.ManifiestoPasajeroResponse::horaSalida)
                .thenComparing(PasajeroDto.ManifiestoPasajeroResponse::numeroAsiento));

        if (operador.tieneRol("CAJERO") && !operador.tieneRol("ADMIN_EMPRESA")) {
            if (operador.getSede() == null || operador.getSede().isBlank()) {
                throw new ReglaNegocioException("Su usuario cajero no tiene terminal asignada");
            }
            String terminal = operador.getSede();
            filas = filas.stream()
                    .filter(f -> terminal.equals(f.origen()))
                    .toList();
        }

        return filas;
    }

    private PasajeroDto.ManifiestoPasajeroResponse toManifiestoBoleto(Boleto b) {
        var v = b.getVenta();
        var viaje = v.getViaje();
        var bus = viaje.getBus();

        return new PasajeroDto.ManifiestoPasajeroResponse(
                b.getId(),
                viaje.getId(),
                viaje.getFecha(),
                viaje.getHoraSalida().toString(),
                viaje.getOrigen(),
                viaje.getDestino(),
                bus.getNumeroInterno(),
                bus.getPlaca(),
                b.getNumeroAsiento(),
                b.getPasajeroNombre() != null ? b.getPasajeroNombre() : v.getCompradorNombre(),
                b.getPasajeroCedula() != null ? b.getPasajeroCedula() : v.getCompradorCedula(),
                v.getCompradorTelefono(),
                v.getCodigo(),
                v.getOperador().getNombreCompleto(),
                b.getEstado().name(),
                Boolean.TRUE.equals(b.getEsMenor())
        );
    }

    private PasajeroDto.ManifiestoPasajeroResponse toManifiestoReserva(ReservaExcepcional r) {
        var va = r.getViajeAsiento();
        var viaje = va.getViaje();
        var bus = viaje.getBus();

        return new PasajeroDto.ManifiestoPasajeroResponse(
                -r.getId(),
                viaje.getId(),
                viaje.getFecha(),
                viaje.getHoraSalida().toString(),
                viaje.getOrigen(),
                viaje.getDestino(),
                bus.getNumeroInterno(),
                bus.getPlaca(),
                va.getAsientoBus().getNumero(),
                r.getCompradorNombre(),
                r.getCompradorCedula(),
                r.getCompradorTelefono(),
                "RESERVA-" + r.getId(),
                r.getOperador().getNombreCompleto(),
                "RESERVA_EXCEPCIONAL",
                false
        );
    }
}
