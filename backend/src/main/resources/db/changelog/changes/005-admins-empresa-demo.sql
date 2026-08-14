-- V5: Administradores por empresa (tenant aislado)
INSERT INTO usuario (empresa_id, nombre_usuario, password_hash, nombre_completo, activo) VALUES
    (1, 'admin.wendelyn', '$2a$10$EixZaYVK1fsbw1ZfbX3OXePaWxn96p36.eiQcKS/0u/3.FZ5Qm3Oe', 'Admin Wendelyn', TRUE),
    (2, 'admin.martinez', '$2a$10$EixZaYVK1fsbw1ZfbX3OXePaWxn96p36.eiQcKS/0u/3.FZ5Qm3Oe', 'Admin Martinez', TRUE);

INSERT INTO usuario_rol (usuario_id, rol_id)
SELECT u.id, r.id FROM usuario u, rol r
WHERE u.nombre_usuario = 'admin.wendelyn' AND r.nombre = 'ADMIN_EMPRESA';

INSERT INTO usuario_rol (usuario_id, rol_id)
SELECT u.id, r.id FROM usuario u, rol r
WHERE u.nombre_usuario = 'admin.martinez' AND r.nombre = 'ADMIN_EMPRESA';
