-- ==============================================================================
-- Datos iniciales: persona
-- Contraseña por defecto para usuario semilla: password123 (hash bcrypt)
-- ==============================================================================

INSERT INTO persona (dni, nombres, apellidos, sexo, fecha_nacimiento, telefono, email, password_hash, activo) VALUES
    ('00000000', 'Admin', 'Principal', 'M', '1990-01-01', '+51999999999', 'admin@educca.gob.pe', '$2a$10$vI8aWBnW3fID.ZQ4/zo1G.q1lRps.9cGLcZEiGDMVr5yUP1KUOYTa', TRUE)
ON DUPLICATE KEY UPDATE
    nombres = VALUES(nombres),
    apellidos = VALUES(apellidos),
    telefono = VALUES(telefono),
    email = VALUES(email),
    activo = VALUES(activo);
