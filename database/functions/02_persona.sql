-- ==============================================================================
-- Funciones: Persona, registro ciudadano LPDP, roles y derechos ARCO
-- ==============================================================================

CREATE OR REPLACE FUNCTION fn_persona_listar()
RETURNS TABLE (
    id                     BIGINT,
    dni                    VARCHAR,
    nombres                VARCHAR,
    apellidos              VARCHAR,
    sexo                   CHAR(1),
    fecha_nacimiento       DATE,
    telefono               VARCHAR,
    email                  VARCHAR,
    categoria              VARCHAR,
    consentimiento_at      TIMESTAMPTZ,
    consentimiento_version VARCHAR,
    anonimizado            BOOLEAN,
    activo                 BOOLEAN
)
LANGUAGE sql
STABLE
AS $$
    SELECT p.id, p.dni, p.nombres, p.apellidos, p.sexo, p.fecha_nacimiento,
           p.telefono, p.email, p.categoria, p.consentimiento_at,
           p.consentimiento_version, p.anonimizado, p.activo
    FROM persona p
    ORDER BY p.id;
$$;

CREATE OR REPLACE FUNCTION fn_persona_obtener(p_id BIGINT)
RETURNS TABLE (
    id                     BIGINT,
    dni                    VARCHAR,
    nombres                VARCHAR,
    apellidos              VARCHAR,
    sexo                   CHAR(1),
    fecha_nacimiento       DATE,
    telefono               VARCHAR,
    email                  VARCHAR,
    categoria              VARCHAR,
    consentimiento_at      TIMESTAMPTZ,
    consentimiento_version VARCHAR,
    anonimizado            BOOLEAN,
    activo                 BOOLEAN
)
LANGUAGE sql
STABLE
AS $$
    SELECT p.id, p.dni, p.nombres, p.apellidos, p.sexo, p.fecha_nacimiento,
           p.telefono, p.email, p.categoria, p.consentimiento_at,
           p.consentimiento_version, p.anonimizado, p.activo
    FROM persona p
    WHERE p.id = p_id;
$$;

CREATE OR REPLACE FUNCTION fn_persona_crear(
    p_dni                    VARCHAR,
    p_nombres                VARCHAR,
    p_apellidos              VARCHAR,
    p_sexo                   CHAR(1),
    p_fecha_nacimiento       DATE,
    p_telefono               VARCHAR,
    p_email                  VARCHAR,
    p_password_hash          TEXT,
    p_activo                 BOOLEAN,
    p_categoria              VARCHAR DEFAULT NULL,
    p_consentimiento_at      TIMESTAMPTZ DEFAULT NULL,
    p_consentimiento_version VARCHAR DEFAULT NULL
)
RETURNS BIGINT
LANGUAGE sql
AS $$
    INSERT INTO persona (
        dni, nombres, apellidos, sexo, fecha_nacimiento,
        telefono, email, password_hash, activo,
        categoria, consentimiento_at, consentimiento_version
    )
    VALUES (
        BTRIM(p_dni),
        BTRIM(p_nombres),
        BTRIM(p_apellidos),
        p_sexo,
        p_fecha_nacimiento,
        NULLIF(BTRIM(p_telefono), ''),
        LOWER(NULLIF(BTRIM(p_email), '')),
        p_password_hash,
        COALESCE(p_activo, TRUE),
        NULLIF(BTRIM(p_categoria), ''),
        p_consentimiento_at,
        NULLIF(BTRIM(p_consentimiento_version), '')
    )
    RETURNING id;
$$;

CREATE OR REPLACE FUNCTION fn_persona_registrar_capacitando(
    p_dni                    VARCHAR,
    p_nombres                VARCHAR,
    p_apellidos              VARCHAR,
    p_sexo                   CHAR(1),
    p_fecha_nacimiento       DATE,
    p_telefono               VARCHAR,
    p_email                  VARCHAR,
    p_password_hash          TEXT,
    p_categoria              VARCHAR,
    p_consentimiento_version VARCHAR DEFAULT 'v1.0-2026'
)
RETURNS BIGINT
LANGUAGE plpgsql
AS $$
DECLARE
    v_persona_id BIGINT;
    v_rol_id     SMALLINT;
BEGIN
    SELECT id INTO v_rol_id FROM rol WHERE nombre = 'capacitando';
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Rol capacitando no configurado' USING ERRCODE = 'P0002';
    END IF;

    INSERT INTO persona (
        dni, nombres, apellidos, sexo, fecha_nacimiento,
        telefono, email, password_hash, categoria,
        consentimiento_at, consentimiento_version, anonimizado, activo
    )
    VALUES (
        BTRIM(p_dni),
        BTRIM(p_nombres),
        BTRIM(p_apellidos),
        p_sexo,
        p_fecha_nacimiento,
        NULLIF(BTRIM(p_telefono), ''),
        LOWER(NULLIF(BTRIM(p_email), '')),
        p_password_hash,
        NULLIF(BTRIM(p_categoria), ''),
        NOW(),
        COALESCE(NULLIF(BTRIM(p_consentimiento_version), ''), 'v1.0-2026'),
        FALSE,
        TRUE
    )
    RETURNING id INTO v_persona_id;

    INSERT INTO persona_rol (persona_id, rol_id)
    VALUES (v_persona_id, v_rol_id)
    ON CONFLICT (persona_id, rol_id) DO NOTHING;

    RETURN v_persona_id;
