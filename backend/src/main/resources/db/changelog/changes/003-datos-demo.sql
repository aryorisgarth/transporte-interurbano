-- V3: Datos demo para desarrollo y pruebas (Sesion 3)
-- Password del cajero demo: "password" (solo desarrollo; Keycloak en semana 3)

INSERT INTO empresa (nombre, telefono, correo, tarifa_equipaje_extra, activo) VALUES
    ('Wendelyn', '2572-3456', 'info@wendelyn.com', 150.00, TRUE),
    ('Martinez', '2572-7890', 'info@martinez.com', 120.00, TRUE);

INSERT INTO usuario (empresa_id, nombre_usuario, password_hash, nombre_completo, activo) VALUES
    (1, 'cajero.wendelyn', '$2a$10$EixZaYVK1fsbw1ZfbX3OXePaWxn96p36.eiQcKS/0u/3.FZ5Qm3Oe', 'Cajero Wendelyn', TRUE),
    (2, 'cajero.martinez', '$2a$10$EixZaYVK1fsbw1ZfbX3OXePaWxn96p36.eiQcKS/0u/3.FZ5Qm3Oe', 'Cajero Martinez', TRUE),
    (NULL, 'admin.global', '$2a$10$EixZaYVK1fsbw1ZfbX3OXePaWxn96p36.eiQcKS/0u/3.FZ5Qm3Oe', 'Administrador General', TRUE);

INSERT INTO usuario_rol (usuario_id, rol_id)
SELECT u.id, r.id FROM usuario u, rol r
WHERE u.nombre_usuario = 'cajero.wendelyn' AND r.nombre = 'CAJERO';

INSERT INTO usuario_rol (usuario_id, rol_id)
SELECT u.id, r.id FROM usuario u, rol r
WHERE u.nombre_usuario = 'cajero.martinez' AND r.nombre = 'CAJERO';

INSERT INTO usuario_rol (usuario_id, rol_id)
SELECT u.id, r.id FROM usuario u, rol r
WHERE u.nombre_usuario = 'admin.global' AND r.nombre = 'ADMIN_GENERAL';
