-- V4: Buses, asientos y viajes demo (listos para consulta publica y venta)
-- Fechas relativas a CURDATE() para que la demo funcione cualquier dia.
-- Tarifa boleto: C$ 350

-- Buses (capacidad 20 = 10 filas x 2 columnas ventana/pasillo)
INSERT INTO bus (empresa_id, numero_interno, placa, capacidad, filas) VALUES
    (1, 'W-01', 'NI-1001', 20, 10),
    (2, 'M-01', 'NI-2001', 20, 10);

-- Asientos bus Wendelyn (bus_id = 1)
INSERT INTO asiento_bus (bus_id, numero, fila, posicion)
WITH RECURSIVE filas AS (
    SELECT 1 AS f
    UNION ALL
    SELECT f + 1 FROM filas WHERE f < 10
)
SELECT 1, f * 2 - 1, f, 'VENTANA' FROM filas
UNION ALL
SELECT 1, f * 2, f, 'PASILLO' FROM filas;

-- Asientos bus Martinez (bus_id = 2)
INSERT INTO asiento_bus (bus_id, numero, fila, posicion)
WITH RECURSIVE filas AS (
    SELECT 1 AS f
    UNION ALL
    SELECT f + 1 FROM filas WHERE f < 10
)
SELECT 2, f * 2 - 1, f, 'VENTANA' FROM filas
UNION ALL
SELECT 2, f * 2, f, 'PASILLO' FROM filas;

-- Viajes programados (hoy y manana; venta permitida dia anterior o mismo dia)
INSERT INTO viaje (empresa_id, bus_id, origen, destino, fecha, hora_salida, tarifa, tarifa_equipaje_extra, estado) VALUES
    (1, 1, 'Bluefields', 'Managua', CURDATE(), '06:00:00', 350.00, 150.00, 'PROGRAMADO'),
    (1, 1, 'Bluefields', 'Managua', DATE_ADD(CURDATE(), INTERVAL 1 DAY), '14:00:00', 350.00, 150.00, 'PROGRAMADO'),
    (2, 2, 'Bluefields', 'Managua', CURDATE(), '07:30:00', 350.00, 120.00, 'PROGRAMADO'),
    (2, 2, 'Managua', 'Bluefields', CURDATE(), '15:00:00', 350.00, 120.00, 'PROGRAMADO');

-- Cupos por viaje (todos DISPONIBLE al crear)
INSERT INTO viaje_asiento (viaje_id, asiento_bus_id, estado)
SELECT v.id, ab.id, 'DISPONIBLE'
FROM viaje v
INNER JOIN asiento_bus ab ON ab.bus_id = v.bus_id;
