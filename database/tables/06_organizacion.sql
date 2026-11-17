-- ==============================================================================
-- Tabla: organizacion
-- Descripción: Instituciones, colegios, organizaciones sociales y EPEA
-- ==============================================================================

CREATE TABLE IF NOT EXISTS organizacion (
    id                   BIGINT AUTO_INCREMENT PRIMARY KEY,
    nombre               VARCHAR(150) NOT NULL,
    tipo                 VARCHAR(30) NOT NULL CHECK (tipo IN (
                             'COLEGIO',
                             'EDUCACION_SUPERIOR',
                             'ORGANIZACION_SOCIAL',
                             'ESPACIO_PUBLICO_EPEA',
                             'INSTITUCION_PUBLICA'
                         )),
    codigo_modular_o_ref VARCHAR(30),
    sector_ubicacion     VARCHAR(120) NOT NULL,
    responsable_id       BIGINT,
    CONSTRAINT fk_organizacion_responsable FOREIGN KEY (responsable_id) REFERENCES persona(id) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
