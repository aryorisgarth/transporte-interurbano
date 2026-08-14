-- V16: Población demo — 4 cooperativas nuevas (total 6 con Wendelyn y Martínez)
-- Cada una: admin, 2 cajeros (Bluefields + Managua), 2 buses 50 asientos, viajes, ventas y reservas.
-- Password de todos los operadores: "password" (hash BCrypt demo)
-- Idempotente: puede ejecutarse varias veces sin duplicar.

SET @pwd := '$2a$10$EixZaYVK1fsbw1ZfbX3OXePaWxn96p36.eiQcKS/0u/3.FZ5Qm3Oe';
SET @bus_tpl := (SELECT id FROM bus WHERE numero_interno = 'W-01' LIMIT 1);

-- Completar Martínez: cajero terminal Managua
INSERT INTO usuario (empresa_id, nombre_usuario, password_hash, nombre_completo, email_login, sede, activo)
SELECT e.id, 'cajero.martinez.mga', @pwd, 'Cajero Martínez Managua', 'cajero.martinez.mga@transporte.local', 'Managua', TRUE
FROM empresa e
WHERE e.nombre LIKE '%Martínez%' OR e.nombre LIKE '%Martinez%'
  AND NOT EXISTS (SELECT 1 FROM usuario WHERE nombre_usuario = 'cajero.martinez.mga');

INSERT INTO usuario_rol (usuario_id, rol_id)
SELECT u.id, r.id FROM usuario u, rol r
WHERE u.nombre_usuario = 'cajero.martinez.mga' AND r.nombre = 'CAJERO'
  AND NOT EXISTS (SELECT 1 FROM usuario_rol ur WHERE ur.usuario_id = u.id AND ur.rol_id = r.id);

-- ---------------------------------------------------------------------------
-- Cooperativa 3: Costa Caribe Express
-- ---------------------------------------------------------------------------
INSERT INTO empresa (nombre, telefono, correo, tarifa_equipaje_extra, activo)
SELECT 'Costa Caribe Express', '2572-4101', 'info@costacaribe.com', 150.00, TRUE
WHERE NOT EXISTS (SELECT 1 FROM empresa WHERE nombre = 'Costa Caribe Express');

INSERT INTO usuario (empresa_id, nombre_usuario, password_hash, nombre_completo, email_login, sede, activo)
SELECT e.id, 'admin.costacaribe', @pwd, 'Admin Costa Caribe', 'admin@costacaribe.com', NULL, TRUE
FROM empresa e WHERE e.nombre = 'Costa Caribe Express'
  AND NOT EXISTS (SELECT 1 FROM usuario WHERE nombre_usuario = 'admin.costacaribe');

INSERT INTO usuario (empresa_id, nombre_usuario, password_hash, nombre_completo, email_login, sede, activo)
SELECT e.id, 'cajero.costacaribe.bfs', @pwd, 'Cajero CC Bluefields', 'cajero.bfs@costacaribe.com', 'Bluefields', TRUE
FROM empresa e WHERE e.nombre = 'Costa Caribe Express'
  AND NOT EXISTS (SELECT 1 FROM usuario WHERE nombre_usuario = 'cajero.costacaribe.bfs');

INSERT INTO usuario (empresa_id, nombre_usuario, password_hash, nombre_completo, email_login, sede, activo)
SELECT e.id, 'cajero.costacaribe.mga', @pwd, 'Cajero CC Managua', 'cajero.mga@costacaribe.com', 'Managua', TRUE
FROM empresa e WHERE e.nombre = 'Costa Caribe Express'
  AND NOT EXISTS (SELECT 1 FROM usuario WHERE nombre_usuario = 'cajero.costacaribe.mga');

INSERT INTO usuario_rol (usuario_id, rol_id)
SELECT u.id, r.id FROM usuario u JOIN rol r ON r.nombre = 'ADMIN_EMPRESA'
WHERE u.nombre_usuario = 'admin.costacaribe'
  AND NOT EXISTS (SELECT 1 FROM usuario_rol ur WHERE ur.usuario_id = u.id AND ur.rol_id = r.id);

INSERT INTO usuario_rol (usuario_id, rol_id)
SELECT u.id, r.id FROM usuario u JOIN rol r ON r.nombre = 'CAJERO'
WHERE u.nombre_usuario IN ('cajero.costacaribe.bfs', 'cajero.costacaribe.mga')
  AND NOT EXISTS (SELECT 1 FROM usuario_rol ur WHERE ur.usuario_id = u.id AND ur.rol_id = r.id);

