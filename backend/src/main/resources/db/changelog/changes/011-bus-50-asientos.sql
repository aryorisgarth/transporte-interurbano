-- V10b: Layout 50 asientos — constraints, asientos 21-50, cupos en viajes

ALTER TABLE bus DROP CHECK chk_bus_filas;
ALTER TABLE bus DROP CHECK chk_bus_capacidad;

ALTER TABLE bus ADD CONSTRAINT chk_bus_capacidad CHECK (capacidad > 0);
ALTER TABLE bus ADD CONSTRAINT chk_bus_filas CHECK (filas > 0);

UPDATE bus SET capacidad = 50, filas = 24 WHERE capacidad = 20;

INSERT INTO asiento_bus (bus_id, numero, fila, posicion)
SELECT b.id, n.num, n.fila, n.pos
FROM bus b
CROSS JOIN (
    SELECT 21 AS num, 11 AS fila, 'VENTANA' AS pos UNION ALL SELECT 22, 11, 'PASILLO' UNION ALL
    SELECT 23, 12, 'VENTANA' UNION ALL SELECT 24, 12, 'PASILLO' UNION ALL
    SELECT 25, 13, 'VENTANA' UNION ALL SELECT 26, 13, 'PASILLO' UNION ALL
    SELECT 27, 14, 'VENTANA' UNION ALL SELECT 28, 14, 'PASILLO' UNION ALL
    SELECT 29, 15, 'VENTANA' UNION ALL SELECT 30, 15, 'PASILLO' UNION ALL
    SELECT 31, 16, 'VENTANA' UNION ALL SELECT 32, 16, 'PASILLO' UNION ALL
    SELECT 33, 17, 'VENTANA' UNION ALL SELECT 34, 17, 'PASILLO' UNION ALL
    SELECT 35, 18, 'VENTANA' UNION ALL SELECT 36, 18, 'PASILLO' UNION ALL
    SELECT 37, 19, 'VENTANA' UNION ALL SELECT 38, 19, 'PASILLO' UNION ALL
    SELECT 39, 20, 'VENTANA' UNION ALL SELECT 40, 20, 'PASILLO' UNION ALL
    SELECT 41, 21, 'VENTANA' UNION ALL SELECT 42, 21, 'PASILLO' UNION ALL
    SELECT 43, 22, 'VENTANA' UNION ALL SELECT 44, 22, 'PASILLO'
) n
WHERE b.capacidad = 50
  AND NOT EXISTS (SELECT 1 FROM asiento_bus ab WHERE ab.bus_id = b.id AND ab.numero = n.num);

INSERT INTO asiento_bus (bus_id, numero, fila, posicion)
SELECT b.id, 45, 23, 'VENTANA'
FROM bus b
WHERE b.capacidad = 50
  AND NOT EXISTS (SELECT 1 FROM asiento_bus ab WHERE ab.bus_id = b.id AND ab.numero = 45);

INSERT INTO asiento_bus (bus_id, numero, fila, posicion)
SELECT b.id, n.num, 24, n.pos
FROM bus b
CROSS JOIN (
    SELECT 46 AS num, 'TRASERA_1' AS pos UNION ALL
    SELECT 47, 'TRASERA_2' UNION ALL
    SELECT 48, 'TRASERA_3' UNION ALL
    SELECT 49, 'TRASERA_4' UNION ALL
    SELECT 50, 'TRASERA_5'
) n
WHERE b.capacidad = 50
  AND NOT EXISTS (SELECT 1 FROM asiento_bus ab WHERE ab.bus_id = b.id AND ab.numero = n.num);

INSERT INTO viaje_asiento (viaje_id, asiento_bus_id, estado)
SELECT v.id, ab.id, 'DISPONIBLE'
FROM viaje v
INNER JOIN asiento_bus ab ON ab.bus_id = v.bus_id
WHERE ab.numero > 20
  AND NOT EXISTS (
    SELECT 1 FROM viaje_asiento va
    WHERE va.viaje_id = v.id AND va.asiento_bus_id = ab.id
  );
