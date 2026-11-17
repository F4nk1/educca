-- ==============================================================================
-- Tabla: permiso
-- Descripción: Permisos granulares del sistema (ej. 'sesiones:crear')
-- ==============================================================================

CREATE TABLE IF NOT EXISTS permiso (
    id          SMALLINT AUTO_INCREMENT PRIMARY KEY,
    clave       VARCHAR(60) NOT NULL UNIQUE,
    descripcion VARCHAR(150) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
