-- V8: Pulido demo — nombres, logos, fotos bus, venta precargada
UPDATE empresa SET nombre = 'Wendelyn Transporte' WHERE nombre = 'Wendelyn';
UPDATE empresa SET nombre = 'Martínez Líneas' WHERE nombre IN ('Martinez', 'Martínez');

UPDATE empresa SET logo_url = 'https://ui-avatars.com/api/?name=WT&background=1565c0&color=fff&size=128'
WHERE nombre LIKE '%Wendelyn%';

UPDATE empresa SET logo_url = 'https://ui-avatars.com/api/?name=ML&background=2e7d32&color=fff&size=128'
WHERE nombre LIKE '%Martínez%' OR nombre LIKE '%Martinez%';

UPDATE bus SET foto_url = 'https://images.unsplash.com/photo-1544620301-c513106a1ad0?w=640&q=80'
WHERE numero_interno = 'W-01';

UPDATE bus SET foto_url = 'https://images.unsplash.com/photo-1570125909232-e097323dfdff?w=640&q=80'
WHERE numero_interno = 'M-01';

-- Venta demo: 2 asientos vendidos en viaje Wendelyn 6:00 AM de hoy
INSERT INTO venta (
    codigo, empresa_id, viaje_id, operador_id,
    comprador_nombre, comprador_cedula, cantidad_boletos,
    subtotal_boletos, subtotal_equipaje, total
)
SELECT
    'DEMO-001', v.empresa_id, v.id, u.id,
    'María López', '001-250678-0001A', 2,
    700.00, 0.00, 700.00
FROM viaje v
INNER JOIN usuario u ON u.nombre_usuario = 'cajero.wendelyn'
WHERE v.origen = 'Bluefields'
  AND v.destino = 'Managua'
  AND v.fecha = CURDATE()
  AND v.hora_salida = '06:00:00'
  AND NOT EXISTS (SELECT 1 FROM venta WHERE codigo = 'DEMO-001');

INSERT INTO boleto (venta_id, viaje_asiento_id, numero_asiento, monto, pasajero_nombre, pasajero_cedula)
SELECT
    ve.id, va.id, ab.numero, 350.00, 'María López', '001-250678-0001A'
FROM venta ve
INNER JOIN viaje v ON v.id = ve.viaje_id
INNER JOIN viaje_asiento va ON va.viaje_id = v.id AND va.estado = 'DISPONIBLE'
INNER JOIN asiento_bus ab ON ab.id = va.asiento_bus_id
WHERE ve.codigo = 'DEMO-001'
ORDER BY ab.numero
LIMIT 2;

UPDATE viaje_asiento va
INNER JOIN boleto b ON b.viaje_asiento_id = va.id
INNER JOIN venta ve ON ve.id = b.venta_id
SET va.estado = 'VENDIDO'
WHERE ve.codigo = 'DEMO-001';
