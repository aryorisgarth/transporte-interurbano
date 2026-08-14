-- =============================================================================
-- Sistema de Gestion de Transporte Interurbano Bluefields - Managua
-- V1: Esquema consolidado (fuente de verdad)
-- MySQL 8.0+
-- =============================================================================

-- -----------------------------------------------------------------------------
-- 1. EMPRESAS Y CONFIGURACION
-- -----------------------------------------------------------------------------

CREATE TABLE empresa (
    id                      BIGINT AUTO_INCREMENT PRIMARY KEY,
    nombre                  VARCHAR(150) NOT NULL,
    telefono                VARCHAR(20),
    correo                  VARCHAR(150),
    tarifa_equipaje_extra   DECIMAL(10, 2) NOT NULL DEFAULT 100.00,
    activo                  BOOLEAN NOT NULL DEFAULT TRUE,
    created_at              TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at              TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT chk_empresa_tarifa_equipaje CHECK (tarifa_equipaje_extra >= 0)
);

CREATE INDEX idx_empresa_activo ON empresa (activo, nombre);

-- -----------------------------------------------------------------------------
-- 2. SEGURIDAD (usuarios locales + Keycloak futuro)
-- -----------------------------------------------------------------------------

CREATE TABLE rol (
    id              BIGINT AUTO_INCREMENT PRIMARY KEY,
    nombre          VARCHAR(50) NOT NULL,
    descripcion     VARCHAR(255),
    CONSTRAINT uq_rol_nombre UNIQUE (nombre)
);

CREATE TABLE usuario (
    id              BIGINT AUTO_INCREMENT PRIMARY KEY,
    empresa_id      BIGINT NULL,
    keycloak_id     VARCHAR(36) NULL,
    nombre_usuario  VARCHAR(50) NOT NULL,
    password_hash   VARCHAR(255) NULL,
    nombre_completo VARCHAR(150) NOT NULL,
    activo          BOOLEAN NOT NULL DEFAULT TRUE,
    created_at      TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at      TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT uq_usuario_nombre UNIQUE (nombre_usuario),
    CONSTRAINT uq_usuario_keycloak UNIQUE (keycloak_id),
    CONSTRAINT fk_usuario_empresa FOREIGN KEY (empresa_id) REFERENCES empresa(id),
    CONSTRAINT chk_usuario_auth CHECK (password_hash IS NOT NULL OR keycloak_id IS NOT NULL)
);

CREATE INDEX idx_usuario_empresa ON usuario (empresa_id, activo);

CREATE TABLE usuario_rol (
    usuario_id      BIGINT NOT NULL,
    rol_id          BIGINT NOT NULL,
    PRIMARY KEY (usuario_id, rol_id),
    CONSTRAINT fk_usuario_rol_usuario FOREIGN KEY (usuario_id) REFERENCES usuario(id) ON DELETE CASCADE,
    CONSTRAINT fk_usuario_rol_rol FOREIGN KEY (rol_id) REFERENCES rol(id) ON DELETE CASCADE
);

-- -----------------------------------------------------------------------------
-- 3. FLOTA: BUS Y LAYOUT DE ASIENTOS
-- -----------------------------------------------------------------------------

CREATE TABLE bus (
    id              BIGINT AUTO_INCREMENT PRIMARY KEY,
    empresa_id      BIGINT NOT NULL,
    numero_interno  VARCHAR(20) NOT NULL,
    placa           VARCHAR(20) NOT NULL,
    capacidad       INT NOT NULL,
    filas           INT NOT NULL,
    activo          BOOLEAN NOT NULL DEFAULT TRUE,
    created_at      TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at      TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT fk_bus_empresa FOREIGN KEY (empresa_id) REFERENCES empresa(id),
    CONSTRAINT uq_bus_empresa_numero UNIQUE (empresa_id, numero_interno),
    CONSTRAINT uq_bus_placa UNIQUE (placa),
    CONSTRAINT chk_bus_capacidad CHECK (capacidad > 0 AND capacidad MOD 2 = 0),
    CONSTRAINT chk_bus_filas CHECK (filas > 0 AND filas * 2 = capacidad)
);

CREATE INDEX idx_bus_empresa_activo ON bus (empresa_id, activo);

CREATE TABLE asiento_bus (
    id              BIGINT AUTO_INCREMENT PRIMARY KEY,
    bus_id          BIGINT NOT NULL,
    numero          INT NOT NULL,
    fila            INT NOT NULL,
    posicion        ENUM('VENTANA', 'PASILLO') NOT NULL,
    CONSTRAINT fk_asiento_bus FOREIGN KEY (bus_id) REFERENCES bus(id) ON DELETE CASCADE,
    CONSTRAINT uq_asiento_bus_numero UNIQUE (bus_id, numero),
    CONSTRAINT uq_asiento_bus_fila_pos UNIQUE (bus_id, fila, posicion),
    CONSTRAINT chk_asiento_fila CHECK (fila > 0),
    CONSTRAINT chk_asiento_numero CHECK (numero > 0)
);