INSERT INTO bus (empresa_id, numero_interno, placa, capacidad, filas, sede, activo, foto_url)
SELECT e.id, 'CC-BFS-01', 'NI-3101', 50, 24, 'Bluefields', TRUE, '/images/bus-yutong-interurbano.png'
FROM empresa e WHERE e.nombre = 'Costa Caribe Express'
  AND NOT EXISTS (SELECT 1 FROM bus WHERE numero_interno = 'CC-BFS-01');

INSERT INTO bus (empresa_id, numero_interno, placa, capacidad, filas, sede, activo, foto_url)
SELECT e.id, 'CC-MGA-01', 'NI-3102', 50, 24, 'Managua', TRUE, '/images/bus-yutong-interurbano.png'
FROM empresa e WHERE e.nombre = 'Costa Caribe Express'
  AND NOT EXISTS (SELECT 1 FROM bus WHERE numero_interno = 'CC-MGA-01');

INSERT INTO asiento_bus (bus_id, numero, fila, posicion)
SELECT nb.id, ab.numero, ab.fila, ab.posicion
FROM bus nb
INNER JOIN asiento_bus ab ON ab.bus_id = @bus_tpl
WHERE nb.numero_interno IN ('CC-BFS-01', 'CC-MGA-01')
  AND NOT EXISTS (SELECT 1 FROM asiento_bus x WHERE x.bus_id = nb.id);

INSERT INTO viaje (empresa_id, bus_id, origen, destino, fecha, hora_salida, tarifa, tarifa_equipaje_extra, estado)
SELECT e.id, b.id, 'Bluefields', 'Managua', CURDATE(), '06:30:00', 350.00, 150.00, 'PROGRAMADO'
FROM empresa e INNER JOIN bus b ON b.empresa_id = e.id AND b.numero_interno = 'CC-BFS-01'
WHERE e.nombre = 'Costa Caribe Express'
  AND NOT EXISTS (
    SELECT 1 FROM viaje v WHERE v.empresa_id = e.id AND v.origen = 'Bluefields'
      AND v.fecha = CURDATE() AND v.hora_salida = '06:30:00'
  );

INSERT INTO viaje (empresa_id, bus_id, origen, destino, fecha, hora_salida, tarifa, tarifa_equipaje_extra, estado)
SELECT e.id, b.id, 'Managua', 'Bluefields', CURDATE(), '15:30:00', 350.00, 150.00, 'PROGRAMADO'
FROM empresa e INNER JOIN bus b ON b.empresa_id = e.id AND b.numero_interno = 'CC-MGA-01'
WHERE e.nombre = 'Costa Caribe Express'
  AND NOT EXISTS (
    SELECT 1 FROM viaje v WHERE v.empresa_id = e.id AND v.origen = 'Managua'
      AND v.fecha = CURDATE() AND v.hora_salida = '15:30:00'
  );

INSERT INTO viaje (empresa_id, bus_id, origen, destino, fecha, hora_salida, tarifa, tarifa_equipaje_extra, estado)
SELECT e.id, b.id, 'Bluefields', 'Managua', DATE_ADD(CURDATE(), INTERVAL 1 DAY), '08:00:00', 350.00, 150.00, 'PROGRAMADO'
FROM empresa e INNER JOIN bus b ON b.empresa_id = e.id AND b.numero_interno = 'CC-BFS-01'
WHERE e.nombre = 'Costa Caribe Express'
  AND NOT EXISTS (
    SELECT 1 FROM viaje v WHERE v.empresa_id = e.id AND v.origen = 'Bluefields'
      AND v.fecha = DATE_ADD(CURDATE(), INTERVAL 1 DAY) AND v.hora_salida = '08:00:00'
  );

INSERT INTO viaje_asiento (viaje_id, asiento_bus_id, estado)
SELECT v.id, ab.id, 'DISPONIBLE'
FROM viaje v
INNER JOIN bus b ON b.id = v.bus_id
INNER JOIN asiento_bus ab ON ab.bus_id = b.id
INNER JOIN empresa e ON e.id = v.empresa_id AND e.nombre = 'Costa Caribe Express'
WHERE NOT EXISTS (SELECT 1 FROM viaje_asiento va WHERE va.viaje_id = v.id AND va.asiento_bus_id = ab.id);

