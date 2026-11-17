-- ==============================================================================
-- Tabla: persona_rol
-- Descripción: Relación N:M entre personas y roles
-- ==============================================================================

CREATE TABLE IF NOT EXISTS persona_rol (
    persona_id BIGINT NOT NULL REFERENCES persona(id) ON DELETE CASCADE,
    rol_id     SMALLINT NOT NULL REFERENCES rol(id) ON DELETE CASCADE,
    PRIMARY KEY (persona_id, rol_id)
);
