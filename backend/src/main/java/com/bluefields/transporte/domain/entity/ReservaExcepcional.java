package com.bluefields.transporte.domain.entity;

import com.bluefields.transporte.domain.enums.EstadoReservaExcepcional;
import jakarta.persistence.*;
import java.time.Instant;

@Entity
@Table(name = "reserva_excepcional")
public class ReservaExcepcional {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @OneToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "viaje_asiento_id", nullable = false, unique = true)
    private ViajeAsiento viajeAsiento;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "operador_id", nullable = false)
    private Usuario operador;

    @Column(name = "comprador_nombre", nullable = false, length = 150)
    private String compradorNombre;

    @Column(name = "comprador_cedula", nullable = false, length = 30)
    private String compradorCedula;

    @Column(name = "comprador_telefono", length = 20)
    private String compradorTelefono;

    @Column(nullable = false, columnDefinition = "TEXT")
    private String motivo;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private EstadoReservaExcepcional estado = EstadoReservaExcepcional.ACTIVA;

    @Column(name = "fecha_reserva", nullable = false)
    private Instant fechaReserva;

    @Column(name = "fecha_expiracion")
    private Instant fechaExpiracion;

    @PrePersist
    void prePersist() {
        if (fechaReserva == null) {
            fechaReserva = Instant.now();
        }
    }

    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }
    public ViajeAsiento getViajeAsiento() { return viajeAsiento; }
    public void setViajeAsiento(ViajeAsiento viajeAsiento) { this.viajeAsiento = viajeAsiento; }
    public Usuario getOperador() { return operador; }
    public void setOperador(Usuario operador) { this.operador = operador; }
    public String getCompradorNombre() { return compradorNombre; }
    public void setCompradorNombre(String compradorNombre) { this.compradorNombre = compradorNombre; }
    public String getCompradorCedula() { return compradorCedula; }
    public void setCompradorCedula(String compradorCedula) { this.compradorCedula = compradorCedula; }
    public String getCompradorTelefono() { return compradorTelefono; }
    public void setCompradorTelefono(String compradorTelefono) { this.compradorTelefono = compradorTelefono; }
    public String getMotivo() { return motivo; }
    public void setMotivo(String motivo) { this.motivo = motivo; }
    public EstadoReservaExcepcional getEstado() { return estado; }
    public void setEstado(EstadoReservaExcepcional estado) { this.estado = estado; }
    public Instant getFechaReserva() { return fechaReserva; }
    public Instant getFechaExpiracion() { return fechaExpiracion; }
    public void setFechaExpiracion(Instant fechaExpiracion) { this.fechaExpiracion = fechaExpiracion; }
}
