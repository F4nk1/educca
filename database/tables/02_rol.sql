-- ==============================================================================
-- Tabla: rol
-- Descripción: Roles del sistema para control de acceso (RBAC dinámico)
-- ==============================================================================

CREATE TABLE IF NOT EXISTS rol (
    id          SMALLINT AUTO_INCREMENT PRIMARY KEY,
    nombre      VARCHAR(50) NOT NULL UNIQUE,
    descripcion VARCHAR(150) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
