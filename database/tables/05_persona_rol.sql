-- ==============================================================================
-- Tabla: persona_rol
-- Descripción: Relación N:M entre personas y roles
-- ==============================================================================

CREATE TABLE IF NOT EXISTS persona_rol (
    persona_id BIGINT NOT NULL,
    rol_id     SMALLINT NOT NULL,
    PRIMARY KEY (persona_id, rol_id),
    CONSTRAINT fk_persona_rol_persona FOREIGN KEY (persona_id) REFERENCES persona(id) ON DELETE CASCADE,
    CONSTRAINT fk_persona_rol_rol FOREIGN KEY (rol_id) REFERENCES rol(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
