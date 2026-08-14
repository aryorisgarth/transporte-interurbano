package com.bluefields.transporte.util;

import com.bluefields.transporte.domain.entity.AsientoBus;
import com.bluefields.transporte.domain.entity.Bus;
import com.bluefields.transporte.domain.enums.PosicionAsiento;
import org.junit.jupiter.api.Test;

import java.util.List;
import java.util.Set;
import java.util.stream.Collectors;

import static org.junit.jupiter.api.Assertions.*;

class AsientoLayoutUtilTest {

    @Test
    void calcularFilas_capacidadEstandar_retorna24() {
        assertEquals(24, AsientoLayoutUtil.calcularFilas(50));
    }

    @Test
    void calcularFilas_capacidadPar_generica() {
        assertEquals(20, AsientoLayoutUtil.calcularFilas(40));
    }

    @Test
    void calcularFilas_capacidadInvalida_lanzaExcepcion() {
        assertThrows(IllegalArgumentException.class, () -> AsientoLayoutUtil.calcularFilas(0));
        assertThrows(IllegalArgumentException.class, () -> AsientoLayoutUtil.calcularFilas(51));
    }

    @Test
    void generarAsientos_layout50_tiene50AsientosUnicos() {
        Bus bus = new Bus();
        bus.setPlaca("TEST-001");

        List<AsientoBus> asientos = AsientoLayoutUtil.generarAsientos(bus, 50);

        assertEquals(50, asientos.size());
        Set<Integer> numeros = asientos.stream().map(AsientoBus::getNumero).collect(Collectors.toSet());
        assertEquals(50, numeros.size());
        assertTrue(numeros.contains(45));
        assertTrue(numeros.contains(50));
    }

    @Test
    void posicionEsperada_zigzag_filaImpar() {
        assertEquals(PosicionAsiento.VENTANA, AsientoLayoutUtil.posicionEsperada(1, 1));
        assertEquals(PosicionAsiento.PASILLO, AsientoLayoutUtil.posicionEsperada(1, 2));
    }

    @Test
    void posicionEsperada_zigzag_filaPar() {
        assertEquals(PosicionAsiento.PASILLO, AsientoLayoutUtil.posicionEsperada(2, 3));
        assertEquals(PosicionAsiento.VENTANA, AsientoLayoutUtil.posicionEsperada(2, 4));
    }

    @Test
    void validarCoherencia_numeroPosicionIncorrecto_lanzaExcepcion() {
        assertThrows(
                IllegalArgumentException.class,
                () -> AsientoLayoutUtil.validarCoherenciaNumeroPosicion(1, 1, PosicionAsiento.PASILLO)
        );
    }

    @Test
    void validarCoherencia_asientoTrasero_noValidaZigzag() {
        assertDoesNotThrow(
                () -> AsientoLayoutUtil.validarCoherenciaNumeroPosicion(
                        46, 24, PosicionAsiento.TRASERA_1
                )
        );
    }
}
