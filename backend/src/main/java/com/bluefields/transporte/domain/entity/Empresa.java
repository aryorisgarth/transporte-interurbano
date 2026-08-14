package com.bluefields.transporte.domain.entity;

import jakarta.persistence.*;
import java.time.Instant;

@Entity
@Table(name = "empresa")
public class Empresa {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false, length = 150)
    private String nombre;

    @Column(length = 20)
    private String telefono;

    @Column(length = 150)
    private String correo;

    @Column(nullable = false)
    private Boolean activo = true;

    @Column(name = "tarifa_equipaje_extra", nullable = false, precision = 10, scale = 2)
    private java.math.BigDecimal tarifaEquipajeExtra = new java.math.BigDecimal("100.00");

    @Column(name = "logo_url", length = 500)
    private String logoUrl;

    @Column(name = "created_at", nullable = false, updatable = false)
    private Instant createdAt;

    @Column(name = "updated_at", nullable = false)
    private Instant updatedAt;

    @PrePersist
    void prePersist() {
        Instant now = Instant.now();
        createdAt = now;
        updatedAt = now;
    }

    @PreUpdate
    void preUpdate() {
        updatedAt = Instant.now();
    }

    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }
    public String getNombre() { return nombre; }
    public void setNombre(String nombre) { this.nombre = nombre; }
    public String getTelefono() { return telefono; }
    public void setTelefono(String telefono) { this.telefono = telefono; }
    public String getCorreo() { return correo; }
    public void setCorreo(String correo) { this.correo = correo; }
    public Boolean getActivo() { return activo; }
    public void setActivo(Boolean activo) { this.activo = activo; }
    public java.math.BigDecimal getTarifaEquipajeExtra() { return tarifaEquipajeExtra; }
    public void setTarifaEquipajeExtra(java.math.BigDecimal tarifaEquipajeExtra) { this.tarifaEquipajeExtra = tarifaEquipajeExtra; }
    public String getLogoUrl() { return logoUrl; }
    public void setLogoUrl(String logoUrl) { this.logoUrl = logoUrl; }
    public Instant getCreatedAt() { return createdAt; }
    public Instant getUpdatedAt() { return updatedAt; }
}
