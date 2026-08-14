-- V12: Patrón zigzag — filas pares invierten ventana/pasillo (3P·4V, 7P·8V, …)
-- Swap en 3 pasos para no violar uq_asiento_bus_fila_pos (bus_id, fila, posicion)

-- Paso 1: marcar temporalmente el asiento izquierdo de filas pares
UPDATE asiento_bus
SET posicion = 'TRASERA_1'
WHERE fila BETWEEN 2 AND 22
  AND fila % 2 = 0
  AND numero = fila * 2 - 1
  AND posicion = 'VENTANA';

-- Paso 2: pasillo derecho → ventana
UPDATE asiento_bus
SET posicion = 'VENTANA'
WHERE fila BETWEEN 2 AND 22
  AND fila % 2 = 0
  AND numero = fila * 2
  AND posicion = 'PASILLO';

-- Paso 3: temporal → pasillo izquierdo
UPDATE asiento_bus
SET posicion = 'PASILLO'
WHERE fila BETWEEN 2 AND 22
  AND fila % 2 = 0
  AND numero = fila * 2 - 1
  AND posicion = 'TRASERA_1';
