-- ==============================================================================
-- Funciones: Persona y asignación de roles
-- ==============================================================================

CREATE OR REPLACE FUNCTION fn_persona_listar()
RETURNS TABLE (
    id               BIGINT,
    dni              VARCHAR,
    nombres          VARCHAR,
    apellidos        VARCHAR,
    sexo             CHAR(1),
    fecha_nacimiento DATE,
    telefono         VARCHAR,
    email            VARCHAR,
    activo           BOOLEAN
)
LANGUAGE sql
STABLE
AS $$
    SELECT p.id, p.dni, p.nombres, p.apellidos, p.sexo, p.fecha_nacimiento, p.telefono, p.email, p.activo
    FROM persona p
    ORDER BY p.id;
$$;

CREATE OR REPLACE FUNCTION fn_persona_obtener(p_id BIGINT)
RETURNS TABLE (
    id               BIGINT,
    dni              VARCHAR,
    nombres          VARCHAR,
    apellidos        VARCHAR,
    sexo             CHAR(1),
    fecha_nacimiento DATE,
    telefono         VARCHAR,
    email            VARCHAR,
    activo           BOOLEAN
)
LANGUAGE sql
STABLE
AS $$
    SELECT p.id, p.dni, p.nombres, p.apellidos, p.sexo, p.fecha_nacimiento, p.telefono, p.email, p.activo
    FROM persona p
    WHERE p.id = p_id;
$$;

CREATE OR REPLACE FUNCTION fn_persona_crear(
    p_dni              VARCHAR,
    p_nombres          VARCHAR,
    p_apellidos        VARCHAR,
    p_sexo             CHAR(1),
    p_fecha_nacimiento DATE,
    p_telefono         VARCHAR,
    p_email            VARCHAR,
    p_password_hash    TEXT,
    p_activo           BOOLEAN
)
RETURNS BIGINT
LANGUAGE sql
AS $$
    INSERT INTO persona (dni, nombres, apellidos, sexo, fecha_nacimiento, telefono, email, password_hash, activo)
    VALUES (p_dni, p_nombres, p_apellidos, p_sexo, p_fecha_nacimiento, NULLIF(BTRIM(p_telefono), ''), NULLIF(BTRIM(p_email), ''), p_password_hash, p_activo)
    RETURNING id;
$$;

CREATE OR REPLACE FUNCTION fn_persona_actualizar(
    p_id               BIGINT,
    p_dni              VARCHAR,
    p_nombres          VARCHAR,
    p_apellidos        VARCHAR,
    p_sexo             CHAR(1),
    p_fecha_nacimiento DATE,
    p_telefono         VARCHAR,
    p_email            VARCHAR
)
RETURNS BOOLEAN
LANGUAGE plpgsql
AS $$
BEGIN
    UPDATE persona
    SET dni = p_dni,
        nombres = p_nombres,
        apellidos = p_apellidos,
        sexo = p_sexo,
        fecha_nacimiento = p_fecha_nacimiento,
        telefono = NULLIF(BTRIM(p_telefono), ''),
        email = NULLIF(BTRIM(p_email), '')
    WHERE id = p_id;
    RETURN FOUND;
END;
$$;

CREATE OR REPLACE FUNCTION fn_persona_cambiar_activo(p_id BIGINT, p_activo BOOLEAN)
RETURNS BOOLEAN
LANGUAGE plpgsql
AS $$
BEGIN
    UPDATE persona SET activo = p_activo WHERE id = p_id;
    RETURN FOUND;
END;
$$;

CREATE OR REPLACE FUNCTION fn_persona_cambiar_password(p_id BIGINT, p_password_hash TEXT)
RETURNS BOOLEAN
LANGUAGE plpgsql
AS $$
BEGIN
    UPDATE persona SET password_hash = p_password_hash WHERE id = p_id;
    RETURN FOUND;
END;
$$;

CREATE OR REPLACE FUNCTION fn_persona_listar_roles(p_persona_id BIGINT)
RETURNS TABLE (id SMALLINT, nombre VARCHAR, descripcion VARCHAR)
LANGUAGE plpgsql
STABLE
AS $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM persona p WHERE p.id = p_persona_id) THEN
        RAISE EXCEPTION 'Persona no encontrada' USING ERRCODE = 'P0002';
    END IF;

    RETURN QUERY
    SELECT r.id, r.nombre, r.descripcion
    FROM persona_rol pr
    JOIN rol r ON r.id = pr.rol_id
    WHERE pr.persona_id = p_persona_id
    ORDER BY r.id;
END;
$$;

CREATE OR REPLACE FUNCTION fn_persona_asignar_rol(p_persona_id BIGINT, p_rol_id SMALLINT)
RETURNS VOID
LANGUAGE sql
AS $$
    INSERT INTO persona_rol (persona_id, rol_id)
    VALUES (p_persona_id, p_rol_id)
    ON CONFLICT (persona_id, rol_id) DO NOTHING;
$$;

CREATE OR REPLACE FUNCTION fn_persona_quitar_rol(p_persona_id BIGINT, p_rol_id SMALLINT)
RETURNS BOOLEAN
LANGUAGE plpgsql
AS $$
BEGIN
    DELETE FROM persona_rol WHERE persona_id = p_persona_id AND rol_id = p_rol_id;
    RETURN FOUND;
END;
$$;
