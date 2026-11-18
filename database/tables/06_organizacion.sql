-- ==============================================================================
-- Tabla: organizacion
-- Descripción: Instituciones, mercados, centros de acopio, organizaciones sociales y EPEA
-- ==============================================================================

CREATE TABLE IF NOT EXISTS organizacion (
    id                   BIGSERIAL PRIMARY KEY,
    nombre               VARCHAR(150) NOT NULL,
    tipo                 VARCHAR(30) NOT NULL CHECK (tipo IN (
                             'COLEGIO',
                             'EDUCACION_SUPERIOR',
                             'ORGANIZACION_SOCIAL',
                             'ESPACIO_PUBLICO_EPEA',
                             'INSTITUCION_PUBLICA',
                             'MERCADO',
                             'CENTRO_ACOPIO'
                         )),
    codigo_modular_o_ref VARCHAR(30),
    sector_ubicacion     VARCHAR(120) NOT NULL,
    responsable_id       BIGINT REFERENCES persona(id) ON DELETE SET NULL,
    latitud              NUMERIC(9, 6) CHECK (latitud IS NULL OR (latitud >= -90 AND latitud <= 90)),
    longitud             NUMERIC(9, 6) CHECK (longitud IS NULL OR (longitud >= -180 AND longitud <= 180)),
    radio_metros         INTEGER NOT NULL DEFAULT 80 CHECK (radio_metros > 0),
    CHECK ((latitud IS NULL AND longitud IS NULL) OR (latitud IS NOT NULL AND longitud IS NOT NULL))
);
