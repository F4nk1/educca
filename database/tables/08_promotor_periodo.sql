-- ==============================================================================
-- Tabla: promotor_periodo
-- Descripción: Registro anual de promotores ambientales y docentes EDUCCA
-- ==============================================================================

CREATE TABLE IF NOT EXISTS promotor_periodo (
    id                 BIGSERIAL PRIMARY KEY,
    persona_id         BIGINT NOT NULL REFERENCES persona(id) ON DELETE RESTRICT,
    anio               SMALLINT NOT NULL,
    tipo_promotor      VARCHAR(10) NOT NULL CHECK (tipo_promotor IN (
                           'PAE', 'PAJ', 'PAC', 'DOCENTE'
                       )),
    organizacion_id    BIGINT REFERENCES organizacion(id) ON DELETE SET NULL,
    estado             VARCHAR(20) NOT NULL DEFAULT 'INSCRITO' CHECK (estado IN (
                           'INSCRITO', 'ACREDITADO', 'RETIRADO'
                       )),
    codigo_certificado VARCHAR(40) UNIQUE,
    UNIQUE (persona_id, anio, tipo_promotor)
);
