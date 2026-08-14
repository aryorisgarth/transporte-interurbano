package com.bluefields.transporte.dto.venta;

import jakarta.validation.Valid;
import jakarta.validation.constraints.*;
import java.math.BigDecimal;
import java.util.List;

public class VentaDto {

    public record EquipajeExtraRequest(
            @NotNull(message = "La cantidad de equipaje extra es obligatoria")
            @Min(value = 1, message = "Debe solicitar al menos 1 equipaje extra")
            Integer cantidad,
            @DecimalMin(value = "0.0", message = "El monto unitario no puede ser negativo")
            BigDecimal montoUnitario,
            @Size(max = 255) String descripcion
    ) {}

    public record PasajeroBoletoRequest(
            @NotNull(message = "El asiento es obligatorio") Long viajeAsientoId,
            @NotBlank(message = "El nombre del pasajero es obligatorio")
            @Size(max = 150) String pasajeroNombre,
            @NotBlank(message = "La cedula del pasajero es obligatoria")
            @Size(min = 5, max = 30, message = "Cedula invalida") String pasajeroCedula,
            Boolean esMenor,
            @Min(0) @Max(17) Integer edad
    ) {}

    public record VentaRequest(
            @NotNull(message = "El viaje es obligatorio") Long viajeId,
            Long operadorId,
            @NotBlank(message = "El nombre del comprador es obligatorio")
            @Size(max = 150) String compradorNombre,
            @NotBlank(message = "La cedula del comprador es obligatoria")
            @Size(min = 5, max = 30, message = "Cedula invalida") String compradorCedula,
            @Size(max = 20) String compradorTelefono,
            @NotEmpty(message = "Debe seleccionar al menos un asiento")
            @Size(max = 50, message = "Maximo 50 asientos por venta") List<Long> viajeAsientoIds,
            @Valid List<PasajeroBoletoRequest> pasajeros,
            @Valid EquipajeExtraRequest equipajeExtra
    ) {}

    public record BoletoResponse(
            Long id,
            Integer numeroAsiento,
            String pasajeroNombre,
            String pasajeroCedula,
            Boolean esMenor,
            Integer edad,
            BigDecimal monto,
            Boolean incluyeEquipaje,
            String estado
    ) {}

    public record VentaResponse(
            Long id,
            String codigo,
            Long viajeId,
            String compradorNombre,
            String compradorCedula,
            String compradorTelefono,
            Integer cantidadBoletos,
            List<Integer> numerosAsiento,
            BigDecimal subtotalBoletos,
            BigDecimal subtotalEquipaje,
            BigDecimal total,
            List<BoletoResponse> boletos
    ) {}
}
