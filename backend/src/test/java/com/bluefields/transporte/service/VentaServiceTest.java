package com.bluefields.transporte.service;

import com.bluefields.transporte.domain.entity.Empresa;
import com.bluefields.transporte.domain.entity.Viaje;
import com.bluefields.transporte.domain.enums.EstadoViaje;
import com.bluefields.transporte.dto.venta.VentaDto;
import com.bluefields.transporte.exception.ReglaNegocioException;
import com.bluefields.transporte.repository.VentaRepository;
import com.bluefields.transporte.repository.ViajeAsientoRepository;
import com.bluefields.transporte.security.OperadorContext;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.math.BigDecimal;
import java.time.Clock;
import java.time.Instant;
import java.time.LocalDate;
import java.time.LocalTime;
import java.time.ZoneId;
import java.util.List;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class VentaServiceTest {

    private static final ZoneId ZONA = ZoneId.of("America/Managua");

    @Mock
    private VentaRepository ventaRepository;

    @Mock
    private ViajeAsientoRepository viajeAsientoRepository;

    @Mock
    private ViajeService viajeService;

    @Mock
    private OperadorContext operadorContext;

    private VentaService ventaService;

    @BeforeEach
    void setUp() {
        Clock clock = Clock.fixed(Instant.parse("2026-06-25T12:00:00Z"), ZONA);
        ventaService = new VentaService(
                ventaRepository,
                viajeAsientoRepository,
                viajeService,
                operadorContext,
                clock
        );
    }

    @Test
    void vender_viajeAntiguo_rechazaVenta() {
        Viaje viaje = viajeConFecha(LocalDate.of(2026, 6, 20));
        when(viajeService.buscarEntidad(1L)).thenReturn(viaje);

        VentaDto.VentaRequest request = requestMinimo(1L);

        ReglaNegocioException ex = assertThrows(
                ReglaNegocioException.class,
                () -> ventaService.vender(request)
        );
        assertTrue(ex.getMessage().contains("dia del viaje o el dia anterior"));
    }

    @Test
    void vender_viajeMuyFuturo_rechazaVenta() {
        Viaje viaje = viajeConFecha(LocalDate.of(2026, 6, 27));
        when(viajeService.buscarEntidad(1L)).thenReturn(viaje);

        VentaDto.VentaRequest request = requestMinimo(1L);

        ReglaNegocioException ex = assertThrows(
                ReglaNegocioException.class,
                () -> ventaService.vender(request)
        );
        assertTrue(ex.getMessage().contains("mas de un dia de anticipacion"));
    }

    @Test
    void vender_viajeCancelado_rechazaVenta() {
        Viaje viaje = viajeConFecha(LocalDate.of(2026, 6, 25));
        viaje.setEstado(EstadoViaje.CANCELADO);
        when(viajeService.buscarEntidad(1L)).thenReturn(viaje);

        VentaDto.VentaRequest request = requestMinimo(1L);

        ReglaNegocioException ex = assertThrows(
                ReglaNegocioException.class,
                () -> ventaService.vender(request)
        );
        assertTrue(ex.getMessage().contains("cancelado"));
    }

    private static VentaDto.VentaRequest requestMinimo(Long viajeId) {
        return new VentaDto.VentaRequest(
                viajeId,
                null,
                "Juan Pérez",
                "001-250606-0001A",
                null,
                List.of(100L),
                null,
                null
        );
    }

    private static Viaje viajeConFecha(LocalDate fecha) {
        Empresa empresa = new Empresa();
        empresa.setId(1L);
        empresa.setNombre("Wendelyn");
        empresa.setTarifaEquipajeExtra(BigDecimal.valueOf(50));
        empresa.setActivo(true);

        Viaje viaje = new Viaje();
        viaje.setId(1L);
        viaje.setEmpresa(empresa);
        viaje.setOrigen("Bluefields");
        viaje.setDestino("Managua");
        viaje.setFecha(fecha);
        viaje.setHoraSalida(LocalTime.of(6, 0));
        viaje.setTarifa(BigDecimal.valueOf(450));
        viaje.setEstado(EstadoViaje.PROGRAMADO);
        return viaje;
    }
}
