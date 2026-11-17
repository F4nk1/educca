-- ==============================================================================
-- Tabla: sesion
-- Descripción: Sesiones educativas, talleres y campañas ejecutadas en EDUCCA
-- ==============================================================================

CREATE TABLE IF NOT EXISTS sesion (
    id               BIGINT AUTO_INCREMENT PRIMARY KEY,
    meta_anual_id    BIGINT NOT NULL,
    organizacion_id  BIGINT,
    responsable_id   BIGINT NOT NULL,
    titulo           VARCHAR(150) NOT NULL,
    modalidad        VARCHAR(15) NOT NULL CHECK (modalidad IN ('PRESENCIAL', 'VIRTUAL')),
    fecha_inicio     DATETIME NOT NULL,
    duracion_minutos SMALLINT NOT NULL CHECK (duracion_minutos > 0),
    estado           VARCHAR(20) NOT NULL DEFAULT 'PROGRAMADA' CHECK (estado IN (
                         'PROGRAMADA', 'EJECUTADA', 'VALIDADA', 'CANCELADA'
                     )),
    CONSTRAINT fk_sesion_meta_anual FOREIGN KEY (meta_anual_id) REFERENCES meta_anual(id) ON DELETE RESTRICT,
    CONSTRAINT fk_sesion_organizacion FOREIGN KEY (organizacion_id) REFERENCES organizacion(id) ON DELETE SET NULL,
    CONSTRAINT fk_sesion_responsable FOREIGN KEY (responsable_id) REFERENCES persona(id) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