END;
$$;

CREATE OR REPLACE FUNCTION fn_persona_actualizar(
    p_id               BIGINT,
    p_dni              VARCHAR,
    p_nombres          VARCHAR,
    p_apellidos        VARCHAR,
    p_sexo             CHAR(1),
    p_fecha_nacimiento DATE,
    p_telefono         VARCHAR,
    p_email            VARCHAR,
    p_categoria        VARCHAR DEFAULT NULL
)
RETURNS BOOLEAN
LANGUAGE plpgsql
AS $$
DECLARE
    v_anonimizado BOOLEAN;
BEGIN
    SELECT anonimizado INTO v_anonimizado FROM persona WHERE id = p_id;
    IF NOT FOUND THEN
        RETURN FALSE;
    END IF;

    IF v_anonimizado THEN
        RAISE EXCEPTION 'No se puede modificar una persona anonimizada' USING ERRCODE = 'P0001';
    END IF;

    UPDATE persona
    SET dni = BTRIM(p_dni),
        nombres = BTRIM(p_nombres),
        apellidos = BTRIM(p_apellidos),
        sexo = p_sexo,
        fecha_nacimiento = p_fecha_nacimiento,
        telefono = NULLIF(BTRIM(p_telefono), ''),
        email = LOWER(NULLIF(BTRIM(p_email), '')),
        categoria = COALESCE(NULLIF(BTRIM(p_categoria), ''), categoria)
    WHERE id = p_id;
    RETURN FOUND;
END;
$$;

CREATE OR REPLACE FUNCTION fn_persona_cambiar_activo(p_id BIGINT, p_activo BOOLEAN)
RETURNS BOOLEAN
LANGUAGE plpgsql
AS $$
DECLARE
    v_anonimizado BOOLEAN;
BEGIN
    SELECT anonimizado INTO v_anonimizado FROM persona WHERE id = p_id;
    IF NOT FOUND THEN
        RETURN FALSE;
    END IF;

    IF v_anonimizado THEN
        RAISE EXCEPTION 'No se puede activar o modificar una persona anonimizada' USING ERRCODE = 'P0001';
    END IF;

    UPDATE persona SET activo = p_activo WHERE id = p_id;
    RETURN FOUND;
END;
$$;

CREATE OR REPLACE FUNCTION fn_persona_cambiar_password(p_id BIGINT, p_password_hash TEXT)
RETURNS BOOLEAN
LANGUAGE plpgsql
AS $$
DECLARE
    v_anonimizado BOOLEAN;
BEGIN
    SELECT anonimizado INTO v_anonimizado FROM persona WHERE id = p_id;
    IF NOT FOUND THEN
        RETURN FALSE;
    END IF;

    IF v_anonimizado THEN
        RAISE EXCEPTION 'No se puede cambiar la contrasena de una persona anonimizada' USING ERRCODE = 'P0001';
    END IF;

    UPDATE persona SET password_hash = p_password_hash WHERE id = p_id;
    RETURN FOUND;
END;
$$;

CREATE OR REPLACE FUNCTION fn_persona_anonimizar_arco(p_id BIGINT)
RETURNS BOOLEAN
LANGUAGE plpgsql
AS $$
DECLARE
    v_anonimizado BOOLEAN;
BEGIN
    SELECT anonimizado INTO v_anonimizado FROM persona WHERE id = p_id FOR UPDATE;
    IF NOT FOUND THEN
        RETURN FALSE;
    END IF;

    IF v_anonimizado THEN
        RAISE EXCEPTION 'La persona ya se encuentra anonimizada' USING ERRCODE = 'P0001';
    END IF;

    IF EXISTS (
        SELECT 1
        FROM persona_rol pr
        JOIN rol r ON r.id = pr.rol_id
        WHERE pr.persona_id = p_id AND r.nombre = 'admin'
    ) THEN
        RAISE EXCEPTION 'No se puede anonimizar una cuenta con rol admin' USING ERRCODE = 'P0001';
    END IF;

    UPDATE persona
    SET dni = 'ANON_' || id::VARCHAR,
        nombres = 'ANONIMIZADO',
        apellidos = 'ANONIMIZADO',
        fecha_nacimiento = DATE '1900-01-01',
        telefono = NULL,
        email = NULL,
        password_hash = NULL,
        activo = FALSE,
        anonimizado = TRUE
    WHERE id = p_id;

    UPDATE promotor_periodo
    SET codigo_certificado = NULL,
        estado = 'RETIRADO'
    WHERE persona_id = p_id;

    UPDATE inscripcion i
    SET estado = 'CANCELADO'
    FROM sesion s
    WHERE i.sesion_id = s.id
      AND i.persona_id = p_id
      AND i.estado = 'INSCRITO'
      AND s.estado = 'PROGRAMADA';

    RETURN TRUE;
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
