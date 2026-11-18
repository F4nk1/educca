-- ==============================================================================
-- Tabla: promotor_periodo
-- Descripción: Registro anual de promotores ambientales, actores acreditados y docentes EDUCCA
-- ==============================================================================

CREATE TABLE IF NOT EXISTS promotor_periodo (
    id                 BIGSERIAL PRIMARY KEY,
    persona_id         BIGINT NOT NULL REFERENCES persona(id) ON DELETE RESTRICT,
    anio               SMALLINT NOT NULL CHECK (anio >= 2024),
    tipo_promotor      VARCHAR(20) NOT NULL CHECK (tipo_promotor IN (
                           'PAE', 'PAJ', 'PAC', 'DOCENTE', 'COMERCIANTE', 'RECICLADOR'
                       )),
    organizacion_id    BIGINT REFERENCES organizacion(id) ON DELETE SET NULL,
    estado             VARCHAR(20) NOT NULL DEFAULT 'INSCRITO' CHECK (estado IN (
                           'INSCRITO', 'ACREDITADO', 'RETIRADO'
                       )),
    codigo_certificado VARCHAR(40) UNIQUE,
    UNIQUE (persona_id, anio, tipo_promotor)
);

CREATE INDEX IF NOT EXISTS idx_promotor_periodo_anio ON promotor_periodo(anio);
