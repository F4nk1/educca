-- ==============================================================================
-- Datos iniciales: rol
-- ==============================================================================

INSERT INTO rol (nombre, descripcion) VALUES
    ('admin', 'Administrador del sistema EDUCCA con acceso total'),
    ('coordinador', 'Coordinador municipal responsable de metas, sesiones y validaciones'),
    ('promotor', 'Promotor ambiental o docente acreditado para registrar actividades'),
    ('consulta', 'Usuario con acceso de solo lectura a reportes y sesiones')
ON DUPLICATE KEY UPDATE
    descripcion = VALUES(descripcion);
