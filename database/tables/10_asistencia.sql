-- ==============================================================================
-- Tabla: asistencia
-- Descripción: Registro de participantes por sesión y su calificación
-- ==============================================================================

CREATE TABLE IF NOT EXISTS asistencia (
    sesion_id        BIGINT NOT NULL REFERENCES sesion(id) ON DELETE CASCADE,
    persona_id       BIGINT NOT NULL REFERENCES persona(id) ON DELETE RESTRICT,
    participacion    VARCHAR(20) NOT NULL DEFAULT 'ASISTENTE' CHECK (participacion IN (
                         'ASISTENTE', 'VOLUNTARIO_REPLICA', 'PONENTE'
                     )),
    calificacion     NUMERIC(4, 2) CHECK (calificacion >= 0 AND calificacion <= 20),
    metodo_registro  VARCHAR(15) NOT NULL DEFAULT 'MANUAL' CHECK (metodo_registro IN (
                         'MANUAL', 'QR_GPS'
                     )),
    distancia_metros NUMERIC(8, 2) CHECK (distancia_metros IS NULL OR distancia_metros >= 0),
    registrado_at    TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    PRIMARY KEY (sesion_id, persona_id)
);
