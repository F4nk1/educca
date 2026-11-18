-- ==============================================================================
-- Tabla: inscripcion
-- Descripción: Inscripciones de capacitandos a sesiones educativas EDUCCA
-- ==============================================================================

CREATE TABLE IF NOT EXISTS inscripcion (
    id         BIGSERIAL PRIMARY KEY,
    sesion_id  BIGINT NOT NULL REFERENCES sesion(id) ON DELETE CASCADE,
    persona_id BIGINT NOT NULL REFERENCES persona(id) ON DELETE RESTRICT,
    estado     VARCHAR(15) NOT NULL DEFAULT 'INSCRITO' CHECK (estado IN (
                   'INSCRITO', 'CANCELADO'
               )),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE (sesion_id, persona_id)
);

CREATE INDEX IF NOT EXISTS idx_inscripcion_sesion_estado ON inscripcion(sesion_id, estado);
CREATE INDEX IF NOT EXISTS idx_inscripcion_persona_id ON inscripcion(persona_id);
