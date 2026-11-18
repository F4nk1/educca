-- ==============================================================================
-- Tabla: sesion
-- Descripción: Sesiones educativas, talleres y campañas ejecutadas en EDUCCA
-- ==============================================================================

CREATE TABLE IF NOT EXISTS sesion (
    id               BIGSERIAL PRIMARY KEY,
    meta_anual_id    BIGINT NOT NULL REFERENCES meta_anual(id) ON DELETE RESTRICT,
    organizacion_id  BIGINT REFERENCES organizacion(id) ON DELETE SET NULL,
    responsable_id   BIGINT NOT NULL REFERENCES persona(id) ON DELETE RESTRICT,
    titulo           VARCHAR(150) NOT NULL,
    modalidad        VARCHAR(15) NOT NULL CHECK (modalidad IN ('PRESENCIAL', 'VIRTUAL')),
    fecha_inicio     TIMESTAMPTZ NOT NULL,
    duracion_minutos SMALLINT NOT NULL CHECK (duracion_minutos > 0),
    estado           VARCHAR(20) NOT NULL DEFAULT 'PROGRAMADA' CHECK (estado IN (
                         'PROGRAMADA', 'EJECUTADA', 'VALIDADA', 'CANCELADA'
                     ))
);

CREATE INDEX IF NOT EXISTS idx_sesion_meta_anual_id ON sesion(meta_anual_id);
CREATE INDEX IF NOT EXISTS idx_sesion_estado ON sesion(estado);