INSERT INTO venta (codigo, empresa_id, viaje_id, operador_id, comprador_nombre, comprador_cedula, cantidad_boletos, subtotal_boletos, subtotal_equipaje, total, estado)
SELECT 'SEED-CC-001', e.id, v.id, u.id, 'Ana Morales', '001-120101-0001A', 2, 700.00, 50.00, 750.00, 'COMPLETADA'
FROM empresa e
INNER JOIN viaje v ON v.empresa_id = e.id AND v.origen = 'Bluefields' AND v.fecha = CURDATE() AND v.hora_salida = '06:30:00'
INNER JOIN usuario u ON u.nombre_usuario = 'cajero.costacaribe.bfs'
WHERE e.nombre = 'Costa Caribe Express'
  AND NOT EXISTS (SELECT 1 FROM venta WHERE codigo = 'SEED-CC-001');

INSERT INTO boleto (venta_id, viaje_asiento_id, numero_asiento, monto, pasajero_nombre, pasajero_cedula, estado)
SELECT ve.id, va.id, ab.numero, 350.00, 'Ana Morales', '001-120101-0001A', 'ACTIVO'
FROM venta ve
INNER JOIN viaje v ON v.id = ve.viaje_id
INNER JOIN viaje_asiento va ON va.viaje_id = v.id
INNER JOIN asiento_bus ab ON ab.id = va.asiento_bus_id AND ab.numero IN (1, 2)
WHERE ve.codigo = 'SEED-CC-001'
  AND NOT EXISTS (SELECT 1 FROM boleto b WHERE b.viaje_asiento_id = va.id);

UPDATE viaje_asiento va
INNER JOIN boleto b ON b.viaje_asiento_id = va.id
INNER JOIN venta ve ON ve.id = b.venta_id
SET va.estado = 'VENDIDO'
WHERE ve.codigo = 'SEED-CC-001';

INSERT INTO reserva_excepcional (viaje_asiento_id, operador_id, comprador_nombre, comprador_cedula, motivo, estado, fecha_expiracion)
SELECT va.id, u.id, 'Reserva Demo CC', '001-999999-0000R', 'Reserva excepcional demo — cliente confirma en 2h', 'ACTIVA', DATE_ADD(NOW(), INTERVAL 4 HOUR)
FROM venta ve
INNER JOIN viaje v ON v.id = ve.viaje_id
INNER JOIN viaje_asiento va ON va.viaje_id = v.id
INNER JOIN asiento_bus ab ON ab.id = va.asiento_bus_id AND ab.numero = 3
INNER JOIN usuario u ON u.nombre_usuario = 'admin.costacaribe'
WHERE ve.codigo = 'SEED-CC-001'
  AND NOT EXISTS (SELECT 1 FROM reserva_excepcional re WHERE re.viaje_asiento_id = va.id);

UPDATE viaje_asiento va
INNER JOIN reserva_excepcional re ON re.viaje_asiento_id = va.id
INNER JOIN venta ve ON ve.codigo = 'SEED-CC-001'
SET va.estado = 'RESERVADO_EXCEPCIONAL'
WHERE re.comprador_cedula = '001-999999-0000R';

-- ---------------------------------------------------------------------------
-- Cooperativa 4: Rama Dorada Líneas
-- ---------------------------------------------------------------------------
INSERT INTO empresa (nombre, telefono, correo, tarifa_equipaje_extra, activo)
SELECT 'Rama Dorada Líneas', '2572-4202', 'info@ramadorada.com', 130.00, TRUE
WHERE NOT EXISTS (SELECT 1 FROM empresa WHERE nombre = 'Rama Dorada Líneas');

INSERT INTO usuario (empresa_id, nombre_usuario, password_hash, nombre_completo, email_login, sede, activo)
SELECT e.id, 'admin.ramadorada', @pwd, 'Admin Rama Dorada', 'admin@ramadorada.com', NULL, TRUE
FROM empresa e WHERE e.nombre = 'Rama Dorada Líneas' AND NOT EXISTS (SELECT 1 FROM usuario WHERE nombre_usuario = 'admin.ramadorada');

INSERT INTO usuario (empresa_id, nombre_usuario, password_hash, nombre_completo, email_login, sede, activo)
SELECT e.id, 'cajero.ramadorada.bfs', @pwd, 'Cajero RD Bluefields', 'cajero.bfs@ramadorada.com', 'Bluefields', TRUE
FROM empresa e WHERE e.nombre = 'Rama Dorada Líneas' AND NOT EXISTS (SELECT 1 FROM usuario WHERE nombre_usuario = 'cajero.ramadorada.bfs');

