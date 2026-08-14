package com.bluefields.transporte.repository;

import com.bluefields.transporte.domain.entity.Rol;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Collection;
import java.util.List;
import java.util.Optional;

public interface RolRepository extends JpaRepository<Rol, Long> {
    Optional<Rol> findByNombre(String nombre);

    List<Rol> findByNombreIn(Collection<String> nombres);
}
