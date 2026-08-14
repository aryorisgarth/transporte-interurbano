package com.bluefields.transporte.repository;

import com.bluefields.transporte.domain.entity.ReservaExcepcional;
import com.bluefields.transporte.domain.enums.EstadoReservaExcepcional;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.time.LocalDate;
import java.util.List;

public interface ReservaExcepcionalRepository extends JpaRepository<ReservaExcepcional, Long> {

    @Query("""
            SELECT r FROM ReservaExcepcional r
            JOIN FETCH r.viajeAsiento va
            JOIN FETCH va.asientoBus ab
            JOIN FETCH va.viaje viaje
            JOIN FETCH viaje.bus bus
            JOIN FETCH r.operador op
            WHERE viaje.empresa.id = :empresaId
              AND viaje.fecha = :fecha
              AND r.estado = :estado
              AND (:viajeId IS NULL OR viaje.id = :viajeId)
              AND (:busId IS NULL OR bus.id = :busId)
            ORDER BY viaje.horaSalida ASC, ab.numero ASC
            """)
    List<ReservaExcepcional> findActivasPorFiltros(
            @Param("empresaId") Long empresaId,
            @Param("fecha") LocalDate fecha,
            @Param("viajeId") Long viajeId,
            @Param("busId") Long busId,
            @Param("estado") EstadoReservaExcepcional estado
    );
}
