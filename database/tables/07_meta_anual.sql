-- ==============================================================================
-- Tabla: meta_anual
-- Descripción: Metas anuales programadas según actividades MINAM
-- ==============================================================================

CREATE TABLE IF NOT EXISTS meta_anual (
    id              BIGSERIAL PRIMARY KEY,
    anio            SMALLINT NOT NULL CHECK (anio >= 2024),
    actividad_minam VARCHAR(20) NOT NULL CHECK (actividad_minam IN (
                        'PAE', 'PAJ', 'PAC', 'EPEA', 'CAMPANA'
                    )),
    indicador       VARCHAR(120) NOT NULL,
    meta_programada INTEGER NOT NULL CHECK (meta_programada > 0),
    presupuesto     NUMERIC(10, 2) NOT NULL DEFAULT 0.00 CHECK (presupuesto >= 0),
    UNIQUE (anio, actividad_minam, indicador)
);
