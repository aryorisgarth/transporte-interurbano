package com.bluefields.transporte.repository;

import com.bluefields.transporte.domain.entity.AsientoBus;
import java.util.Optional;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

public interface AsientoBusRepository extends JpaRepository<AsientoBus, Long> {

    @Query("""
            SELECT a FROM AsientoBus a
            JOIN FETCH a.bus b
            WHERE a.id = :asientoId AND b.id = :busId
            """)
    Optional<AsientoBus> findByIdAndBusId(@Param("asientoId") Long asientoId, @Param("busId") Long busId);

    boolean existsByBusIdAndNumeroAndIdNot(Long busId, Integer numero, Long id);

    boolean existsByBusIdAndFilaAndPosicionAndIdNot(
            Long busId, Integer fila, com.bluefields.transporte.domain.enums.PosicionAsiento posicion, Long id
    );
}
