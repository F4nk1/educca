-- ==============================================================================
-- Datos iniciales: persona_rol
-- ==============================================================================

INSERT INTO persona_rol (persona_id, rol_id)
SELECT p.id, r.id
FROM persona p
JOIN rol r ON r.nombre = 'admin'
WHERE p.dni = '00000000'
ON DUPLICATE KEY UPDATE persona_id = persona_rol.persona_id;
