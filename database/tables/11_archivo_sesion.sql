-- ==============================================================================
-- Tabla: archivo_sesion
-- Descripción: Evidencias y documentos asociados a cada sesión
-- ==============================================================================

CREATE TABLE IF NOT EXISTS archivo_sesion (
    id          BIGSERIAL PRIMARY KEY,
    sesion_id   BIGINT NOT NULL REFERENCES sesion(id) ON DELETE CASCADE,
    tipo        VARCHAR(25) NOT NULL CHECK (tipo IN (
                    'FOTO_EVIDENCIA', 'PADRON_FIRMADO', 'ACTA', 'MATERIAL_DIDACTICO'
                )),
    url_archivo TEXT NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_archivo_sesion_sesion_id ON archivo_sesion(sesion_id);
