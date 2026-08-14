package com.bluefields.transporte.service;

import com.bluefields.transporte.domain.entity.ParadaRuta;
import com.bluefields.transporte.dto.parada.ParadaCreateRequest;
import com.bluefields.transporte.dto.parada.ParadaDto;
import com.bluefields.transporte.dto.parada.ParadaUpdateRequest;
import com.bluefields.transporte.exception.RecursoNoEncontradoException;
import com.bluefields.transporte.exception.ReglaNegocioException;
import com.bluefields.transporte.repository.ParadaRutaRepository;
import com.bluefields.transporte.util.CorredorUtil;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalTime;
import java.util.List;

@Service
@Transactional(readOnly = true)
public class ParadaRutaService {

    private final ParadaRutaRepository paradaRutaRepository;

    public ParadaRutaService(ParadaRutaRepository paradaRutaRepository) {
        this.paradaRutaRepository = paradaRutaRepository;
    }

    public List<ParadaDto.ParadaResponse> listarPorRuta(String origen, String destino, LocalTime horaSalida) {
        String origenFinal = origen != null ? origen : CorredorUtil.BLUEFIELDS;
        String destinoFinal = destino != null ? destino : CorredorUtil.MANAGUA;

        return paradaRutaRepository.findByOrigenAndDestinoAndActivoTrueOrderByOrdenAsc(origenFinal, destinoFinal)
                .stream()
                .map(p -> toResponse(p, horaSalida))
                .toList();
    }

    @Transactional
    public ParadaDto.ParadaResponse crear(ParadaCreateRequest request) {
        CorredorUtil.validarPar(request.origen(), request.destino());

        int siguienteOrden = paradaRutaRepository
                .findTopByOrigenAndDestinoOrderByOrdenDesc(request.origen(), request.destino())
                .map(p -> p.getOrden() + 1)
                .orElse(1);

        ParadaRuta parada = new ParadaRuta();
        parada.setOrigen(request.origen());
        parada.setDestino(request.destino());
        parada.setNombre(request.nombre().trim());
        parada.setOrden(siguienteOrden);
        parada.setMinutosDesdeSalida(request.minutosDesdeSalida());
        parada.setLatitud(request.latitud());
        parada.setLongitud(request.longitud());
        parada.setActivo(true);

        return toResponse(paradaRutaRepository.save(parada), null);
    }

    @Transactional
    public ParadaDto.ParadaResponse actualizar(Long id, ParadaUpdateRequest request) {
        ParadaRuta parada = paradaRutaRepository.findById(id)
                .orElseThrow(() -> new RecursoNoEncontradoException("Parada no encontrada: " + id));

        if (!Boolean.TRUE.equals(parada.getActivo())) {
            throw new ReglaNegocioException("La parada está inactiva");
        }

        parada.setNombre(request.nombre().trim());
        parada.setMinutosDesdeSalida(request.minutosDesdeSalida());
        parada.setLatitud(request.latitud());
        parada.setLongitud(request.longitud());

        return toResponse(parada, null);
    }

    @Transactional
    public void eliminar(Long id) {
        ParadaRuta parada = paradaRutaRepository.findById(id)
                .orElseThrow(() -> new RecursoNoEncontradoException("Parada no encontrada: " + id));

        long activas = paradaRutaRepository
                .findByOrigenAndDestinoAndActivoTrueOrderByOrdenAsc(parada.getOrigen(), parada.getDestino())
                .size();

        if (activas <= 2) {
            throw new ReglaNegocioException("La ruta debe tener al menos salida y llegada (2 paradas)");
        }

        parada.setActivo(false);
    }

    private ParadaDto.ParadaResponse toResponse(ParadaRuta parada, LocalTime horaSalida) {
        String horaEstimada = null;
        if (horaSalida != null) {
            horaEstimada = horaSalida.plusMinutes(parada.getMinutosDesdeSalida()).toString().substring(0, 5);
        }

        Double lat = parada.getLatitud() != null ? parada.getLatitud().doubleValue() : null;
        Double lng = parada.getLongitud() != null ? parada.getLongitud().doubleValue() : null;

        return new ParadaDto.ParadaResponse(
                parada.getId(),
                parada.getNombre(),
                parada.getOrden(),
                parada.getMinutosDesdeSalida(),
                horaEstimada,
                lat,
                lng
        );
    }
}
