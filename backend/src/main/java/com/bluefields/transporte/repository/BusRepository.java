package com.bluefields.transporte.repository;

import com.bluefields.transporte.domain.entity.Bus;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import java.util.List;
import java.util.Optional;

public interface BusRepository extends JpaRepository<Bus, Long> {

    List<Bus> findByEmpresaIdAndActivoTrue(Long empresaId);

    List<Bus> findByEmpresaIdAndSedeAndActivoTrue(Long empresaId, String sede);

    List<Bus> findByEmpresaIdOrderByNumeroInternoAsc(Long empresaId);

    @Query("SELECT b FROM Bus b LEFT JOIN FETCH b.asientos WHERE b.id = :id")
    Optional<Bus> findWithAsientosById(@Param("id") Long id);

    long countByEmpresaIdAndActivoTrue(Long empresaId);

    long countByEmpresaIdAndActivoFalse(Long empresaId);
}
