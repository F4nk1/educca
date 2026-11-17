-- ==============================================================================
-- Tabla: promotor_periodo
-- Descripción: Registro anual de promotores ambientales y docentes EDUCCA
-- ==============================================================================

CREATE TABLE IF NOT EXISTS promotor_periodo (
    id                 BIGINT AUTO_INCREMENT PRIMARY KEY,
    persona_id         BIGINT NOT NULL,
    anio               SMALLINT NOT NULL,
    tipo_promotor      VARCHAR(10) NOT NULL CHECK (tipo_promotor IN (
                           'PAE', 'PAJ', 'PAC', 'DOCENTE'
                       )),
    organizacion_id    BIGINT,
    estado             VARCHAR(20) NOT NULL DEFAULT 'INSCRITO' CHECK (estado IN (
                           'INSCRITO', 'ACREDITADO', 'RETIRADO'
                       )),
    codigo_certificado VARCHAR(40) UNIQUE,
    UNIQUE (persona_id, anio, tipo_promotor),
    CONSTRAINT fk_promotor_periodo_persona FOREIGN KEY (persona_id) REFERENCES persona(id) ON DELETE RESTRICT,
    CONSTRAINT fk_promotor_periodo_organizacion FOREIGN KEY (organizacion_id) REFERENCES organizacion(id) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
