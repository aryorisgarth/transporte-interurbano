package com.bluefields.transporte.exception;

public class ExternalApiException extends RuntimeException {

    private final String servicio;

    public ExternalApiException(String servicio, String message) {
        super(message);
        this.servicio = servicio;
    }

    public ExternalApiException(String servicio, String message, Throwable cause) {
        super(message, cause);
        this.servicio = servicio;
    }

    public String getServicio() {
        return servicio;
    }
}
