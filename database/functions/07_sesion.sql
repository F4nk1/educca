-- ==============================================================================
-- Funciones: Sesion Educativa, Solapamiento Horario y Cupos
-- ==============================================================================

CREATE OR REPLACE FUNCTION fn_sesion_listar(
    p_meta_anual_id   BIGINT DEFAULT NULL,
    p_estado          VARCHAR DEFAULT NULL,
    p_eje_tematico    VARCHAR DEFAULT NULL,
    p_organizacion_id BIGINT DEFAULT NULL
)
RETURNS TABLE (
    id                 BIGINT,
    meta_anual_id      BIGINT,
    organizacion_id    BIGINT,
    responsable_id     BIGINT,
    titulo             VARCHAR,
    modalidad          VARCHAR,
    eje_tematico       VARCHAR,
    fecha_inicio       TIMESTAMPTZ,
    duracion_minutos   SMALLINT,
    cupo_maximo        INTEGER,
    inscritos_actuales INTEGER,
    cupos_disponibles  INTEGER,
    estado             VARCHAR
)
LANGUAGE sql
STABLE
AS $$
    SELECT s.id,
           s.meta_anual_id,
           s.organizacion_id,
           s.responsable_id,
           s.titulo,
           s.modalidad,
           s.eje_tematico,
           s.fecha_inicio,
           s.duracion_minutos,
           s.cupo_maximo,
           COALESCE(ic.inscritos, 0)::INTEGER AS inscritos_actuales,
           GREATEST(s.cupo_maximo - COALESCE(ic.inscritos, 0), 0)::INTEGER AS cupos_disponibles,
           s.estado
    FROM sesion s
    LEFT JOIN (
        SELECT sesion_id, COUNT(*)::INTEGER AS inscritos
        FROM inscripcion
        WHERE estado = 'INSCRITO'
        GROUP BY sesion_id
    ) ic ON ic.sesion_id = s.id
    WHERE (p_meta_anual_id IS NULL OR s.meta_anual_id = p_meta_anual_id)
      AND (p_estado IS NULL OR s.estado = p_estado)
      AND (p_eje_tematico IS NULL OR s.eje_tematico = p_eje_tematico)
      AND (p_organizacion_id IS NULL OR s.organizacion_id = p_organizacion_id)
    ORDER BY s.fecha_inicio DESC, s.id DESC;
$$;

CREATE OR REPLACE FUNCTION fn_sesion_obtener(p_id BIGINT)
RETURNS TABLE (
    id                 BIGINT,
    meta_anual_id      BIGINT,
    organizacion_id    BIGINT,
    responsable_id     BIGINT,
    titulo             VARCHAR,
    modalidad          VARCHAR,
    eje_tematico       VARCHAR,
    fecha_inicio       TIMESTAMPTZ,
    duracion_minutos   SMALLINT,
    cupo_maximo        INTEGER,
    inscritos_actuales INTEGER,
    cupos_disponibles  INTEGER,
    estado             VARCHAR
)
LANGUAGE sql
STABLE
AS $$
    SELECT s.id,
           s.meta_anual_id,
           s.organizacion_id,
           s.responsable_id,
           s.titulo,
           s.modalidad,
           s.eje_tematico,
           s.fecha_inicio,
           s.duracion_minutos,
           s.cupo_maximo,
           COALESCE(ic.inscritos, 0)::INTEGER AS inscritos_actuales,
           GREATEST(s.cupo_maximo - COALESCE(ic.inscritos, 0), 0)::INTEGER AS cupos_disponibles,
           s.estado
    FROM sesion s
    LEFT JOIN (
        SELECT sesion_id, COUNT(*)::INTEGER AS inscritos
        FROM inscripcion
        WHERE estado = 'INSCRITO'
        GROUP BY sesion_id
    ) ic ON ic.sesion_id = s.id
    WHERE s.id = p_id;
$$;

CREATE OR REPLACE FUNCTION fn_sesion_crear(
    p_meta_anual_id    BIGINT,
    p_organizacion_id  BIGINT,
    p_responsable_id   BIGINT,
    p_titulo           VARCHAR,
    p_modalidad        VARCHAR,
    p_eje_tematico     VARCHAR,
    p_fecha_inicio     TIMESTAMPTZ,
    p_duracion_minutos SMALLINT,
    p_cupo_maximo      INTEGER DEFAULT 50
)
RETURNS BIGINT
LANGUAGE plpgsql
AS $$
DECLARE
    v_fecha_fin TIMESTAMPTZ;
    v_id        BIGINT;
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM persona p
        WHERE p.id = p_responsable_id AND p.activo = TRUE AND p.anonimizado = FALSE
    ) THEN
        RAISE EXCEPTION 'El capacitador responsable no existe o no se encuentra activo' USING ERRCODE = 'P0001';
    END IF;

    v_fecha_fin := p_fecha_inicio + (p_duracion_minutos * INTERVAL '1 minute');

    IF p_organizacion_id IS NOT NULL AND EXISTS (
        SELECT 1 FROM sesion s
        WHERE s.organizacion_id = p_organizacion_id
          AND s.estado <> 'CANCELADA'
          AND p_fecha_inicio < (s.fecha_inicio + (s.duracion_minutos * INTERVAL '1 minute'))
          AND s.fecha_inicio < v_fecha_fin
    ) THEN
        RAISE EXCEPTION 'Solapamiento horario: ya existe una sesion programada en la misma sede durante ese horario' USING ERRCODE = 'P0001';
    END IF;

    IF EXISTS (
        SELECT 1 FROM sesion s
        WHERE s.responsable_id = p_responsable_id
          AND s.estado <> 'CANCELADA'
          AND p_fecha_inicio < (s.fecha_inicio + (s.duracion_minutos * INTERVAL '1 minute'))
          AND s.fecha_inicio < v_fecha_fin
    ) THEN
        RAISE EXCEPTION 'Solapamiento horario: el capacitador ya tiene otra sesion asignada durante ese horario' USING ERRCODE = 'P0001';
    END IF;

    INSERT INTO sesion (
        meta_anual_id, organizacion_id, responsable_id,
        titulo, modalidad, eje_tematico,
        fecha_inicio, duracion_minutos, cupo_maximo
    )
    VALUES (
        p_meta_anual_id,
        p_organizacion_id,
        p_responsable_id,
        BTRIM(p_titulo),
        p_modalidad,
        COALESCE(NULLIF(BTRIM(p_eje_tematico), ''), 'SEGREGACION_RECICLA'),
        p_fecha_inicio,
        p_duracion_minutos,
        COALESCE(NULLIF(p_cupo_maximo, 0), 50)
    )
    RETURNING id INTO v_id;

    RETURN v_id;
