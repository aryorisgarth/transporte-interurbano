package com.bluefields.transporte.repository;

import com.bluefields.transporte.domain.entity.Empresa;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.List;
import java.util.Optional;

public interface EmpresaRepository extends JpaRepository<Empresa, Long> {

    List<Empresa> findByActivoTrueOrderByNombreAsc();

    Optional<Empresa> findByIdAndActivoTrue(Long id);
}