INSERT INTO usuario (empresa_id, nombre_usuario, password_hash, nombre_completo, email_login, sede, activo)
SELECT e.id, 'cajero.ramadorada.mga', @pwd, 'Cajero RD Managua', 'cajero.mga@ramadorada.com', 'Managua', TRUE
FROM empresa e WHERE e.nombre = 'Rama Dorada Líneas' AND NOT EXISTS (SELECT 1 FROM usuario WHERE nombre_usuario = 'cajero.ramadorada.mga');

INSERT INTO usuario_rol (usuario_id, rol_id)
SELECT u.id, r.id FROM usuario u JOIN rol r ON r.nombre = 'ADMIN_EMPRESA'
WHERE u.nombre_usuario = 'admin.ramadorada'
  AND NOT EXISTS (SELECT 1 FROM usuario_rol ur WHERE ur.usuario_id = u.id AND ur.rol_id = r.id);

INSERT INTO usuario_rol (usuario_id, rol_id)
SELECT u.id, r.id FROM usuario u JOIN rol r ON r.nombre = 'CAJERO'
WHERE u.nombre_usuario IN ('cajero.ramadorada.bfs', 'cajero.ramadorada.mga')
  AND NOT EXISTS (SELECT 1 FROM usuario_rol ur WHERE ur.usuario_id = u.id AND ur.rol_id = r.id);

INSERT INTO bus (empresa_id, numero_interno, placa, capacidad, filas, sede, activo, foto_url)
SELECT e.id, 'RD-BFS-01', 'NI-3201', 50, 24, 'Bluefields', TRUE, '/images/bus-yutong-interurbano.png'
FROM empresa e WHERE e.nombre = 'Rama Dorada Líneas' AND NOT EXISTS (SELECT 1 FROM bus WHERE numero_interno = 'RD-BFS-01');

INSERT INTO bus (empresa_id, numero_interno, placa, capacidad, filas, sede, activo, foto_url)
SELECT e.id, 'RD-MGA-01', 'NI-3202', 50, 24, 'Managua', TRUE, '/images/bus-yutong-interurbano.png'
FROM empresa e WHERE e.nombre = 'Rama Dorada Líneas' AND NOT EXISTS (SELECT 1 FROM bus WHERE numero_interno = 'RD-MGA-01');

INSERT INTO asiento_bus (bus_id, numero, fila, posicion)
SELECT nb.id, ab.numero, ab.fila, ab.posicion
FROM bus nb INNER JOIN asiento_bus ab ON ab.bus_id = @bus_tpl
WHERE nb.numero_interno IN ('RD-BFS-01', 'RD-MGA-01')
  AND NOT EXISTS (SELECT 1 FROM asiento_bus x WHERE x.bus_id = nb.id);

INSERT INTO viaje (empresa_id, bus_id, origen, destino, fecha, hora_salida, tarifa, tarifa_equipaje_extra, estado)
SELECT e.id, b.id, 'Bluefields', 'Managua', CURDATE(), '07:00:00', 360.00, 130.00, 'PROGRAMADO'
FROM empresa e INNER JOIN bus b ON b.empresa_id = e.id AND b.numero_interno = 'RD-BFS-01'
WHERE e.nombre = 'Rama Dorada Líneas'
  AND NOT EXISTS (SELECT 1 FROM viaje v WHERE v.empresa_id = e.id AND v.fecha = CURDATE() AND v.hora_salida = '07:00:00' AND v.origen = 'Bluefields');

INSERT INTO viaje (empresa_id, bus_id, origen, destino, fecha, hora_salida, tarifa, tarifa_equipaje_extra, estado)
SELECT e.id, b.id, 'Managua', 'Bluefields', CURDATE(), '16:00:00', 360.00, 130.00, 'PROGRAMADO'
FROM empresa e INNER JOIN bus b ON b.empresa_id = e.id AND b.numero_interno = 'RD-MGA-01'
WHERE e.nombre = 'Rama Dorada Líneas'
  AND NOT EXISTS (SELECT 1 FROM viaje v WHERE v.empresa_id = e.id AND v.fecha = CURDATE() AND v.hora_salida = '16:00:00' AND v.origen = 'Managua');

