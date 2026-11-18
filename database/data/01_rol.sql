-- ==============================================================================
-- Datos iniciales: rol
-- ==============================================================================

INSERT INTO rol (nombre, descripcion) VALUES
    ('admin', 'Administrador del sistema EDUCCA con acceso total'),
    ('coordinador', 'Coordinador municipal responsable de metas, sedes, sesiones, validaciones y ARCO'),
    ('capacitador', 'Capacitador ambiental encargado de dictar talleres, generar QR y registrar asistencias'),
    ('capacitando', 'Ciudadano participante que se inscribe a talleres, marca asistencia QR+GPS y consulta su avance'),
    ('consulta', 'Usuario con acceso de solo lectura a catálogo y reportes agregados')
ON CONFLICT (nombre) DO UPDATE SET
    descripcion = EXCLUDED.descripcion;
