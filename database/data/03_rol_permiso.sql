-- ==============================================================================
-- Datos iniciales: rol_permiso
-- ==============================================================================

INSERT INTO rol_permiso (rol_id, permiso_id)
SELECT r.id, p.id
FROM rol r
CROSS JOIN permiso p
WHERE r.nombre = 'admin'
ON CONFLICT (rol_id, permiso_id) DO NOTHING;

INSERT INTO rol_permiso (rol_id, permiso_id)
SELECT r.id, p.id
FROM rol r
JOIN permiso p ON p.clave IN (
    'personas:leer', 'personas:escribir',
    'organizaciones:leer', 'organizaciones:escribir',
    'metas:leer', 'metas:escribir',
    'promotores:leer', 'promotores:escribir',
    'sesiones:leer', 'sesiones:crear', 'sesiones:validar', 'sesiones:qr',
    'inscripciones:leer', 'inscripciones:gestionar',
    'asistencias:registrar', 'asistencias:checkin_qr',
    'archivos:subir', 'reportes:exportar', 'arco:gestionar'
)
WHERE r.nombre = 'coordinador'
ON CONFLICT (rol_id, permiso_id) DO NOTHING;

INSERT INTO rol_permiso (rol_id, permiso_id)
SELECT r.id, p.id
FROM rol r
JOIN permiso p ON p.clave IN (
    'organizaciones:leer', 'metas:leer', 'promotores:leer',
    'sesiones:leer', 'sesiones:qr',
    'inscripciones:leer',
    'asistencias:registrar', 'archivos:subir'
)
WHERE r.nombre = 'capacitador'
ON CONFLICT (rol_id, permiso_id) DO NOTHING;

INSERT INTO rol_permiso (rol_id, permiso_id)
SELECT r.id, p.id
FROM rol r
JOIN permiso p ON p.clave IN (
    'organizaciones:leer', 'sesiones:leer',
    'inscripciones:gestionar', 'asistencias:checkin_qr'
)
WHERE r.nombre = 'capacitando'
ON CONFLICT (rol_id, permiso_id) DO NOTHING;

INSERT INTO rol_permiso (rol_id, permiso_id)
SELECT r.id, p.id
FROM rol r
JOIN permiso p ON p.clave IN (
    'organizaciones:leer', 'metas:leer',
    'promotores:leer', 'sesiones:leer', 'reportes:exportar'
)
WHERE r.nombre = 'consulta'
ON CONFLICT (rol_id, permiso_id) DO NOTHING;