INSERT INTO viaje_asiento (viaje_id, asiento_bus_id, estado)
SELECT v.id, ab.id, 'DISPONIBLE'
FROM viaje v INNER JOIN bus b ON b.id = v.bus_id INNER JOIN asiento_bus ab ON ab.bus_id = b.id
INNER JOIN empresa e ON e.id = v.empresa_id AND e.nombre = 'Rama Dorada Líneas'
WHERE NOT EXISTS (SELECT 1 FROM viaje_asiento va WHERE va.viaje_id = v.id AND va.asiento_bus_id = ab.id);

INSERT INTO venta (codigo, empresa_id, viaje_id, operador_id, comprador_nombre, comprador_cedula, cantidad_boletos, subtotal_boletos, subtotal_equipaje, total, estado)
SELECT 'SEED-RD-001', e.id, v.id, u.id, 'Carlos Vega', '001-130202-0002B', 2, 720.00, 0, 720.00, 'COMPLETADA'
FROM empresa e
INNER JOIN viaje v ON v.empresa_id = e.id AND v.origen = 'Bluefields' AND v.fecha = CURDATE() AND v.hora_salida = '07:00:00'
INNER JOIN usuario u ON u.nombre_usuario = 'cajero.ramadorada.bfs'
WHERE e.nombre = 'Rama Dorada Líneas' AND NOT EXISTS (SELECT 1 FROM venta WHERE codigo = 'SEED-RD-001');

INSERT INTO boleto (venta_id, viaje_asiento_id, numero_asiento, monto, pasajero_nombre, pasajero_cedula, estado)
SELECT ve.id, va.id, ab.numero, 360.00, 'Carlos Vega', '001-130202-0002B', 'ACTIVO'
FROM venta ve INNER JOIN viaje v ON v.id = ve.viaje_id
INNER JOIN viaje_asiento va ON va.viaje_id = v.id
INNER JOIN asiento_bus ab ON ab.id = va.asiento_bus_id AND ab.numero IN (5, 6)
WHERE ve.codigo = 'SEED-RD-001' AND NOT EXISTS (SELECT 1 FROM boleto b WHERE b.viaje_asiento_id = va.id);

UPDATE viaje_asiento va INNER JOIN boleto b ON b.viaje_asiento_id = va.id INNER JOIN venta ve ON ve.id = b.venta_id
SET va.estado = 'VENDIDO' WHERE ve.codigo = 'SEED-RD-001';

-- ---------------------------------------------------------------------------
-- Cooperativa 5: Atlántico Sur Transporte
-- ---------------------------------------------------------------------------
INSERT INTO empresa (nombre, telefono, correo, tarifa_equipaje_extra, activo)
SELECT 'Atlántico Sur Transporte', '2572-4303', 'info@atlanticosur.com', 140.00, TRUE
WHERE NOT EXISTS (SELECT 1 FROM empresa WHERE nombre = 'Atlántico Sur Transporte');

INSERT INTO usuario (empresa_id, nombre_usuario, password_hash, nombre_completo, email_login, sede, activo)
SELECT e.id, u.nombre_usuario, @pwd, u.nombre_completo, u.email_login, u.sede, TRUE
FROM empresa e
CROSS JOIN (
    SELECT 'admin.atlanticosur' AS nombre_usuario, 'Admin Atlántico Sur' AS nombre_completo, 'admin@atlanticosur.com' AS email_login, NULL AS sede
    UNION ALL SELECT 'cajero.atlanticosur.bfs', 'Cajero AS Bluefields', 'cajero.bfs@atlanticosur.com', 'Bluefields'
    UNION ALL SELECT 'cajero.atlanticosur.mga', 'Cajero AS Managua', 'cajero.mga@atlanticosur.com', 'Managua'
) u
WHERE e.nombre = 'Atlántico Sur Transporte'
  AND NOT EXISTS (SELECT 1 FROM usuario x WHERE x.nombre_usuario = u.nombre_usuario);

INSERT INTO usuario_rol (usuario_id, rol_id)
SELECT u.id, r.id FROM usuario u JOIN rol r ON r.nombre = IF(u.nombre_usuario LIKE 'admin.%', 'ADMIN_EMPRESA', 'CAJERO')
WHERE u.nombre_usuario IN ('admin.atlanticosur', 'cajero.atlanticosur.bfs', 'cajero.atlanticosur.mga')
  AND NOT EXISTS (SELECT 1 FROM usuario_rol ur WHERE ur.usuario_id = u.id AND ur.rol_id = r.id);

