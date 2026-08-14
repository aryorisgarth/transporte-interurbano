package com.bluefields.transporte.mapper;

import com.bluefields.transporte.domain.entity.*;
import com.bluefields.transporte.domain.enums.EstadoAsientoViaje;
import com.bluefields.transporte.dto.bus.BusResponse;
import com.bluefields.transporte.dto.consulta.ConsultaPublicaDto;
import com.bluefields.transporte.dto.empresa.EmpresaResponse;
import com.bluefields.transporte.dto.venta.VentaDto;
import com.bluefields.transporte.dto.viaje.ViajeResponse;
import com.bluefields.transporte.repository.ViajeAsientoRepository;

import java.util.Comparator;
import java.util.List;

public final class EntityMapper {

    private EntityMapper() {}

    public static EmpresaResponse toEmpresaResponse(Empresa empresa) {
        return new EmpresaResponse(
                empresa.getId(),
                empresa.getNombre(),
                empresa.getTelefono(),
                empresa.getCorreo(),
                empresa.getTarifaEquipajeExtra(),
                empresa.getLogoUrl(),
                empresa.getActivo(),
                empresa.getCreatedAt(),
                empresa.getUpdatedAt()
        );
    }

    public static BusResponse toBusResponse(Bus bus) {
        List<BusResponse.AsientoResponse> asientos = bus.getAsientos().stream()
                .sorted(Comparator.comparing(AsientoBus::getNumero))
                .map(a -> new BusResponse.AsientoResponse(
                        a.getId(), a.getNumero(), a.getFila(), a.getPosicion()))
                .toList();

        return new BusResponse(
                bus.getId(),
                bus.getEmpresa().getId(),
                bus.getNumeroInterno(),
                bus.getPlaca(),
                bus.getCapacidad(),
                bus.getFilas(),
                bus.getActivo(),
                bus.getFotoUrl(),
                bus.getSede(),
                asientos
        );
    }

    public static ViajeResponse toViajeResponse(Viaje viaje, long asientosDisponibles) {
        return new ViajeResponse(
                viaje.getId(),
                viaje.getEmpresa().getId(),
                viaje.getEmpresa().getNombre(),
                viaje.getBus().getId(),
                viaje.getBus().getNumeroInterno(),
                viaje.getOrigen(),
                viaje.getDestino(),
                viaje.getFecha(),
                viaje.getHoraSalida(),
                viaje.getTarifa(),
                viaje.getTarifaEquipajeExtra(),
                viaje.getEstado(),
                asientosDisponibles,
                viaje.getCreatedAt()
        );
    }

    public static ConsultaPublicaDto.ViajeDisponibleResponse toConsultaViaje(Viaje viaje, long disponibles) {
        return new ConsultaPublicaDto.ViajeDisponibleResponse(
                viaje.getId(),
                viaje.getEmpresa().getNombre(),
                viaje.getEmpresa().getLogoUrl(),
                viaje.getHoraSalida().toString(),
                disponibles,
                viaje.getBus().getCapacidad(),
                viaje.getTarifa()
        );
    }

    public static ConsultaPublicaDto.AsientoDisponibleResponse toAsientoConsulta(ViajeAsiento va) {
        AsientoBus ab = va.getAsientoBus();
        return new ConsultaPublicaDto.AsientoDisponibleResponse(
                va.getId(),
                ab.getNumero(),
                ab.getFila(),
                ab.getPosicion(),
                va.getEstado()
        );
    }

    public static VentaDto.VentaResponse toVentaResponse(Venta venta) {
        List<Integer> numeros = venta.getBoletos().stream()
                .map(Boleto::getNumeroAsiento)
                .sorted()
                .toList();

        List<VentaDto.BoletoResponse> boletos = venta.getBoletos().stream()
                .map(b -> new VentaDto.BoletoResponse(
                        b.getId(),
                        b.getNumeroAsiento(),
                        b.getPasajeroNombre() != null ? b.getPasajeroNombre() : venta.getCompradorNombre(),
                        b.getPasajeroCedula() != null ? b.getPasajeroCedula() : venta.getCompradorCedula(),
                        Boolean.TRUE.equals(b.getEsMenor()),
                        b.getEdad(),
                        b.getMonto(),
                        b.getIncluyeEquipaje(),
                        b.getEstado().name()))
                .toList();

        return new VentaDto.VentaResponse(
                venta.getId(),
                venta.getCodigo(),
                venta.getViaje().getId(),
                venta.getCompradorNombre(),
                venta.getCompradorCedula(),
                venta.getCompradorTelefono(),
                venta.getCantidadBoletos(),
                numeros,
                venta.getSubtotalBoletos(),
                venta.getSubtotalEquipaje(),
                venta.getTotal(),
                boletos
        );
    }

    public static long contarDisponibles(ViajeAsientoRepository repo, Long viajeId) {
        return repo.countByViajeIdAndEstado(viajeId, EstadoAsientoViaje.DISPONIBLE);
    }
}
