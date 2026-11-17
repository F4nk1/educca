-- ==============================================================================
-- Tabla: archivo_sesion
-- Descripción: Evidencias y documentos asociados a cada sesión
-- ==============================================================================

CREATE TABLE IF NOT EXISTS archivo_sesion (
    id          BIGINT AUTO_INCREMENT PRIMARY KEY,
    sesion_id   BIGINT NOT NULL,
    tipo        VARCHAR(25) NOT NULL CHECK (tipo IN (
                    'FOTO_EVIDENCIA', 'PADRON_FIRMADO', 'ACTA', 'MATERIAL_DIDACTICO'
                )),
    url_archivo TEXT NOT NULL,
    CONSTRAINT fk_archivo_sesion_sesion FOREIGN KEY (sesion_id) REFERENCES sesion(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
