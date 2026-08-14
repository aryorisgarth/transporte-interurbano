-- V14: Terminal base del operador (cajero vende solo en su sede)
ALTER TABLE usuario ADD COLUMN sede VARCHAR(100) NULL AFTER nombre_completo;

UPDATE usuario SET sede = 'Bluefields'
WHERE nombre_usuario IN ('cajero.wendelyn', 'cajero.martinez');

-- Cajero demo terminal Managua (Wendelyn)
INSERT INTO usuario (empresa_id, nombre_usuario, password_hash, nombre_completo, sede, activo)
SELECT 1, 'cajero.wendelyn.mga', '$2a$10$EixZaYVK1fsbw1ZfbX3OXePaWxn96p36.eiQcKS/0u/3.FZ5Qm3Oe', 'Cajero Wendelyn Managua', 'Managua', TRUE
WHERE NOT EXISTS (SELECT 1 FROM usuario WHERE nombre_usuario = 'cajero.wendelyn.mga');

INSERT INTO usuario_rol (usuario_id, rol_id)
SELECT u.id, r.id FROM usuario u, rol r
WHERE u.nombre_usuario = 'cajero.wendelyn.mga' AND r.nombre = 'CAJERO'
  AND NOT EXISTS (
    SELECT 1 FROM usuario_rol ur WHERE ur.usuario_id = u.id AND ur.rol_id = r.id
  );
