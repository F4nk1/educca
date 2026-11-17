-- ==============================================================================
-- Tabla: rol_permiso
-- Descripción: Relación N:M entre roles y permisos
-- ==============================================================================

CREATE TABLE IF NOT EXISTS rol_permiso (
    rol_id     SMALLINT NOT NULL,
    permiso_id SMALLINT NOT NULL,
    PRIMARY KEY (rol_id, permiso_id),
    CONSTRAINT fk_rol_permiso_rol FOREIGN KEY (rol_id) REFERENCES rol(id) ON DELETE CASCADE,
    CONSTRAINT fk_rol_permiso_permiso FOREIGN KEY (permiso_id) REFERENCES permiso(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
