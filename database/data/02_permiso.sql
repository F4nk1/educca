-- ==============================================================================
-- Datos iniciales: permiso
-- ==============================================================================

INSERT INTO permiso (clave, descripcion) VALUES
    ('personas:leer', 'Consultar personas registradas'),
    ('personas:escribir', 'Registrar y actualizar personas'),
    ('roles:gestionar', 'Administrar roles y permisos'),
    ('organizaciones:leer', 'Consultar organizaciones y sedes registradas'),
    ('organizaciones:escribir', 'Registrar y actualizar organizaciones y sedes georreferenciadas'),
    ('metas:leer', 'Consultar metas anuales MINAM'),
    ('metas:escribir', 'Programar y actualizar metas anuales'),
    ('promotores:leer', 'Consultar promotores por periodo'),
    ('promotores:escribir', 'Inscribir y acreditar promotores'),
    ('sesiones:leer', 'Consultar catálogo de sesiones educativas'),
    ('sesiones:crear', 'Programar, actualizar y eliminar sesiones educativas'),
    ('sesiones:validar', 'Validar o cancelar sesiones ejecutadas'),
    ('sesiones:qr', 'Generar, consultar y revocar código QR dinámico y monitorear sesión en tiempo real'),
    ('inscripciones:leer', 'Consultar lista de inscritos de una sesión'),
    ('inscripciones:gestionar', 'Inscribirse, cancelar inscripción propia y consultar talleres inscritos'),
    ('asistencias:registrar', 'Registrar y consultar asistencia y calificaciones de una sesión'),
    ('asistencias:checkin_qr', 'Registrar asistencia presencial con QR y GPS y consultar historial propio'),
    ('archivos:subir', 'Adjuntar evidencias, actas y material didáctico a sesiones'),
    ('reportes:exportar', 'Exportar reportes consolidados EDUCCA'),
    ('arco:gestionar', 'Gestionar exportación y anonimización de datos personales conforme a la LPDP (ARCO)')
ON CONFLICT (clave) DO UPDATE SET
    descripcion = EXCLUDED.descripcion;
