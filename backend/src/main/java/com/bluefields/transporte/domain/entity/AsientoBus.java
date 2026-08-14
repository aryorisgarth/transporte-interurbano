package com.bluefields.transporte.domain.entity;

import com.bluefields.transporte.domain.enums.PosicionAsiento;
import jakarta.persistence.*;

@Entity
@Table(name = "asiento_bus")
public class AsientoBus {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "bus_id", nullable = false)
    private Bus bus;

    @Column(nullable = false)
    private Integer numero;

    @Column(nullable = false)
    private Integer fila;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private PosicionAsiento posicion;

    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }
    public Bus getBus() { return bus; }
    public void setBus(Bus bus) { this.bus = bus; }
    public Integer getNumero() { return numero; }
    public void setNumero(Integer numero) { this.numero = numero; }
    public Integer getFila() { return fila; }
    public void setFila(Integer fila) { this.fila = fila; }
    public PosicionAsiento getPosicion() { return posicion; }
    public void setPosicion(PosicionAsiento posicion) { this.posicion = posicion; }
}
