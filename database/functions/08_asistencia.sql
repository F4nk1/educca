-- ==============================================================================
-- Funciones: Asistencia
-- ==============================================================================

CREATE OR REPLACE FUNCTION fn_asistencia_listar_por_sesion(p_sesion_id BIGINT)
RETURNS TABLE (
    sesion_id     BIGINT,
    persona_id    BIGINT,
    participacion VARCHAR,
    calificacion  NUMERIC
)
LANGUAGE sql
STABLE
AS $$
    SELECT a.sesion_id, a.persona_id, a.participacion, a.calificacion
    FROM asistencia a
    WHERE a.sesion_id = p_sesion_id
    ORDER BY a.persona_id;
$$;

CREATE OR REPLACE FUNCTION fn_asistencia_registrar(
    p_sesion_id     BIGINT,
    p_persona_id    BIGINT,
    p_participacion VARCHAR,
    p_calificacion  NUMERIC
)
RETURNS VOID
LANGUAGE sql
AS $$
    INSERT INTO asistencia (sesion_id, persona_id, participacion, calificacion)
    VALUES (p_sesion_id, p_persona_id, COALESCE(p_participacion, 'ASISTENTE'), p_calificacion)
    ON CONFLICT (sesion_id, persona_id) DO UPDATE SET
        participacion = EXCLUDED.participacion,
        calificacion = EXCLUDED.calificacion;
$$;

CREATE OR REPLACE FUNCTION fn_asistencia_eliminar(p_sesion_id BIGINT, p_persona_id BIGINT)
RETURNS BOOLEAN
LANGUAGE plpgsql
AS $$
BEGIN
    DELETE FROM asistencia WHERE sesion_id = p_sesion_id AND persona_id = p_persona_id;
    RETURN FOUND;
END;
$$;
