package com.bluefields.transporte.repository;

import com.bluefields.transporte.domain.entity.Venta;
import com.bluefields.transporte.domain.enums.EstadoVenta;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.time.LocalDate;
import java.util.List;
import java.util.Optional;

public interface VentaRepository extends JpaRepository<Venta, Long> {

    @Query("""
            SELECT v FROM Venta v
            JOIN FETCH v.viaje viaje
            JOIN FETCH v.empresa e
            JOIN FETCH v.operador op
            LEFT JOIN FETCH v.boletos b
            LEFT JOIN FETCH v.equipajeExtra eq
            WHERE v.id = :id
            """)
    Optional<Venta> findWithDetailsById(@Param("id") Long id);

    List<Venta> findByViajeIdOrderByFechaVentaDesc(Long viajeId);

    @Query("""
            SELECT COALESCE(SUM(v.total), 0),
                   COALESCE(SUM(v.subtotalBoletos), 0),
                   COALESCE(SUM(v.subtotalEquipaje), 0),
                   COUNT(v),
                   COALESCE(SUM(v.cantidadBoletos), 0)
            FROM Venta v
            JOIN v.viaje viaje
            WHERE v.empresa.id = :empresaId
              AND viaje.fecha BETWEEN :desde AND :hasta
              AND v.estado = :estado
            """)
    Object[] sumarIngresosPorPeriodo(
            @Param("empresaId") Long empresaId,
            @Param("desde") LocalDate desde,
            @Param("hasta") LocalDate hasta,
            @Param("estado") EstadoVenta estado
    );

    @Query("""
            SELECT viaje.fecha,
                   COALESCE(SUM(v.total), 0),
                   COALESCE(SUM(v.subtotalBoletos), 0),
                   COALESCE(SUM(v.subtotalEquipaje), 0),
                   COUNT(v),
                   COALESCE(SUM(v.cantidadBoletos), 0)
            FROM Venta v
            JOIN v.viaje viaje
            WHERE v.empresa.id = :empresaId
              AND viaje.fecha BETWEEN :desde AND :hasta
              AND v.estado = :estado
            GROUP BY viaje.fecha
            ORDER BY viaje.fecha
            """)
    List<Object[]> ingresosAgrupadosPorDia(
            @Param("empresaId") Long empresaId,
            @Param("desde") LocalDate desde,
            @Param("hasta") LocalDate hasta,
            @Param("estado") EstadoVenta estado
    );

    @Query("""
            SELECT viaje.id,
                   viaje.fecha,
                   viaje.horaSalida,
                   viaje.origen,
                   viaje.destino,
                   viaje.bus.numeroInterno,
                   COALESCE(SUM(v.total), 0),
                   COALESCE(SUM(v.subtotalBoletos), 0),
                   COALESCE(SUM(v.subtotalEquipaje), 0),
                   COUNT(v),
                   COALESCE(SUM(v.cantidadBoletos), 0)
            FROM Venta v
            JOIN v.viaje viaje
            WHERE v.empresa.id = :empresaId
              AND viaje.fecha BETWEEN :desde AND :hasta
              AND v.estado = :estado
            GROUP BY viaje.id, viaje.fecha, viaje.horaSalida, viaje.origen, viaje.destino, viaje.bus.numeroInterno
            ORDER BY viaje.fecha, viaje.horaSalida
            """)
    List<Object[]> ingresosAgrupadosPorViaje(
            @Param("empresaId") Long empresaId,
            @Param("desde") LocalDate desde,
            @Param("hasta") LocalDate hasta,
            @Param("estado") EstadoVenta estado
    );

    @Query("""
            SELECT op.id,
                   op.nombreCompleto,
                   op.sede,
                   COALESCE(SUM(v.total), 0),
                   COALESCE(SUM(v.subtotalBoletos), 0),
                   COALESCE(SUM(v.subtotalEquipaje), 0),
                   COUNT(v),
                   COALESCE(SUM(v.cantidadBoletos), 0)
            FROM Venta v
            JOIN v.viaje viaje
            JOIN v.operador op
            WHERE v.empresa.id = :empresaId
              AND viaje.fecha BETWEEN :desde AND :hasta
              AND v.estado = :estado
            GROUP BY op.id, op.nombreCompleto, op.sede
            ORDER BY SUM(v.total) DESC
            """)
    List<Object[]> ingresosAgrupadosPorCajero(
            @Param("empresaId") Long empresaId,
            @Param("desde") LocalDate desde,
            @Param("hasta") LocalDate hasta,
            @Param("estado") EstadoVenta estado
    );

    @Query("""
            SELECT viaje.origen,
                   COALESCE(SUM(v.total), 0),
                   COUNT(v),
                   COALESCE(SUM(v.cantidadBoletos), 0)
            FROM Venta v
            JOIN v.viaje viaje
            WHERE v.empresa.id = :empresaId
              AND viaje.fecha BETWEEN :desde AND :hasta
              AND v.estado = :estado
            GROUP BY viaje.origen
            ORDER BY viaje.origen
            """)
    List<Object[]> ingresosAgrupadosPorTerminal(
            @Param("empresaId") Long empresaId,
            @Param("desde") LocalDate desde,
            @Param("hasta") LocalDate hasta,
            @Param("estado") EstadoVenta estado
    );

    @Query("""
            SELECT v.id,
                   v.codigo,
                   v.fechaVenta,
                   v.total,
                   v.subtotalBoletos,
                   v.subtotalEquipaje,
                   v.cantidadBoletos,
                   op.nombreCompleto,
                   op.sede,
                   viaje.origen,
                   viaje.destino,
                   viaje.fecha,
                   viaje.horaSalida
            FROM Venta v
            JOIN v.viaje viaje
            JOIN v.operador op
            WHERE v.empresa.id = :empresaId
              AND viaje.fecha BETWEEN :desde AND :hasta
              AND v.estado = :estado
            ORDER BY v.fechaVenta DESC
            """)
    List<Object[]> listarVentasIngresos(
            @Param("empresaId") Long empresaId,
            @Param("desde") LocalDate desde,
            @Param("hasta") LocalDate hasta,
            @Param("estado") EstadoVenta estado
    );
}
