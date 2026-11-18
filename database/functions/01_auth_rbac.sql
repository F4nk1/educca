-- ==============================================================================
-- Funciones: Autenticación y RBAC
-- ==============================================================================

CREATE OR REPLACE FUNCTION fn_auth_login(p_identificador VARCHAR)
RETURNS TABLE (
    id            BIGINT,
    dni           VARCHAR,
    nombres       VARCHAR,
    apellidos     VARCHAR,
    email         VARCHAR,
    password_hash TEXT,
    activo        BOOLEAN
)
LANGUAGE sql
STABLE
AS $$
    SELECT p.id, p.dni, p.nombres, p.apellidos, p.email, p.password_hash, p.activo
    FROM persona p
    WHERE (p.dni = p_identificador OR LOWER(p.email) = LOWER(p_identificador))
      AND p.password_hash IS NOT NULL
      AND p.anonimizado = FALSE
    LIMIT 1;
$$;

CREATE OR REPLACE FUNCTION fn_persona_roles_nombres(p_persona_id BIGINT)
RETURNS TABLE (nombre VARCHAR)
LANGUAGE sql
STABLE
AS $$
    SELECT r.nombre
    FROM persona_rol pr
    JOIN rol r ON r.id = pr.rol_id
    WHERE pr.persona_id = p_persona_id
    ORDER BY r.nombre;
$$;

CREATE OR REPLACE FUNCTION fn_persona_permisos_claves(p_persona_id BIGINT)
RETURNS TABLE (clave VARCHAR)
LANGUAGE sql
STABLE
AS $$
    SELECT DISTINCT pm.clave
    FROM persona_rol pr
    JOIN rol_permiso rp ON rp.rol_id = pr.rol_id
    JOIN permiso pm ON pm.id = rp.permiso_id
    WHERE pr.persona_id = p_persona_id
    ORDER BY pm.clave;
$$;

CREATE OR REPLACE FUNCTION fn_persona_tiene_permiso(p_persona_id BIGINT, p_clave VARCHAR)
RETURNS BOOLEAN
LANGUAGE sql
STABLE
AS $$
    SELECT EXISTS (
        SELECT 1
        FROM persona p
        JOIN persona_rol pr ON pr.persona_id = p.id
        JOIN rol_permiso rp ON rp.rol_id = pr.rol_id
        JOIN permiso pm ON pm.id = rp.permiso_id
        WHERE p.id = p_persona_id
          AND p.activo = TRUE
          AND p.anonimizado = FALSE
          AND pm.clave = p_clave
    );
$$;
