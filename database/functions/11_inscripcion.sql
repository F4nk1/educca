-- ==============================================================================
-- Funciones: Inscripcion de Capacitandos a Sesiones
-- ==============================================================================

CREATE OR REPLACE FUNCTION fn_inscripcion_crear(
    p_sesion_id  BIGINT,
    p_persona_id BIGINT
)
RETURNS BIGINT
LANGUAGE plpgsql
AS $$
DECLARE
    v_estado      VARCHAR(20);
    v_cupo_maximo INTEGER;
    v_inscritos   INTEGER;
    v_id          BIGINT;
BEGIN
    SELECT estado, cupo_maximo
    INTO v_estado, v_cupo_maximo
    FROM sesion
    WHERE id = p_sesion_id
    FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Sesion no encontrada' USING ERRCODE = 'P0002';
    END IF;

    IF v_estado <> 'PROGRAMADA' THEN
        RAISE EXCEPTION 'Solo se permite la inscripcion en sesiones con estado PROGRAMADA' USING ERRCODE = 'P0001';
    END IF;

    IF EXISTS (
        SELECT 1 FROM inscripcion
        WHERE sesion_id = p_sesion_id AND persona_id = p_persona_id AND estado = 'INSCRITO'
    ) THEN
        RAISE EXCEPTION 'El usuario ya se encuentra inscrito en esta sesion' USING ERRCODE = '23505';
    END IF;

    SELECT COUNT(*)::INTEGER INTO v_inscritos
    FROM inscripcion
    WHERE sesion_id = p_sesion_id AND estado = 'INSCRITO';

    IF v_inscritos >= v_cupo_maximo THEN
        RAISE EXCEPTION 'La sesion ha alcanzado el cupo maximo permitido (%)' , v_cupo_maximo USING ERRCODE = 'P0001';
    END IF;

    INSERT INTO inscripcion (sesion_id, persona_id, estado, created_at)
    VALUES (p_sesion_id, p_persona_id, 'INSCRITO', NOW())
    ON CONFLICT (sesion_id, persona_id) DO UPDATE SET
        estado = 'INSCRITO',
        created_at = NOW()
    RETURNING id INTO v_id;

    RETURN v_id;
END;
$$;

CREATE OR REPLACE FUNCTION fn_inscripcion_cancelar(
    p_sesion_id  BIGINT,
    p_persona_id BIGINT
)
RETURNS BOOLEAN
LANGUAGE plpgsql
AS $$
DECLARE
    v_estado_sesion VARCHAR(20);
    v_fecha_inicio  TIMESTAMPTZ;
    v_estado_insc   VARCHAR(15);
BEGIN
    SELECT estado, fecha_inicio
    INTO v_estado_sesion, v_fecha_inicio
    FROM sesion
    WHERE id = p_sesion_id
    FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Sesion no encontrada' USING ERRCODE = 'P0002';
    END IF;

    SELECT estado INTO v_estado_insc
    FROM inscripcion
    WHERE sesion_id = p_sesion_id AND persona_id = p_persona_id;

    IF NOT FOUND OR v_estado_insc = 'CANCELADO' THEN
        RETURN FALSE;
    END IF;

    IF v_estado_sesion <> 'PROGRAMADA' OR NOW() >= v_fecha_inicio THEN
        RAISE EXCEPTION 'Solo se puede cancelar la inscripcion antes del inicio de una sesion PROGRAMADA' USING ERRCODE = 'P0001';
    END IF;

    UPDATE inscripcion
    SET estado = 'CANCELADO'
    WHERE sesion_id = p_sesion_id AND persona_id = p_persona_id;

    RETURN TRUE;
END;
$$;

CREATE OR REPLACE FUNCTION fn_inscripcion_listar_por_sesion(p_sesion_id BIGINT)
RETURNS TABLE (
    id         BIGINT,
    sesion_id  BIGINT,
    persona_id BIGINT,
    dni        VARCHAR,
    nombres    VARCHAR,
    apellidos  VARCHAR,
    categoria  VARCHAR,
    estado     VARCHAR,
    created_at TIMESTAMPTZ
)
LANGUAGE plpgsql
STABLE
AS $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM sesion s WHERE s.id = p_sesion_id) THEN
        RAISE EXCEPTION 'Sesion no encontrada' USING ERRCODE = 'P0002';
    END IF;

    RETURN QUERY
    SELECT i.id,
           i.sesion_id,
           i.persona_id,
           p.dni,
           p.nombres,
           p.apellidos,
           p.categoria,
           i.estado,
           i.created_at
    FROM inscripcion i
    JOIN persona p ON p.id = i.persona_id
    WHERE i.sesion_id = p_sesion_id
    ORDER BY i.created_at ASC, i.id ASC;
END;
$$;

CREATE OR REPLACE FUNCTION fn_inscripcion_listar_por_persona(p_persona_id BIGINT)
RETURNS TABLE (
    id               BIGINT,
    sesion_id        BIGINT,
    titulo           VARCHAR,
    eje_tematico     VARCHAR,
    modalidad        VARCHAR,
    fecha_inicio     TIMESTAMPTZ,
    duracion_minutos SMALLINT,
    organizacion_id  BIGINT,
    estado_sesion    VARCHAR,
    estado           VARCHAR,
    created_at       TIMESTAMPTZ
)
LANGUAGE sql
STABLE
AS $$
    SELECT i.id,
           i.sesion_id,
           s.titulo,
           s.eje_tematico,
           s.modalidad,
           s.fecha_inicio,
           s.duracion_minutos,
           s.organizacion_id,
           s.estado AS estado_sesion,
           i.estado,
           i.created_at
    FROM inscripcion i
    JOIN sesion s ON s.id = i.sesion_id
    WHERE i.persona_id = p_persona_id
    ORDER BY s.fecha_inicio DESC, i.id DESC;
$$;