INSERT INTO bus (empresa_id, numero_interno, placa, capacidad, filas, sede, activo, foto_url)
SELECT e.id, x.numero_interno, x.placa, 50, 24, x.sede, TRUE, '/images/bus-yutong-interurbano.png'
FROM empresa e
CROSS JOIN (
    SELECT 'AS-BFS-01' AS numero_interno, 'NI-3301' AS placa, 'Bluefields' AS sede
    UNION ALL SELECT 'AS-MGA-01', 'NI-3302', 'Managua'
) x
WHERE e.nombre = 'Atlántico Sur Transporte'
  AND NOT EXISTS (SELECT 1 FROM bus b WHERE b.numero_interno = x.numero_interno);

INSERT INTO asiento_bus (bus_id, numero, fila, posicion)
SELECT nb.id, ab.numero, ab.fila, ab.posicion
FROM bus nb INNER JOIN asiento_bus ab ON ab.bus_id = @bus_tpl
WHERE nb.numero_interno IN ('AS-BFS-01', 'AS-MGA-01')
  AND NOT EXISTS (SELECT 1 FROM asiento_bus x WHERE x.bus_id = nb.id);

INSERT INTO viaje (empresa_id, bus_id, origen, destino, fecha, hora_salida, tarifa, tarifa_equipaje_extra, estado)
SELECT e.id, b.id, 'Bluefields', 'Managua', CURDATE(), '05:45:00', 355.00, 140.00, 'PROGRAMADO'
FROM empresa e INNER JOIN bus b ON b.empresa_id = e.id AND b.numero_interno = 'AS-BFS-01'
WHERE e.nombre = 'Atlántico Sur Transporte'
  AND NOT EXISTS (SELECT 1 FROM viaje v WHERE v.empresa_id = e.id AND v.fecha = CURDATE() AND v.hora_salida = '05:45:00');

INSERT INTO viaje (empresa_id, bus_id, origen, destino, fecha, hora_salida, tarifa, tarifa_equipaje_extra, estado)
SELECT e.id, b.id, 'Managua', 'Bluefields', CURDATE(), '14:30:00', 355.00, 140.00, 'PROGRAMADO'
FROM empresa e INNER JOIN bus b ON b.empresa_id = e.id AND b.numero_interno = 'AS-MGA-01'
WHERE e.nombre = 'Atlántico Sur Transporte'
  AND NOT EXISTS (SELECT 1 FROM viaje v WHERE v.empresa_id = e.id AND v.fecha = CURDATE() AND v.hora_salida = '14:30:00' AND v.origen = 'Managua');

INSERT INTO viaje_asiento (viaje_id, asiento_bus_id, estado)
SELECT v.id, ab.id, 'DISPONIBLE'
FROM viaje v INNER JOIN bus b ON b.id = v.bus_id INNER JOIN asiento_bus ab ON ab.bus_id = b.id
INNER JOIN empresa e ON e.id = v.empresa_id AND e.nombre = 'Atlántico Sur Transporte'
WHERE NOT EXISTS (SELECT 1 FROM viaje_asiento va WHERE va.viaje_id = v.id AND va.asiento_bus_id = ab.id);

INSERT INTO venta (codigo, empresa_id, viaje_id, operador_id, comprador_nombre, comprador_cedula, cantidad_boletos, subtotal_boletos, subtotal_equipaje, total, estado)
SELECT 'SEED-AS-001', e.id, v.id, u.id, 'Lucía Herrera', '001-140303-0003C', 3, 1065.00, 0, 1065.00, 'COMPLETADA'
FROM empresa e
INNER JOIN viaje v ON v.empresa_id = e.id AND v.origen = 'Bluefields' AND v.fecha = CURDATE() AND v.hora_salida = '05:45:00'
INNER JOIN usuario u ON u.nombre_usuario = 'cajero.atlanticosur.bfs'
WHERE e.nombre = 'Atlántico Sur Transporte' AND NOT EXISTS (SELECT 1 FROM venta WHERE codigo = 'SEED-AS-001');

INSERT INTO boleto (venta_id, viaje_asiento_id, numero_asiento, monto, pasajero_nombre, pasajero_cedula, estado)
SELECT ve.id, va.id, ab.numero, 355.00, CONCAT('Pasajero AS ', ab.numero), '001-140303-0003C', 'ACTIVO'
FROM venta ve INNER JOIN viaje v ON v.id = ve.viaje_id
INNER JOIN viaje_asiento va ON va.viaje_id = v.id
INNER JOIN asiento_bus ab ON ab.id = va.asiento_bus_id AND ab.numero IN (10, 11, 12)
WHERE ve.codigo = 'SEED-AS-001' AND NOT EXISTS (SELECT 1 FROM boleto b WHERE b.viaje_asiento_id = va.id);