-- -----------------------------------------------------------------------------
-- 4. VIAJES Y OCUPACION POR SALIDA
-- -----------------------------------------------------------------------------

CREATE TABLE viaje (
    id                      BIGINT AUTO_INCREMENT PRIMARY KEY,
    empresa_id              BIGINT NOT NULL,
    bus_id                  BIGINT NOT NULL,
    origen                  VARCHAR(100) NOT NULL DEFAULT 'Bluefields',
    destino                 VARCHAR(100) NOT NULL DEFAULT 'Managua',
    fecha                   DATE NOT NULL,
    hora_salida             TIME NOT NULL,
    tarifa                  DECIMAL(10, 2) NOT NULL,
    tarifa_equipaje_extra   DECIMAL(10, 2) NULL,
    estado                  ENUM('PROGRAMADO', 'EN_CURSO', 'COMPLETADO', 'CANCELADO') NOT NULL DEFAULT 'PROGRAMADO',
    observaciones           VARCHAR(500),
    created_at              TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at              TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT fk_viaje_empresa FOREIGN KEY (empresa_id) REFERENCES empresa(id),
    CONSTRAINT fk_viaje_bus FOREIGN KEY (bus_id) REFERENCES bus(id),
    CONSTRAINT chk_viaje_tarifa CHECK (tarifa >= 0),
    CONSTRAINT chk_viaje_tarifa_equipaje CHECK (tarifa_equipaje_extra IS NULL OR tarifa_equipaje_extra >= 0)
);

CREATE INDEX idx_viaje_busqueda_publica ON viaje (origen, destino, fecha, estado);
CREATE INDEX idx_viaje_empresa_fecha ON viaje (empresa_id, fecha, hora_salida);

CREATE TABLE viaje_asiento (
    id              BIGINT AUTO_INCREMENT PRIMARY KEY,
    viaje_id        BIGINT NOT NULL,
    asiento_bus_id  BIGINT NOT NULL,
    estado          ENUM('DISPONIBLE', 'VENDIDO', 'CANCELADO', 'RESERVADO_EXCEPCIONAL') NOT NULL DEFAULT 'DISPONIBLE',
    version         INT NOT NULL DEFAULT 0,
    updated_at      TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT fk_viaje_asiento_viaje FOREIGN KEY (viaje_id) REFERENCES viaje(id) ON DELETE CASCADE,
    CONSTRAINT fk_viaje_asiento_asiento FOREIGN KEY (asiento_bus_id) REFERENCES asiento_bus(id),
    CONSTRAINT uq_viaje_asiento UNIQUE (viaje_id, asiento_bus_id)
);

CREATE INDEX idx_viaje_asiento_disponibles ON viaje_asiento (viaje_id, estado);

-- -----------------------------------------------------------------------------
-- 5. VENTAS Y BOLETOS (compra multiple a un nombre)
-- -----------------------------------------------------------------------------

CREATE TABLE venta (
    id                  BIGINT AUTO_INCREMENT PRIMARY KEY,
    codigo              VARCHAR(30) NOT NULL,
    empresa_id          BIGINT NOT NULL,
    viaje_id            BIGINT NOT NULL,
    operador_id         BIGINT NOT NULL,
    comprador_nombre    VARCHAR(150) NOT NULL,
    comprador_cedula    VARCHAR(30) NOT NULL,
    comprador_telefono  VARCHAR(20),
    cantidad_boletos    INT NOT NULL,
    subtotal_boletos    DECIMAL(10, 2) NOT NULL DEFAULT 0,
    subtotal_equipaje   DECIMAL(10, 2) NOT NULL DEFAULT 0,
    total               DECIMAL(10, 2) NOT NULL DEFAULT 0,
    fecha_venta         TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    estado              ENUM('COMPLETADA', 'CANCELADA', 'PARCIALMENTE_CANCELADA') NOT NULL DEFAULT 'COMPLETADA',
    CONSTRAINT uq_venta_codigo UNIQUE (codigo),
    CONSTRAINT fk_venta_empresa FOREIGN KEY (empresa_id) REFERENCES empresa(id),
    CONSTRAINT fk_venta_viaje FOREIGN KEY (viaje_id) REFERENCES viaje(id),
    CONSTRAINT fk_venta_operador FOREIGN KEY (operador_id) REFERENCES usuario(id),
    CONSTRAINT chk_venta_cantidad CHECK (cantidad_boletos > 0),
    CONSTRAINT chk_venta_totales CHECK (total = subtotal_boletos + subtotal_equipaje)
);

