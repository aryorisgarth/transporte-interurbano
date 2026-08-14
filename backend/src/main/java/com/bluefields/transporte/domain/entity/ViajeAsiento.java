package com.bluefields.transporte.domain.entity;

import com.bluefields.transporte.domain.enums.EstadoAsientoViaje;
import jakarta.persistence.*;
import java.time.Instant;

@Entity
@Table(name = "viaje_asiento")
public class ViajeAsiento {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "viaje_id", nullable = false)
    private Viaje viaje;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "asiento_bus_id", nullable = false)
    private AsientoBus asientoBus;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private EstadoAsientoViaje estado = EstadoAsientoViaje.DISPONIBLE;

    @Version
    @Column(nullable = false)
    private Integer version = 0;

    @Column(name = "updated_at", nullable = false)
    private Instant updatedAt;

    @PrePersist
    @PreUpdate
    void touchUpdatedAt() {
        updatedAt = Instant.now();
    }

    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }
    public Viaje getViaje() { return viaje; }
    public void setViaje(Viaje viaje) { this.viaje = viaje; }
    public AsientoBus getAsientoBus() { return asientoBus; }
    public void setAsientoBus(AsientoBus asientoBus) { this.asientoBus = asientoBus; }
    public EstadoAsientoViaje getEstado() { return estado; }
    public void setEstado(EstadoAsientoViaje estado) { this.estado = estado; }
    public Integer getVersion() { return version; }
    public Instant getUpdatedAt() { return updatedAt; }
}