UPDATE viaje_asiento va INNER JOIN boleto b ON b.viaje_asiento_id = va.id INNER JOIN venta ve ON ve.id = b.venta_id
SET va.estado = 'VENDIDO' WHERE ve.codigo = 'SEED-AS-001';

-- ---------------------------------------------------------------------------
-- Cooperativa 6: Corredor Centro SA
-- ---------------------------------------------------------------------------
INSERT INTO empresa (nombre, telefono, correo, tarifa_equipaje_extra, activo)
SELECT 'Corredor Centro SA', '2572-4404', 'info@corredorcentro.com', 125.00, TRUE
WHERE NOT EXISTS (SELECT 1 FROM empresa WHERE nombre = 'Corredor Centro SA');

INSERT INTO usuario (empresa_id, nombre_usuario, password_hash, nombre_completo, email_login, sede, activo)
SELECT e.id, u.nombre_usuario, @pwd, u.nombre_completo, u.email_login, u.sede, TRUE
FROM empresa e
CROSS JOIN (
    SELECT 'admin.corredorcentro' AS nombre_usuario, 'Admin Corredor Centro' AS nombre_completo, 'admin@corredorcentro.com' AS email_login, NULL AS sede
    UNION ALL SELECT 'cajero.corredorcentro.bfs', 'Cajero CCN Bluefields', 'cajero.bfs@corredorcentro.com', 'Bluefields'
    UNION ALL SELECT 'cajero.corredorcentro.mga', 'Cajero CCN Managua', 'cajero.mga@corredorcentro.com', 'Managua'
) u
WHERE e.nombre = 'Corredor Centro SA'
  AND NOT EXISTS (SELECT 1 FROM usuario x WHERE x.nombre_usuario = u.nombre_usuario);

INSERT INTO usuario_rol (usuario_id, rol_id)
SELECT u.id, r.id FROM usuario u JOIN rol r ON r.nombre = IF(u.nombre_usuario LIKE 'admin.%', 'ADMIN_EMPRESA', 'CAJERO')
WHERE u.nombre_usuario IN ('admin.corredorcentro', 'cajero.corredorcentro.bfs', 'cajero.corredorcentro.mga')
  AND NOT EXISTS (SELECT 1 FROM usuario_rol ur WHERE ur.usuario_id = u.id AND ur.rol_id = r.id);

INSERT INTO bus (empresa_id, numero_interno, placa, capacidad, filas, sede, activo, foto_url)
SELECT e.id, x.numero_interno, x.placa, 50, 24, x.sede, TRUE, '/images/bus-yutong-interurbano.png'
FROM empresa e
CROSS JOIN (
    SELECT 'CN-BFS-01' AS numero_interno, 'NI-3401' AS placa, 'Bluefields' AS sede
    UNION ALL SELECT 'CN-MGA-01', 'NI-3402', 'Managua'
) x
WHERE e.nombre = 'Corredor Centro SA'
  AND NOT EXISTS (SELECT 1 FROM bus b WHERE b.numero_interno = x.numero_interno);

INSERT INTO asiento_bus (bus_id, numero, fila, posicion)
SELECT nb.id, ab.numero, ab.fila, ab.posicion
FROM bus nb INNER JOIN asiento_bus ab ON ab.bus_id = @bus_tpl
WHERE nb.numero_interno IN ('CN-BFS-01', 'CN-MGA-01')
  AND NOT EXISTS (SELECT 1 FROM asiento_bus x WHERE x.bus_id = nb.id);

INSERT INTO viaje (empresa_id, bus_id, origen, destino, fecha, hora_salida, tarifa, tarifa_equipaje_extra, estado)
SELECT e.id, b.id, 'Bluefields', 'Managua', CURDATE(), '08:15:00', 345.00, 125.00, 'PROGRAMADO'
FROM empresa e INNER JOIN bus b ON b.empresa_id = e.id AND b.numero_interno = 'CN-BFS-01'
WHERE e.nombre = 'Corredor Centro SA'
  AND NOT EXISTS (SELECT 1 FROM viaje v WHERE v.empresa_id = e.id AND v.fecha = CURDATE() AND v.hora_salida = '08:15:00');

