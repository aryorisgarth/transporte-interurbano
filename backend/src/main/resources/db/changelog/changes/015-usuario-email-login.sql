-- Email de acceso Keycloak (distinto del correo de contacto de la cooperativa)
ALTER TABLE usuario ADD COLUMN email_login VARCHAR(150) NULL AFTER nombre_completo;

UPDATE usuario SET email_login = CONCAT(nombre_usuario, '@transporte.local') WHERE email_login IS NULL;
