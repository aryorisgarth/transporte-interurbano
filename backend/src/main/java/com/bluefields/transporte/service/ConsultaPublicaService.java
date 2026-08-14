package com.bluefields.transporte.service;

import com.bluefields.transporte.domain.entity.Viaje;
import com.bluefields.transporte.domain.enums.EstadoAsientoViaje;
import com.bluefields.transporte.domain.enums.EstadoViaje;
import com.bluefields.transporte.dto.consulta.ConsultaPublicaDto;
import com.bluefields.transporte.exception.RecursoNoEncontradoException;
import com.bluefields.transporte.mapper.EntityMapper;
import com.bluefields.transporte.repository.ViajeAsientoRepository;
import com.bluefields.transporte.repository.ViajeRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDate;
import java.util.List;

@Service
@Transactional(readOnly = true)
public class ConsultaPublicaService {

    private final ViajeRepository viajeRepository;
    private final ViajeAsientoRepository viajeAsientoRepository;
    private final ParadaRutaService paradaRutaService;

    public ConsultaPublicaService(
            ViajeRepository viajeRepository,
            ViajeAsientoRepository viajeAsientoRepository,
            ParadaRutaService paradaRutaService
    ) {
        this.viajeRepository = viajeRepository;
        this.viajeAsientoRepository = viajeAsientoRepository;
        this.paradaRutaService = paradaRutaService;
    }

    public List<ConsultaPublicaDto.ViajeDisponibleResponse> buscarViajes(
            String origen,
            String destino,
            LocalDate fecha
    ) {
        String origenFinal = origen != null ? origen : "Bluefields";
        String destinoFinal = destino != null ? destino : "Managua";

        return viajeRepository.buscarViajesPublicos(origenFinal, destinoFinal, fecha, EstadoViaje.PROGRAMADO)
                .stream()
                .map(v -> {
                    long disponibles = EntityMapper.contarDisponibles(viajeAsientoRepository, v.getId());
                    return EntityMapper.toConsultaViaje(v, disponibles);
                })
                .toList();
    }

    public ConsultaPublicaDto.DetalleViajeResponse detalleViaje(Long viajeId) {
        Viaje viaje = viajeRepository.findWithDetailsById(viajeId)
                .orElseThrow(() -> new RecursoNoEncontradoException("Viaje no encontrado: " + viajeId));

        var asientos = viajeAsientoRepository.findByViajeIdOrderByAsientoBusNumeroAsc(viajeId).stream()
                .map(EntityMapper::toAsientoConsulta)
                .toList();

        long disponibles = asientos.stream()
                .filter(a -> a.estado() == EstadoAsientoViaje.DISPONIBLE)
                .count();

        var paradas = paradaRutaService.listarPorRuta(
                viaje.getOrigen(),
                viaje.getDestino(),
                viaje.getHoraSalida()
        );

        return new ConsultaPublicaDto.DetalleViajeResponse(
                viaje.getId(),
                viaje.getEmpresa().getNombre(),
                viaje.getEmpresa().getLogoUrl(),
                viaje.getBus().getNumeroInterno(),
                viaje.getBus().getFotoUrl(),
                viaje.getOrigen(),
                viaje.getDestino(),
                viaje.getFecha(),
                viaje.getHoraSalida().toString(),
                viaje.getTarifa(),
                viaje.getTarifaEquipajeExtra() != null
                        ? viaje.getTarifaEquipajeExtra()
                        : viaje.getEmpresa().getTarifaEquipajeExtra(),
                disponibles,
                asientos,
                paradas
        );
    }
}
