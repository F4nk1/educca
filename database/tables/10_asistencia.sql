-- ==============================================================================
-- Tabla: asistencia
-- Descripción: Registro de participantes por sesión y su calificación
-- ==============================================================================

CREATE TABLE IF NOT EXISTS asistencia (
    sesion_id     BIGINT NOT NULL,
    persona_id    BIGINT NOT NULL,
    participacion VARCHAR(20) NOT NULL DEFAULT 'ASISTENTE' CHECK (participacion IN (
                      'ASISTENTE', 'VOLUNTARIO_REPLICA', 'PONENTE'
                  )),
    calificacion  DECIMAL(4, 2),
    PRIMARY KEY (sesion_id, persona_id),
    CONSTRAINT fk_asistencia_sesion FOREIGN KEY (sesion_id) REFERENCES sesion(id) ON DELETE CASCADE,
    CONSTRAINT fk_asistencia_persona FOREIGN KEY (persona_id) REFERENCES persona(id) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
