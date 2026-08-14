package com.bluefields.transporte.util;

import com.bluefields.transporte.domain.entity.AsientoBus;
import com.bluefields.transporte.domain.entity.Bus;
import com.bluefields.transporte.domain.enums.PosicionAsiento;
import java.util.ArrayList;
import java.util.List;

public final class AsientoLayoutUtil {

    /** Capacidad estándar buses interurbanos demo (Bluefields–Managua). */
    public static final int CAPACIDAD_ESTANDAR = 50;

    /** Filas lógicas: 22 pares + 1 ventana suelta + 1 fila trasera de 5. */
    public static final int FILAS_ESTANDAR = 24;

    private static final int FILA_TRASERA = 24;
    private static final int FILA_VENTANA_FINAL = 23;
    private static final int PRIMER_ASIENTO_TRASERA = 46;

    private AsientoLayoutUtil() {}

    public static int calcularFilas(int capacidad) {
        if (capacidad == CAPACIDAD_ESTANDAR) {
            return FILAS_ESTANDAR;
        }
        if (capacidad <= 0 || capacidad % 2 != 0) {
            throw new IllegalArgumentException("La capacidad debe ser un número par mayor a 0");
        }
        return capacidad / 2;
    }

    /**
     * Layout 50 asientos con patrón zigzag (lado del busero alterna):
     * - Fila impar:  izquierda VENTANA, derecha PASILLO  (ej. 1V · 2P)
     * - Fila par:    izquierda PASILLO, derecha VENTANA  (ej. 3P · 4V)
     * - Fila 23: asiento 45 ventana
     * - Fila 24: respaldo 46–50
     */
    public static List<AsientoBus> generarAsientos(Bus bus, int capacidad) {
        if (capacidad == CAPACIDAD_ESTANDAR) {
            return generarLayout50(bus);
        }
        return generarLayoutSimple(bus, capacidad);
    }

    private static List<AsientoBus> generarLayout50(Bus bus) {
        List<AsientoBus> asientos = new ArrayList<>();

        for (int fila = 1; fila <= 22; fila++) {
            asientos.add(crearAsiento(bus, fila * 2 - 1, fila, posicionIzquierda(fila)));
            asientos.add(crearAsiento(bus, fila * 2, fila, posicionDerecha(fila)));
        }

        asientos.add(crearAsiento(bus, 45, FILA_VENTANA_FINAL, PosicionAsiento.VENTANA));

        PosicionAsiento[] traseras = {
                PosicionAsiento.TRASERA_1,
                PosicionAsiento.TRASERA_2,
                PosicionAsiento.TRASERA_3,
                PosicionAsiento.TRASERA_4,
                PosicionAsiento.TRASERA_5
        };
        for (int i = 0; i < traseras.length; i++) {
            asientos.add(crearAsiento(bus, PRIMER_ASIENTO_TRASERA + i, FILA_TRASERA, traseras[i]));
        }

        return asientos;
    }

    /** Layout genérico zigzag sin fila trasera. */
    private static List<AsientoBus> generarLayoutSimple(Bus bus, int capacidad) {
        List<AsientoBus> asientos = new ArrayList<>();
        int filas = capacidad / 2;
        for (int fila = 1; fila <= filas; fila++) {
            asientos.add(crearAsiento(bus, fila * 2 - 1, fila, posicionIzquierda(fila)));
            asientos.add(crearAsiento(bus, fila * 2, fila, posicionDerecha(fila)));
        }
        return asientos;
    }

    public static PosicionAsiento posicionIzquierda(int fila) {
        return fila % 2 == 1 ? PosicionAsiento.VENTANA : PosicionAsiento.PASILLO;
    }

    public static PosicionAsiento posicionDerecha(int fila) {
        return fila % 2 == 1 ? PosicionAsiento.PASILLO : PosicionAsiento.VENTANA;
    }

    public static PosicionAsiento posicionEsperada(int fila, int numero) {
        if (numero == fila * 2 - 1) {
            return posicionIzquierda(fila);
        }
        if (numero == fila * 2) {
            return posicionDerecha(fila);
        }
        throw new IllegalArgumentException(
                "El número " + numero + " no corresponde a la fila " + fila + " en layout zigzag"
        );
    }

    public static void validarCoherenciaNumeroPosicion(Integer numero, Integer fila, PosicionAsiento posicion) {
        if (numero == null || fila == null || posicion == null) {
            throw new IllegalArgumentException("Número, fila y posición son obligatorios");
        }
        if (posicion.esTrasera()) {
            return;
        }
        PosicionAsiento esperada = posicionEsperada(fila, numero);
        if (posicion != esperada) {
            throw new IllegalArgumentException(
                    "Asiento " + numero + " en fila " + fila + " debe ser " + esperada + ", no " + posicion
            );
        }
    }

    private static AsientoBus crearAsiento(Bus bus, int numero, int fila, PosicionAsiento posicion) {
        AsientoBus asiento = new AsientoBus();
        asiento.setBus(bus);
        asiento.setNumero(numero);
        asiento.setFila(fila);
        asiento.setPosicion(posicion);
        return asiento;
    }
}
