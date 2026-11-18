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
    eje_tematico     VARCHAR(40) NOT NULL DEFAULT 'SEGREGACION_RECICLA' CHECK (eje_tematico IN (
                         'SEGREGACION_RECICLA',
                         'RECICLAJE_FORMAL',
                         'COMPOSTAJE',
                         'ECOEFICIENCIA',
                         'GESTION_RESIDUOS'
                     )),
    fecha_inicio     TIMESTAMPTZ NOT NULL,
    duracion_minutos SMALLINT NOT NULL CHECK (duracion_minutos > 0),
    cupo_maximo      INTEGER NOT NULL DEFAULT 50 CHECK (cupo_maximo > 0),
    estado           VARCHAR(20) NOT NULL DEFAULT 'PROGRAMADA' CHECK (estado IN (
                         'PROGRAMADA', 'EJECUTADA', 'VALIDADA', 'CANCELADA'
                     ))
);

CREATE INDEX IF NOT EXISTS idx_sesion_meta_anual_id ON sesion(meta_anual_id);
CREATE INDEX IF NOT EXISTS idx_sesion_estado ON sesion(estado);
CREATE INDEX IF NOT EXISTS idx_sesion_eje_tematico ON sesion(eje_tematico);
CREATE INDEX IF NOT EXISTS idx_sesion_organizacion_fecha ON sesion(organizacion_id, fecha_inicio);
CREATE INDEX IF NOT EXISTS idx_sesion_responsable_fecha ON sesion(responsable_id, fecha_inicio);
