package com.bluefields.transporte.domain.enums;

public enum PosicionAsiento {
    VENTANA,
    PASILLO,
    TRASERA_1,
    TRASERA_2,
    TRASERA_3,
    TRASERA_4,
    TRASERA_5;

    public boolean esTrasera() {
        return name().startsWith("TRASERA");
    }
}
