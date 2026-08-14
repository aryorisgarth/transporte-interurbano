-- V7: Logo empresa, foto bus, paradas ruta Bluefields-Managua
ALTER TABLE empresa ADD COLUMN logo_url VARCHAR(500) NULL;
ALTER TABLE bus ADD COLUMN foto_url VARCHAR(500) NULL;

CREATE TABLE parada_ruta (
    id                      BIGINT AUTO_INCREMENT PRIMARY KEY,
    origen                  VARCHAR(100) NOT NULL DEFAULT 'Bluefields',
    destino                 VARCHAR(100) NOT NULL DEFAULT 'Managua',
    nombre                  VARCHAR(120) NOT NULL,
    orden                   INT NOT NULL,
    minutos_desde_salida    INT NOT NULL DEFAULT 0,
    latitud                 DECIMAL(10, 7) NULL,
    longitud                DECIMAL(10, 7) NULL,
    activo                  BOOLEAN NOT NULL DEFAULT TRUE,
    CONSTRAINT uq_parada_ruta_orden UNIQUE (origen, destino, orden)
);

CREATE INDEX idx_parada_ruta_busqueda ON parada_ruta (origen, destino, activo, orden);

INSERT INTO parada_ruta (origen, destino, nombre, orden, minutos_desde_salida, latitud, longitud) VALUES
    ('Bluefields', 'Managua', 'Terminal Bluefields', 1, 0, 12.0131, -83.7635),
    ('Bluefields', 'Managua', 'El Rama', 2, 90, 12.1597, -84.2192),
    ('Bluefields', 'Managua', 'Nueva Guinea', 3, 180, 11.6866, -84.4560),
    ('Bluefields', 'Managua', 'Juigalpa', 4, 300, 12.1064, -85.3645),
    ('Bluefields', 'Managua', 'Terminal Managua (Ulaprobus)', 5, 480, 12.1364, -86.2514);

UPDATE empresa SET logo_url = 'https://ui-avatars.com/api/?name=Wendelyn&background=1565c0&color=fff&size=128'
WHERE nombre LIKE '%Wendelyn%';

UPDATE empresa SET logo_url = 'https://ui-avatars.com/api/?name=Martinez&background=2e7d32&color=fff&size=128'
WHERE nombre LIKE '%Martinez%';
