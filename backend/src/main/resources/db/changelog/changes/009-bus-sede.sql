-- V9: Sede/terminal base del bus + flota demo por terminal
ALTER TABLE bus ADD COLUMN sede VARCHAR(100) NOT NULL DEFAULT 'Bluefields' AFTER filas;

UPDATE bus SET sede = 'Bluefields' WHERE numero_interno IN ('W-01', 'M-01');

-- Bus Wendelyn en terminal Managua
INSERT INTO bus (empresa_id, numero_interno, placa, capacidad, filas, sede)
SELECT 1, 'W-02', 'NI-1002', 20, 10, 'Managua'
WHERE NOT EXISTS (SELECT 1 FROM bus WHERE numero_interno = 'W-02');

INSERT INTO asiento_bus (bus_id, numero, fila, posicion)
SELECT b.id, f * 2 - 1, f, 'VENTANA'
FROM bus b
CROSS JOIN (
    SELECT 1 AS f UNION SELECT 2 UNION SELECT 3 UNION SELECT 4 UNION SELECT 5
    UNION SELECT 6 UNION SELECT 7 UNION SELECT 8 UNION SELECT 9 UNION SELECT 10
) nums
WHERE b.numero_interno = 'W-02'
  AND NOT EXISTS (SELECT 1 FROM asiento_bus ab WHERE ab.bus_id = b.id);

INSERT INTO asiento_bus (bus_id, numero, fila, posicion)
SELECT b.id, f * 2, f, 'PASILLO'
FROM bus b
CROSS JOIN (
    SELECT 1 AS f UNION SELECT 2 UNION SELECT 3 UNION SELECT 4 UNION SELECT 5
    UNION SELECT 6 UNION SELECT 7 UNION SELECT 8 UNION SELECT 9 UNION SELECT 10
) nums
WHERE b.numero_interno = 'W-02'
  AND NOT EXISTS (SELECT 1 FROM asiento_bus ab WHERE ab.bus_id = b.id AND ab.posicion = 'PASILLO');

-- Bus Martinez en terminal Managua
INSERT INTO bus (empresa_id, numero_interno, placa, capacidad, filas, sede)
SELECT 2, 'M-02', 'NI-2002', 20, 10, 'Managua'
WHERE NOT EXISTS (SELECT 1 FROM bus WHERE numero_interno = 'M-02');

INSERT INTO asiento_bus (bus_id, numero, fila, posicion)
SELECT b.id, f * 2 - 1, f, 'VENTANA'
FROM bus b
CROSS JOIN (
    SELECT 1 AS f UNION SELECT 2 UNION SELECT 3 UNION SELECT 4 UNION SELECT 5
    UNION SELECT 6 UNION SELECT 7 UNION SELECT 8 UNION SELECT 9 UNION SELECT 10
) nums
WHERE b.numero_interno = 'M-02'
  AND NOT EXISTS (SELECT 1 FROM asiento_bus ab WHERE ab.bus_id = b.id);

INSERT INTO asiento_bus (bus_id, numero, fila, posicion)
SELECT b.id, f * 2, f, 'PASILLO'
FROM bus b
CROSS JOIN (
    SELECT 1 AS f UNION SELECT 2 UNION SELECT 3 UNION SELECT 4 UNION SELECT 5
    UNION SELECT 6 UNION SELECT 7 UNION SELECT 8 UNION SELECT 9 UNION SELECT 10
) nums
WHERE b.numero_interno = 'M-02'
  AND NOT EXISTS (SELECT 1 FROM asiento_bus ab WHERE ab.bus_id = b.id AND ab.posicion = 'PASILLO');

-- Viaje Martinez M->B debe usar bus con sede Managua
UPDATE viaje v
INNER JOIN bus b ON b.numero_interno = 'M-02'
SET v.bus_id = b.id
WHERE v.origen = 'Managua' AND v.destino = 'Bluefields' AND v.empresa_id = 2;

-- Viaje demo Wendelyn Managua -> Bluefields (bus W-02)
INSERT INTO viaje (empresa_id, bus_id, origen, destino, fecha, hora_salida, tarifa, tarifa_equipaje_extra, estado)
SELECT 1, b.id, 'Managua', 'Bluefields', CURDATE(), '15:00:00', 350.00, 150.00, 'PROGRAMADO'
FROM bus b
WHERE b.numero_interno = 'W-02'
  AND NOT EXISTS (
    SELECT 1 FROM viaje v
    WHERE v.empresa_id = 1 AND v.origen = 'Managua' AND v.destino = 'Bluefields' AND v.fecha = CURDATE()
  );

INSERT INTO viaje_asiento (viaje_id, asiento_bus_id, estado)
SELECT v.id, ab.id, 'DISPONIBLE'
FROM viaje v
INNER JOIN bus b ON b.id = v.bus_id
INNER JOIN asiento_bus ab ON ab.bus_id = b.id
WHERE v.origen = 'Managua' AND v.destino = 'Bluefields' AND v.empresa_id = 1
  AND NOT EXISTS (
    SELECT 1 FROM viaje_asiento va WHERE va.viaje_id = v.id AND va.asiento_bus_id = ab.id
  );

-- Paradas corredor Managua -> Bluefields
INSERT INTO parada_ruta (origen, destino, nombre, orden, minutos_desde_salida, latitud, longitud)
SELECT 'Managua', 'Bluefields', nombre, (6 - orden), (480 - minutos_desde_salida), latitud, longitud
FROM parada_ruta
WHERE origen = 'Bluefields' AND destino = 'Managua'
  AND NOT EXISTS (SELECT 1 FROM parada_ruta WHERE origen = 'Managua' AND destino = 'Bluefields');
