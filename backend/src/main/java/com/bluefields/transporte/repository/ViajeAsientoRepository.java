package com.bluefields.transporte.repository;

import com.bluefields.transporte.domain.entity.ViajeAsiento;
import com.bluefields.transporte.domain.enums.EstadoAsientoViaje;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import java.util.List;
import java.util.Optional;

public interface ViajeAsientoRepository extends JpaRepository<ViajeAsiento, Long> {

    List<ViajeAsiento> findByViajeIdOrderByAsientoBusNumeroAsc(Long viajeId);

    long countByViajeIdAndEstado(Long viajeId, EstadoAsientoViaje estado);

    @Query("""
            SELECT va FROM ViajeAsiento va
            JOIN FETCH va.asientoBus ab
            WHERE va.id IN :ids AND va.viaje.id = :viajeId
            """)
    List<ViajeAsiento> findByViajeIdAndIdIn(
            @Param("viajeId") Long viajeId,
            @Param("ids") List<Long> ids
    );

    Optional<ViajeAsiento> findByIdAndViajeId(Long id, Long viajeId);

    @Query("""
            SELECT va FROM ViajeAsiento va
            JOIN FETCH va.viaje v
            JOIN FETCH v.empresa e
            JOIN FETCH va.asientoBus ab
            WHERE va.id = :id
            """)
    Optional<ViajeAsiento> findByIdWithViaje(@Param("id") Long id);
}
