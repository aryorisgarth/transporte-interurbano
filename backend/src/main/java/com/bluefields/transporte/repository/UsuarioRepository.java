package com.bluefields.transporte.repository;

import com.bluefields.transporte.domain.entity.Usuario;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.Optional;
import java.util.List;

public interface UsuarioRepository extends JpaRepository<Usuario, Long> {
    Optional<Usuario> findByNombreUsuario(String nombreUsuario);

    boolean existsByNombreUsuario(String nombreUsuario);

    List<Usuario> findByEmpresaIdOrderByNombreCompletoAsc(Long empresaId);

    @Query("SELECT u FROM Usuario u LEFT JOIN FETCH u.empresa WHERE u.nombreUsuario = :nombre")
    Optional<Usuario> findByNombreUsuarioWithEmpresa(@Param("nombre") String nombreUsuario);

    @Query("SELECT u FROM Usuario u LEFT JOIN FETCH u.empresa WHERE u.id = :id")
    Optional<Usuario> findByIdWithEmpresa(@Param("id") Long id);

    long countByEmpresaIdAndActivoTrue(Long empresaId);
}