INSERT INTO viaje (empresa_id, bus_id, origen, destino, fecha, hora_salida, tarifa, tarifa_equipaje_extra, estado)
SELECT e.id, b.id, 'Managua', 'Bluefields', CURDATE(), '17:00:00', 345.00, 125.00, 'PROGRAMADO'
FROM empresa e INNER JOIN bus b ON b.empresa_id = e.id AND b.numero_interno = 'CN-MGA-01'
WHERE e.nombre = 'Corredor Centro SA'
  AND NOT EXISTS (SELECT 1 FROM viaje v WHERE v.empresa_id = e.id AND v.fecha = CURDATE() AND v.hora_salida = '17:00:00' AND v.origen = 'Managua');

INSERT INTO viaje_asiento (viaje_id, asiento_bus_id, estado)
SELECT v.id, ab.id, 'DISPONIBLE'
FROM viaje v INNER JOIN bus b ON b.id = v.bus_id INNER JOIN asiento_bus ab ON ab.bus_id = b.id
INNER JOIN empresa e ON e.id = v.empresa_id AND e.nombre = 'Corredor Centro SA'
WHERE NOT EXISTS (SELECT 1 FROM viaje_asiento va WHERE va.viaje_id = v.id AND va.asiento_bus_id = ab.id);

INSERT INTO venta (codigo, empresa_id, viaje_id, operador_id, comprador_nombre, comprador_cedula, cantidad_boletos, subtotal_boletos, subtotal_equipaje, total, estado)
SELECT 'SEED-CN-001', e.id, v.id, u.id, 'Pedro Ruiz', '001-150404-0004D', 1, 345.00, 125.00, 470.00, 'COMPLETADA'
FROM empresa e
INNER JOIN viaje v ON v.empresa_id = e.id AND v.origen = 'Bluefields' AND v.fecha = CURDATE() AND v.hora_salida = '08:15:00'
INNER JOIN usuario u ON u.nombre_usuario = 'cajero.corredorcentro.bfs'
WHERE e.nombre = 'Corredor Centro SA' AND NOT EXISTS (SELECT 1 FROM venta WHERE codigo = 'SEED-CN-001');

INSERT INTO boleto (venta_id, viaje_asiento_id, numero_asiento, monto, pasajero_nombre, pasajero_cedula, estado)
SELECT ve.id, va.id, ab.numero, 345.00, 'Pedro Ruiz', '001-150404-0004D', 'ACTIVO'
FROM venta ve INNER JOIN viaje v ON v.id = ve.viaje_id
INNER JOIN viaje_asiento va ON va.viaje_id = v.id
INNER JOIN asiento_bus ab ON ab.id = va.asiento_bus_id AND ab.numero = 7
WHERE ve.codigo = 'SEED-CN-001' AND NOT EXISTS (SELECT 1 FROM boleto b WHERE b.viaje_asiento_id = va.id);

UPDATE viaje_asiento va INNER JOIN boleto b ON b.viaje_asiento_id = va.id INNER JOIN venta ve ON ve.id = b.venta_id
SET va.estado = 'VENDIDO' WHERE ve.codigo = 'SEED-CN-001';

INSERT INTO reserva_excepcional (viaje_asiento_id, operador_id, comprador_nombre, comprador_cedula, motivo, estado, fecha_expiracion)
SELECT va.id, u.id, 'Reserva CN Demo', '001-888888-0000R', 'Cliente empresarial — apartado temporal', 'ACTIVA', DATE_ADD(NOW(), INTERVAL 6 HOUR)
FROM venta ve INNER JOIN viaje v ON v.id = ve.viaje_id
INNER JOIN viaje_asiento va ON va.viaje_id = v.id
INNER JOIN asiento_bus ab ON ab.id = va.asiento_bus_id AND ab.numero = 8
INNER JOIN usuario u ON u.nombre_usuario = 'admin.corredorcentro'
WHERE ve.codigo = 'SEED-CN-001'
  AND NOT EXISTS (SELECT 1 FROM reserva_excepcional re WHERE re.viaje_asiento_id = va.id);

UPDATE viaje_asiento va INNER JOIN reserva_excepcional re ON re.viaje_asiento_id = va.id
SET va.estado = 'RESERVADO_EXCEPCIONAL' WHERE re.comprador_cedula = '001-888888-0000R';
