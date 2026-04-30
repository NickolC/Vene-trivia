-- Script manual para crear superadmins.
-- Ejecutar en la base: res://DB/venetrivia.db

CREATE TABLE IF NOT EXISTS SuperAdmin (
  NU_USU INTEGER PRIMARY KEY AUTOINCREMENT,
  NM_SUPERADMIN TEXT NOT NULL UNIQUE,
  CO_PSW TEXT NOT NULL
);

-- Superusuario inicial por defecto
INSERT OR IGNORE INTO SuperAdmin (NM_SUPERADMIN, CO_PSW)
VALUES ('admin', 'admin');

-- Ejemplo adicional opcional
-- INSERT OR IGNORE INTO SuperAdmin (NM_SUPERADMIN, CO_PSW)
-- VALUES ('ops_admin', 'cambia_otra_clave');

-- Consulta de verificacion
SELECT NU_USU, NM_SUPERADMIN FROM SuperAdmin ORDER BY NU_USU;
