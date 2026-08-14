-- V6: Datos por pasajero en boleto + permiso reserva excepcional demo
ALTER TABLE boleto
    ADD COLUMN pasajero_nombre VARCHAR(150) NULL,
    ADD COLUMN pasajero_cedula VARCHAR(30) NULL,
    ADD COLUMN es_menor BOOLEAN NOT NULL DEFAULT FALSE,
    ADD COLUMN edad INT NULL;

UPDATE boleto b
    INNER JOIN venta v ON v.id = b.venta_id
SET b.pasajero_nombre = v.comprador_nombre,
    b.pasajero_cedula = v.comprador_cedula;

INSERT INTO usuario_rol (usuario_id, rol_id)
SELECT u.id, r.id FROM usuario u, rol r
WHERE u.nombre_usuario = 'admin.wendelyn' AND r.nombre = 'RESERVA_EXCEPCIONAL'
  AND NOT EXISTS (
    SELECT 1 FROM usuario_rol ur
    JOIN usuario u2 ON u2.id = ur.usuario_id
    JOIN rol r2 ON r2.id = ur.rol_id
    WHERE u2.nombre_usuario = 'admin.wendelyn' AND r2.nombre = 'RESERVA_EXCEPCIONAL'
);
