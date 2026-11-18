-- ==============================================================================
-- Tabla: asistencia
-- Descripción: Registro de participantes por sesión y su calificación
-- ==============================================================================

CREATE TABLE IF NOT EXISTS asistencia (
    sesion_id     BIGINT NOT NULL REFERENCES sesion(id) ON DELETE CASCADE,
    persona_id    BIGINT NOT NULL REFERENCES persona(id) ON DELETE RESTRICT,
    participacion VARCHAR(20) NOT NULL DEFAULT 'ASISTENTE' CHECK (participacion IN (
                      'ASISTENTE', 'VOLUNTARIO_REPLICA', 'PONENTE'
                  )),
    calificacion  NUMERIC(4, 2) CHECK (calificacion >= 0 AND calificacion <= 20),
    PRIMARY KEY (sesion_id, persona_id)
);
