-- ==============================================================================
-- Funciones: Sesion Educativa
-- ==============================================================================

CREATE OR REPLACE FUNCTION fn_sesion_listar(
    p_meta_anual_id BIGINT DEFAULT NULL,
    p_estado        VARCHAR DEFAULT NULL
)
RETURNS TABLE (
    id               BIGINT,
    meta_anual_id    BIGINT,
    organizacion_id  BIGINT,
    responsable_id   BIGINT,
    titulo           VARCHAR,
    modalidad        VARCHAR,
    fecha_inicio     TIMESTAMPTZ,
    duracion_minutos SMALLINT,
    estado           VARCHAR
)
LANGUAGE sql
STABLE
AS $$
    SELECT s.id, s.meta_anual_id, s.organizacion_id, s.responsable_id,
           s.titulo, s.modalidad, s.fecha_inicio, s.duracion_minutos, s.estado
    FROM sesion s
    WHERE (p_meta_anual_id IS NULL OR s.meta_anual_id = p_meta_anual_id)
      AND (p_estado IS NULL OR s.estado = p_estado)
    ORDER BY s.fecha_inicio DESC, s.id DESC;
$$;

CREATE OR REPLACE FUNCTION fn_sesion_obtener(p_id BIGINT)
RETURNS TABLE (
    id               BIGINT,
    meta_anual_id    BIGINT,
    organizacion_id  BIGINT,
    responsable_id   BIGINT,
    titulo           VARCHAR,
    modalidad        VARCHAR,
    fecha_inicio     TIMESTAMPTZ,
    duracion_minutos SMALLINT,
    estado           VARCHAR
)
LANGUAGE sql
STABLE
AS $$
    SELECT s.id, s.meta_anual_id, s.organizacion_id, s.responsable_id,
           s.titulo, s.modalidad, s.fecha_inicio, s.duracion_minutos, s.estado
    FROM sesion s
    WHERE s.id = p_id;
$$;

CREATE OR REPLACE FUNCTION fn_sesion_crear(
    p_meta_anual_id    BIGINT,
    p_organizacion_id  BIGINT,
    p_responsable_id   BIGINT,
    p_titulo           VARCHAR,
    p_modalidad        VARCHAR,
    p_fecha_inicio     TIMESTAMPTZ,
    p_duracion_minutos SMALLINT
)
RETURNS BIGINT
LANGUAGE sql
AS $$
    INSERT INTO sesion (meta_anual_id, organizacion_id, responsable_id, titulo, modalidad, fecha_inicio, duracion_minutos)
    VALUES (p_meta_anual_id, p_organizacion_id, p_responsable_id, p_titulo, p_modalidad, p_fecha_inicio, p_duracion_minutos)
    RETURNING id;
$$;

CREATE OR REPLACE FUNCTION fn_sesion_actualizar(
    p_id               BIGINT,
    p_meta_anual_id    BIGINT,
    p_organizacion_id  BIGINT,
    p_responsable_id   BIGINT,
    p_titulo           VARCHAR,
    p_modalidad        VARCHAR,
    p_fecha_inicio     TIMESTAMPTZ,
    p_duracion_minutos SMALLINT
)
RETURNS BOOLEAN
LANGUAGE plpgsql
AS $$
DECLARE
    v_estado VARCHAR(20);
BEGIN
    SELECT estado INTO v_estado FROM sesion WHERE id = p_id;
    IF NOT FOUND THEN
        RETURN FALSE;
    END IF;

    IF v_estado IN ('VALIDADA', 'CANCELADA') THEN
        RAISE EXCEPTION 'No se puede modificar una sesion en estado %', v_estado USING ERRCODE = 'P0001';
    END IF;

    UPDATE sesion
    SET meta_anual_id = p_meta_anual_id,
        organizacion_id = p_organizacion_id,
        responsable_id = p_responsable_id,
        titulo = p_titulo,
        modalidad = p_modalidad,
        fecha_inicio = p_fecha_inicio,
        duracion_minutos = p_duracion_minutos
    WHERE id = p_id;
    RETURN TRUE;
END;
$$;

CREATE OR REPLACE FUNCTION fn_sesion_cambiar_estado(p_id BIGINT, p_nuevo_estado VARCHAR)
RETURNS BOOLEAN
LANGUAGE plpgsql
AS $$
DECLARE
    v_estado VARCHAR(20);
BEGIN
    SELECT estado INTO v_estado FROM sesion WHERE id = p_id;
    IF NOT FOUND THEN
        RETURN FALSE;
    END IF;

    IF NOT (
        (v_estado = 'PROGRAMADA' AND p_nuevo_estado IN ('EJECUTADA', 'CANCELADA')) OR
        (v_estado = 'EJECUTADA' AND p_nuevo_estado IN ('VALIDADA', 'CANCELADA'))
    ) THEN
        RAISE EXCEPTION 'Transicion de estado invalida: % -> %', v_estado, p_nuevo_estado USING ERRCODE = 'P0001';
    END IF;

    UPDATE sesion SET estado = p_nuevo_estado WHERE id = p_id;
    RETURN TRUE;
END;
$$;

CREATE OR REPLACE FUNCTION fn_sesion_eliminar(p_id BIGINT)
RETURNS BOOLEAN
LANGUAGE plpgsql
AS $$
BEGIN
    DELETE FROM sesion WHERE id = p_id;
    RETURN FOUND;
END;
$$;
