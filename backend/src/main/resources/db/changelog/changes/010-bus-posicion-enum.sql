-- V10a: Ampliar ENUM posicion para fila trasera (46-50)
ALTER TABLE asiento_bus MODIFY COLUMN posicion ENUM(
    'VENTANA',
    'PASILLO',
    'TRASERA_1',
    'TRASERA_2',
    'TRASERA_3',
    'TRASERA_4',
    'TRASERA_5'
) NOT NULL;
