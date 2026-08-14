package com.bluefields.transporte.util;

import com.bluefields.transporte.exception.ReglaNegocioException;

import java.util.Set;

public final class CorredorUtil {

    public static final String BLUEFIELDS = "Bluefields";
    public static final String MANAGUA = "Managua";

    private static final Set<String> CIUDADES = Set.of(BLUEFIELDS, MANAGUA);

    private CorredorUtil() {}

    public static void validarCiudad(String ciudad) {
        if (ciudad == null || !CIUDADES.contains(ciudad)) {
            throw new ReglaNegocioException("Ciudad no valida: " + ciudad + ". Use Bluefields o Managua.");
        }
    }

    public static void validarPar(String origen, String destino) {
        validarCiudad(origen);
        validarCiudad(destino);
        if (origen.equals(destino)) {
            throw new ReglaNegocioException("El origen y el destino deben ser diferentes");
        }
    }

    public static String destinoOpuesto(String origen) {
        validarCiudad(origen);
        return BLUEFIELDS.equals(origen) ? MANAGUA : BLUEFIELDS;
    }
}