CREATE INDEX idx_venta_viaje ON venta (viaje_id);
CREATE INDEX idx_venta_empresa_fecha ON venta (empresa_id, fecha_venta);
CREATE INDEX idx_venta_cedula ON venta (comprador_cedula);

CREATE TABLE boleto (
    id                  BIGINT AUTO_INCREMENT PRIMARY KEY,
    venta_id            BIGINT NOT NULL,
    viaje_asiento_id    BIGINT NOT NULL,
    numero_asiento      INT NOT NULL,
    monto               DECIMAL(10, 2) NOT NULL,
    incluye_equipaje    BOOLEAN NOT NULL DEFAULT TRUE,
    estado              ENUM('ACTIVO', 'CANCELADO') NOT NULL DEFAULT 'ACTIVO',
    CONSTRAINT fk_boleto_venta FOREIGN KEY (venta_id) REFERENCES venta(id) ON DELETE CASCADE,
    CONSTRAINT fk_boleto_viaje_asiento FOREIGN KEY (viaje_asiento_id) REFERENCES viaje_asiento(id),
    CONSTRAINT uq_boleto_asiento UNIQUE (viaje_asiento_id),
    CONSTRAINT chk_boleto_monto CHECK (monto >= 0)
);

CREATE INDEX idx_boleto_venta ON boleto (venta_id, estado);

CREATE TABLE equipaje_extra (
    id              BIGINT AUTO_INCREMENT PRIMARY KEY,
    venta_id        BIGINT NOT NULL,
    cantidad        INT NOT NULL DEFAULT 1,
    monto_unitario  DECIMAL(10, 2) NOT NULL,
    monto_total     DECIMAL(10, 2) NOT NULL,
    descripcion     VARCHAR(255) NOT NULL DEFAULT 'Equipaje adicional',
    CONSTRAINT fk_equipaje_venta FOREIGN KEY (venta_id) REFERENCES venta(id) ON DELETE CASCADE,
    CONSTRAINT chk_equipaje_cantidad CHECK (cantidad > 0),
    CONSTRAINT chk_equipaje_montos CHECK (monto_total = monto_unitario * cantidad AND monto_unitario >= 0)
);

-- -----------------------------------------------------------------------------
-- 6. RESERVA EXCEPCIONAL (solo permiso especial; no flujo normal)
-- -----------------------------------------------------------------------------

CREATE TABLE reserva_excepcional (
    id                  BIGINT AUTO_INCREMENT PRIMARY KEY,
    viaje_asiento_id    BIGINT NOT NULL,
    operador_id         BIGINT NOT NULL,
    comprador_nombre    VARCHAR(150) NOT NULL,
    comprador_cedula    VARCHAR(30) NOT NULL,
    comprador_telefono  VARCHAR(20),
    motivo              TEXT NOT NULL,
    estado              ENUM('ACTIVA', 'CONVERTIDA', 'CANCELADA', 'EXPIRADA') NOT NULL DEFAULT 'ACTIVA',
    fecha_reserva       TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    fecha_expiracion    TIMESTAMP NULL,
    CONSTRAINT uq_reserva_asiento UNIQUE (viaje_asiento_id),
    CONSTRAINT fk_reserva_viaje_asiento FOREIGN KEY (viaje_asiento_id) REFERENCES viaje_asiento(id),
    CONSTRAINT fk_reserva_operador FOREIGN KEY (operador_id) REFERENCES usuario(id)
);

CREATE INDEX idx_reserva_estado ON reserva_excepcional (estado, fecha_expiracion);

-- -----------------------------------------------------------------------------
-- 7. VISTA: consulta publica de cupos (solo lectura)
-- -----------------------------------------------------------------------------

CREATE OR REPLACE VIEW v_cupos_viaje AS
SELECT
    v.id                    AS viaje_id,
    e.id                    AS empresa_id,
    e.nombre                AS empresa_nombre,
    v.origen,
    v.destino,
    v.fecha,
    v.hora_salida,
    v.tarifa,
    v.estado                AS estado_viaje,
    b.capacidad             AS capacidad_total,
    SUM(CASE WHEN va.estado = 'DISPONIBLE' THEN 1 ELSE 0 END) AS asientos_disponibles,
    SUM(CASE WHEN va.estado = 'VENDIDO' THEN 1 ELSE 0 END) AS asientos_vendidos,
    SUM(CASE WHEN va.estado = 'RESERVADO_EXCEPCIONAL' THEN 1 ELSE 0 END) AS asientos_reservados
FROM viaje v
JOIN empresa e ON e.id = v.empresa_id
JOIN bus b ON b.id = v.bus_id
JOIN viaje_asiento va ON va.viaje_id = v.id
WHERE e.activo = TRUE
GROUP BY v.id, e.id, e.nombre, v.origen, v.destino, v.fecha, v.hora_salida, v.tarifa, v.estado, b.capacidad;