END;
$$;

CREATE OR REPLACE FUNCTION fn_sesion_actualizar(
    p_id               BIGINT,
    p_meta_anual_id    BIGINT,
    p_organizacion_id  BIGINT,
    p_responsable_id   BIGINT,
    p_titulo           VARCHAR,
    p_modalidad        VARCHAR,
    p_eje_tematico     VARCHAR,
    p_fecha_inicio     TIMESTAMPTZ,
    p_duracion_minutos SMALLINT,
    p_cupo_maximo      INTEGER DEFAULT 50
)
RETURNS BOOLEAN
LANGUAGE plpgsql
AS $$
DECLARE
    v_estado     VARCHAR(20);
    v_fecha_fin  TIMESTAMPTZ;
    v_cupo_final INTEGER;
    v_inscritos  INTEGER;
BEGIN
    SELECT estado INTO v_estado FROM sesion WHERE id = p_id FOR UPDATE;
    IF NOT FOUND THEN
        RETURN FALSE;
    END IF;

    IF v_estado IN ('VALIDADA', 'CANCELADA') THEN
        RAISE EXCEPTION 'No se puede modificar una sesion en estado %', v_estado USING ERRCODE = 'P0001';
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM persona p
        WHERE p.id = p_responsable_id AND p.activo = TRUE AND p.anonimizado = FALSE
    ) THEN
        RAISE EXCEPTION 'El capacitador responsable no existe o no se encuentra activo' USING ERRCODE = 'P0001';
    END IF;

    v_cupo_final := COALESCE(NULLIF(p_cupo_maximo, 0), 50);
    SELECT COUNT(*)::INTEGER INTO v_inscritos
    FROM inscripcion
    WHERE sesion_id = p_id AND estado = 'INSCRITO';

    IF v_cupo_final < v_inscritos THEN
        RAISE EXCEPTION 'El cupo maximo (%) no puede ser menor al numero actual de inscritos (%)', v_cupo_final, v_inscritos USING ERRCODE = 'P0001';
    END IF;

    v_fecha_fin := p_fecha_inicio + (p_duracion_minutos * INTERVAL '1 minute');

    IF p_organizacion_id IS NOT NULL AND EXISTS (
        SELECT 1 FROM sesion s
        WHERE s.organizacion_id = p_organizacion_id
          AND s.id <> p_id
          AND s.estado <> 'CANCELADA'
          AND p_fecha_inicio < (s.fecha_inicio + (s.duracion_minutos * INTERVAL '1 minute'))
          AND s.fecha_inicio < v_fecha_fin
    ) THEN
        RAISE EXCEPTION 'Solapamiento horario: ya existe una sesion programada en la misma sede durante ese horario' USING ERRCODE = 'P0001';
    END IF;

    IF EXISTS (
        SELECT 1 FROM sesion s
        WHERE s.responsable_id = p_responsable_id
          AND s.id <> p_id
          AND s.estado <> 'CANCELADA'
          AND p_fecha_inicio < (s.fecha_inicio + (s.duracion_minutos * INTERVAL '1 minute'))
          AND s.fecha_inicio < v_fecha_fin
    ) THEN
        RAISE EXCEPTION 'Solapamiento horario: el capacitador ya tiene otra sesion asignada durante ese horario' USING ERRCODE = 'P0001';
    END IF;

    UPDATE sesion
    SET meta_anual_id = p_meta_anual_id,
        organizacion_id = p_organizacion_id,
        responsable_id = p_responsable_id,
        titulo = BTRIM(p_titulo),
        modalidad = p_modalidad,
        eje_tematico = COALESCE(NULLIF(BTRIM(p_eje_tematico), ''), eje_tematico),
        fecha_inicio = p_fecha_inicio,
        duracion_minutos = p_duracion_minutos,
        cupo_maximo = v_cupo_final
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
DECLARE
    v_estado VARCHAR(20);
BEGIN
    SELECT estado INTO v_estado FROM sesion WHERE id = p_id;
    IF NOT FOUND THEN
        RETURN FALSE;
    END IF;

    IF v_estado IN ('VALIDADA', 'CANCELADA') THEN
        RAISE EXCEPTION 'No se puede eliminar una sesion en estado %', v_estado USING ERRCODE = 'P0001';
    END IF;

    DELETE FROM sesion WHERE id = p_id;
    RETURN TRUE;
END;
$$;
