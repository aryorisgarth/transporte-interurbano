package com.bluefields.transporte.domain.entity;

import com.bluefields.transporte.domain.enums.EstadoBoleto;
import jakarta.persistence.*;
import java.math.BigDecimal;

@Entity
@Table(name = "boleto")
public class Boleto {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "venta_id", nullable = false)
    private Venta venta;

    @OneToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "viaje_asiento_id", nullable = false, unique = true)
    private ViajeAsiento viajeAsiento;

    @Column(name = "numero_asiento", nullable = false)
    private Integer numeroAsiento;

    @Column(nullable = false, precision = 10, scale = 2)
    private BigDecimal monto;

    @Column(name = "incluye_equipaje", nullable = false)
    private Boolean incluyeEquipaje = true;

    @Column(name = "pasajero_nombre", length = 150)
    private String pasajeroNombre;

    @Column(name = "pasajero_cedula", length = 30)
    private String pasajeroCedula;

    @Column(name = "es_menor", nullable = false)
    private Boolean esMenor = false;

    @Column(name = "edad")
    private Integer edad;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private EstadoBoleto estado = EstadoBoleto.ACTIVO;

    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }
    public Venta getVenta() { return venta; }
    public void setVenta(Venta venta) { this.venta = venta; }
    public ViajeAsiento getViajeAsiento() { return viajeAsiento; }
    public void setViajeAsiento(ViajeAsiento viajeAsiento) { this.viajeAsiento = viajeAsiento; }
    public Integer getNumeroAsiento() { return numeroAsiento; }
    public void setNumeroAsiento(Integer numeroAsiento) { this.numeroAsiento = numeroAsiento; }
    public BigDecimal getMonto() { return monto; }
    public void setMonto(BigDecimal monto) { this.monto = monto; }
    public Boolean getIncluyeEquipaje() { return incluyeEquipaje; }
    public void setIncluyeEquipaje(Boolean incluyeEquipaje) { this.incluyeEquipaje = incluyeEquipaje; }
    public String getPasajeroNombre() { return pasajeroNombre; }
    public void setPasajeroNombre(String pasajeroNombre) { this.pasajeroNombre = pasajeroNombre; }
    public String getPasajeroCedula() { return pasajeroCedula; }
    public void setPasajeroCedula(String pasajeroCedula) { this.pasajeroCedula = pasajeroCedula; }
    public Boolean getEsMenor() { return esMenor; }
    public void setEsMenor(Boolean esMenor) { this.esMenor = esMenor; }
    public Integer getEdad() { return edad; }
    public void setEdad(Integer edad) { this.edad = edad; }
    public EstadoBoleto getEstado() { return estado; }
    public void setEstado(EstadoBoleto estado) { this.estado = estado; }
}
