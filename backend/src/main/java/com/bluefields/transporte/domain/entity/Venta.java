package com.bluefields.transporte.domain.entity;

import com.bluefields.transporte.domain.enums.EstadoVenta;
import jakarta.persistence.*;
import java.math.BigDecimal;
import java.time.Instant;
import java.util.ArrayList;
import java.util.List;

@Entity
@Table(name = "venta")
public class Venta {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false, unique = true, length = 30)
    private String codigo;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "empresa_id", nullable = false)
    private Empresa empresa;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "viaje_id", nullable = false)
    private Viaje viaje;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "operador_id", nullable = false)
    private Usuario operador;

    @Column(name = "comprador_nombre", nullable = false, length = 150)
    private String compradorNombre;

    @Column(name = "comprador_cedula", nullable = false, length = 30)
    private String compradorCedula;

    @Column(name = "comprador_telefono", length = 20)
    private String compradorTelefono;

    @Column(name = "cantidad_boletos", nullable = false)
    private Integer cantidadBoletos;

    @Column(name = "subtotal_boletos", nullable = false, precision = 10, scale = 2)
    private BigDecimal subtotalBoletos = BigDecimal.ZERO;

    @Column(name = "subtotal_equipaje", nullable = false, precision = 10, scale = 2)
    private BigDecimal subtotalEquipaje = BigDecimal.ZERO;

    @Column(nullable = false, precision = 10, scale = 2)
    private BigDecimal total = BigDecimal.ZERO;

    @Column(name = "fecha_venta", nullable = false)
    private Instant fechaVenta;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private EstadoVenta estado = EstadoVenta.COMPLETADA;

    @OneToMany(mappedBy = "venta", cascade = CascadeType.ALL, orphanRemoval = true)
    private List<Boleto> boletos = new ArrayList<>();

    @OneToMany(mappedBy = "venta", cascade = CascadeType.ALL, orphanRemoval = true)
    private List<EquipajeExtra> equipajeExtra = new ArrayList<>();

    @PrePersist
    void prePersist() {
        if (fechaVenta == null) {
            fechaVenta = Instant.now();
        }
    }

    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }
    public String getCodigo() { return codigo; }
    public void setCodigo(String codigo) { this.codigo = codigo; }
    public Empresa getEmpresa() { return empresa; }
    public void setEmpresa(Empresa empresa) { this.empresa = empresa; }
    public Viaje getViaje() { return viaje; }
    public void setViaje(Viaje viaje) { this.viaje = viaje; }
    public Usuario getOperador() { return operador; }
    public void setOperador(Usuario operador) { this.operador = operador; }
    public String getCompradorNombre() { return compradorNombre; }
    public void setCompradorNombre(String compradorNombre) { this.compradorNombre = compradorNombre; }
    public String getCompradorCedula() { return compradorCedula; }
    public void setCompradorCedula(String compradorCedula) { this.compradorCedula = compradorCedula; }
    public String getCompradorTelefono() { return compradorTelefono; }
    public void setCompradorTelefono(String compradorTelefono) { this.compradorTelefono = compradorTelefono; }
    public Integer getCantidadBoletos() { return cantidadBoletos; }
    public void setCantidadBoletos(Integer cantidadBoletos) { this.cantidadBoletos = cantidadBoletos; }
    public BigDecimal getSubtotalBoletos() { return subtotalBoletos; }
    public void setSubtotalBoletos(BigDecimal subtotalBoletos) { this.subtotalBoletos = subtotalBoletos; }
    public BigDecimal getSubtotalEquipaje() { return subtotalEquipaje; }
    public void setSubtotalEquipaje(BigDecimal subtotalEquipaje) { this.subtotalEquipaje = subtotalEquipaje; }
    public BigDecimal getTotal() { return total; }
    public void setTotal(BigDecimal total) { this.total = total; }
    public Instant getFechaVenta() { return fechaVenta; }
    public void setFechaVenta(Instant fechaVenta) { this.fechaVenta = fechaVenta; }
    public EstadoVenta getEstado() { return estado; }
    public void setEstado(EstadoVenta estado) { this.estado = estado; }
    public List<Boleto> getBoletos() { return boletos; }
    public void setBoletos(List<Boleto> boletos) { this.boletos = boletos; }
    public List<EquipajeExtra> getEquipajeExtra() { return equipajeExtra; }
    public void setEquipajeExtra(List<EquipajeExtra> equipajeExtra) { this.equipajeExtra = equipajeExtra; }
}
