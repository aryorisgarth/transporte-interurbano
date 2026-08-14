package com.bluefields.transporte.repository;

import com.bluefields.transporte.domain.entity.Boleto;
import com.bluefields.transporte.domain.enums.EstadoBoleto;
import com.bluefields.transporte.domain.enums.EstadoVenta;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.time.LocalDate;
import java.util.List;

public interface BoletoRepository extends JpaRepository<Boleto, Long> {

    @Query("""
            SELECT b FROM Boleto b
            JOIN FETCH b.venta v
            JOIN FETCH v.viaje viaje
            JOIN FETCH viaje.bus bus
            JOIN FETCH v.operador op
            JOIN FETCH v.empresa e
            WHERE e.id = :empresaId
              AND viaje.fecha = :fecha
              AND b.estado = :estadoBoleto
              AND v.estado = :estadoVenta
              AND (:viajeId IS NULL OR viaje.id = :viajeId)
              AND (:busId IS NULL OR bus.id = :busId)
            ORDER BY viaje.horaSalida ASC, b.numeroAsiento ASC
            """)
    List<Boleto> findManifiesto(
            @Param("empresaId") Long empresaId,
            @Param("fecha") LocalDate fecha,
            @Param("viajeId") Long viajeId,
            @Param("busId") Long busId,
            @Param("estadoBoleto") EstadoBoleto estadoBoleto,
            @Param("estadoVenta") EstadoVenta estadoVenta
    );

    @Query("""
            SELECT COUNT(b) FROM Boleto b
            JOIN b.venta v
            JOIN v.viaje viaje
            WHERE v.empresa.id = :empresaId
              AND viaje.fecha = :fecha
              AND b.estado = :estadoBoleto
              AND v.estado = :estadoVenta
            """)
    long countVendidosPorEmpresaYFecha(
            @Param("empresaId") Long empresaId,
            @Param("fecha") LocalDate fecha,
            @Param("estadoBoleto") EstadoBoleto estadoBoleto,
            @Param("estadoVenta") EstadoVenta estadoVenta
    );
}
