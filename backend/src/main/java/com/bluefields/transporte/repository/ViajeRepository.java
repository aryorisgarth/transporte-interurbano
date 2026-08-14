package com.bluefields.transporte.repository;

import com.bluefields.transporte.domain.entity.Viaje;
import com.bluefields.transporte.domain.enums.EstadoViaje;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.time.LocalDate;
import java.util.List;
import java.util.Optional;

public interface ViajeRepository extends JpaRepository<Viaje, Long> {

    @Query("""
            SELECT v FROM Viaje v
            JOIN FETCH v.empresa e
            JOIN FETCH v.bus b
            WHERE v.id = :id
            """)
    Optional<Viaje> findWithDetailsById(@Param("id") Long id);

    @Query("""
            SELECT v FROM Viaje v
            JOIN FETCH v.empresa e
            JOIN FETCH v.bus b
            WHERE v.empresa.id = :empresaId
              AND v.fecha = :fecha
            ORDER BY v.horaSalida
            """)
    List<Viaje> findByEmpresaAndFecha(
            @Param("empresaId") Long empresaId,
            @Param("fecha") LocalDate fecha
    );

    @Query("""
            SELECT v FROM Viaje v
            JOIN FETCH v.empresa e
            JOIN FETCH v.bus b
            WHERE v.empresa.id = :empresaId
              AND v.fecha = :fecha
              AND v.origen = :origen
            ORDER BY v.horaSalida
            """)
    List<Viaje> findByEmpresaAndFechaAndOrigen(
            @Param("empresaId") Long empresaId,
            @Param("fecha") LocalDate fecha,
            @Param("origen") String origen
    );

    @Query("""
            SELECT v FROM Viaje v
            JOIN FETCH v.empresa e
            JOIN FETCH v.bus b
            WHERE v.origen = :origen
              AND v.destino = :destino
              AND v.fecha = :fecha
              AND v.estado = :estado
            ORDER BY v.horaSalida
            """)
    List<Viaje> buscarViajesPublicos(
            @Param("origen") String origen,
            @Param("destino") String destino,
            @Param("fecha") LocalDate fecha,
            @Param("estado") EstadoViaje estado
    );

    List<Viaje> findByBusId(Long busId);

    long countByEmpresaIdAndFecha(Long empresaId, LocalDate fecha);
}
