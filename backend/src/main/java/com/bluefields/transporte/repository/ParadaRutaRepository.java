package com.bluefields.transporte.repository;

import com.bluefields.transporte.domain.entity.ParadaRuta;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;

public interface ParadaRutaRepository extends JpaRepository<ParadaRuta, Long> {

    List<ParadaRuta> findByOrigenAndDestinoAndActivoTrueOrderByOrdenAsc(String origen, String destino);

    Optional<ParadaRuta> findTopByOrigenAndDestinoOrderByOrdenDesc(String origen, String destino);
}
