-- ==============================================================================
-- Funciones: Asistencia Manual, Check-in QR + GPS e Historial del Capacitando
-- ==============================================================================

CREATE OR REPLACE FUNCTION fn_asistencia_listar_por_sesion(p_sesion_id BIGINT)
RETURNS TABLE (
    sesion_id        BIGINT,
    persona_id       BIGINT,
    participacion    VARCHAR,
    calificacion     NUMERIC,
    metodo_registro  VARCHAR,
    distancia_metros NUMERIC,
    registrado_at    TIMESTAMPTZ
)
LANGUAGE plpgsql
STABLE
AS $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM sesion s WHERE s.id = p_sesion_id) THEN
        RAISE EXCEPTION 'Sesion no encontrada' USING ERRCODE = 'P0002';
    END IF;

    RETURN QUERY
    SELECT a.sesion_id, a.persona_id, a.participacion, a.calificacion,
           a.metodo_registro, a.distancia_metros, a.registrado_at
    FROM asistencia a
    WHERE a.sesion_id = p_sesion_id
    ORDER BY a.registrado_at ASC, a.persona_id ASC;
END;
$$;

CREATE OR REPLACE FUNCTION fn_asistencia_registrar(
    p_sesion_id     BIGINT,
    p_persona_id    BIGINT,
    p_participacion VARCHAR,
    p_calificacion  NUMERIC
)
RETURNS VOID
LANGUAGE plpgsql
AS $$
DECLARE
    v_estado VARCHAR(20);
BEGIN
    SELECT estado INTO v_estado FROM sesion WHERE id = p_sesion_id;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Sesion no encontrada' USING ERRCODE = 'P0002';
    END IF;

    IF v_estado IN ('VALIDADA', 'CANCELADA') THEN
        RAISE EXCEPTION 'No se puede registrar asistencia en una sesion en estado %', v_estado USING ERRCODE = 'P0001';
    END IF;

    INSERT INTO asistencia (sesion_id, persona_id, participacion, calificacion, metodo_registro, registrado_at)
    VALUES (p_sesion_id, p_persona_id, COALESCE(NULLIF(BTRIM(p_participacion), ''), 'ASISTENTE'), p_calificacion, 'MANUAL', NOW())
    ON CONFLICT (sesion_id, persona_id) DO UPDATE SET
        participacion = COALESCE(NULLIF(BTRIM(EXCLUDED.participacion), ''), asistencia.participacion),
        calificacion = EXCLUDED.calificacion;
END;
$$;

CREATE OR REPLACE FUNCTION fn_asistencia_checkin_qr(
    p_sesion_id        BIGINT,
    p_persona_id       BIGINT,
    p_distancia_metros NUMERIC
)
RETURNS VOID
LANGUAGE plpgsql
AS $$
DECLARE
    v_estado      VARCHAR(20);
    v_modalidad   VARCHAR(15);
    v_cupo_maximo INTEGER;
    v_inscritos   INTEGER;
BEGIN
    SELECT estado, modalidad, cupo_maximo
    INTO v_estado, v_modalidad, v_cupo_maximo
    FROM sesion
    WHERE id = p_sesion_id
    FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Sesion no encontrada' USING ERRCODE = 'P0002';
    END IF;

    IF v_modalidad <> 'PRESENCIAL' THEN
        RAISE EXCEPTION 'El check-in con QR y GPS solo aplica a sesiones presenciales' USING ERRCODE = 'P0001';
    END IF;

    IF v_estado IN ('VALIDADA', 'CANCELADA') THEN
        RAISE EXCEPTION 'No se puede registrar asistencia en una sesion en estado %', v_estado USING ERRCODE = 'P0001';
    END IF;

    IF EXISTS (
        SELECT 1 FROM asistencia
        WHERE sesion_id = p_sesion_id AND persona_id = p_persona_id
    ) THEN
        RAISE EXCEPTION 'La asistencia ya fue registrada para esta sesion' USING ERRCODE = '23505';
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM inscripcion
        WHERE sesion_id = p_sesion_id AND persona_id = p_persona_id AND estado = 'INSCRITO'
    ) THEN
        SELECT COUNT(*)::INTEGER INTO v_inscritos
        FROM inscripcion
        WHERE sesion_id = p_sesion_id AND estado = 'INSCRITO';

        IF v_inscritos >= v_cupo_maximo THEN
            RAISE EXCEPTION 'No hay cupos disponibles en esta sesion para registrar nuevos participantes' USING ERRCODE = 'P0001';
        END IF;

        INSERT INTO inscripcion (sesion_id, persona_id, estado, created_at)
        VALUES (p_sesion_id, p_persona_id, 'INSCRITO', NOW())
        ON CONFLICT (sesion_id, persona_id) DO UPDATE SET
            estado = 'INSCRITO',
            created_at = NOW();
    END IF;

    INSERT INTO asistencia (
        sesion_id, persona_id, participacion, calificacion,
        metodo_registro, distancia_metros, registrado_at
    )
    VALUES (
        p_sesion_id,
        p_persona_id,
        'ASISTENTE',
        NULL,
        'QR_GPS',
        ROUND(p_distancia_metros, 2),
        NOW()
    );
END;
$$;

CREATE OR REPLACE FUNCTION fn_asistencia_listar_por_persona(p_persona_id BIGINT)
RETURNS TABLE (
    sesion_id        BIGINT,
    titulo           VARCHAR,
    eje_tematico     VARCHAR,
    modalidad        VARCHAR,
    fecha_inicio     TIMESTAMPTZ,
    estado_sesion    VARCHAR,
    participacion    VARCHAR,
    calificacion     NUMERIC,
    metodo_registro  VARCHAR,
    distancia_metros NUMERIC,
    registrado_at    TIMESTAMPTZ
)
LANGUAGE sql
STABLE
AS $$
    SELECT a.sesion_id,
           s.titulo,
           s.eje_tematico,
           s.modalidad,
           s.fecha_inicio,
           s.estado AS estado_sesion,
           a.participacion,
           a.calificacion,
           a.metodo_registro,
           a.distancia_metros,
           a.registrado_at
    FROM asistencia a
    JOIN sesion s ON s.id = a.sesion_id
    WHERE a.persona_id = p_persona_id
    ORDER BY s.fecha_inicio DESC, s.id DESC;
$$;

CREATE OR REPLACE FUNCTION fn_asistencia_eliminar(p_sesion_id BIGINT, p_persona_id BIGINT)
RETURNS BOOLEAN
LANGUAGE plpgsql
AS $$
DECLARE
    v_estado VARCHAR(20);
BEGIN
    SELECT estado INTO v_estado FROM sesion WHERE id = p_sesion_id;
    IF NOT FOUND THEN
        RETURN FALSE;
    END IF;

    IF v_estado IN ('VALIDADA', 'CANCELADA') THEN
        RAISE EXCEPTION 'No se puede eliminar asistencia de una sesion en estado %', v_estado USING ERRCODE = 'P0001';
    END IF;

    DELETE FROM asistencia WHERE sesion_id = p_sesion_id AND persona_id = p_persona_id;
    RETURN FOUND;
END;
$$;
