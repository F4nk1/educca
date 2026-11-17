-- ==============================================================================
-- Datos iniciales: permiso
-- ==============================================================================

INSERT INTO permiso (clave, descripcion) VALUES
    ('personas:leer', 'Consultar personas registradas'),
    ('personas:escribir', 'Registrar y actualizar personas'),
    ('roles:gestionar', 'Administrar roles y permisos'),
    ('organizaciones:leer', 'Consultar organizaciones registradas'),
    ('organizaciones:escribir', 'Registrar y actualizar organizaciones'),
    ('metas:leer', 'Consultar metas anuales MINAM'),
    ('metas:escribir', 'Programar y actualizar metas anuales'),
    ('promotores:leer', 'Consultar promotores por periodo'),
    ('promotores:escribir', 'Inscribir y acreditar promotores'),
    ('sesiones:leer', 'Consultar sesiones educativas'),
    ('sesiones:crear', 'Programar y registrar sesiones educativas'),
    ('sesiones:validar', 'Validar o cancelar sesiones ejecutadas'),
    ('asistencias:registrar', 'Registrar asistencia y calificaciones'),
    ('archivos:subir', 'Adjuntar evidencias y actas a sesiones'),
    ('reportes:exportar', 'Exportar reportes consolidados EDUCCA')
ON CONFLICT (clave) DO UPDATE SET
    descripcion = EXCLUDED.descripcion;
