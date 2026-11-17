-- ==============================================================================
-- Funciones: Reportes consolidados EDUCCA
-- ==============================================================================

CREATE OR REPLACE FUNCTION fn_reporte_avance_metas(p_anio SMALLINT DEFAULT NULL)
RETURNS TABLE (
    meta_anual_id        BIGINT,
    anio                 SMALLINT,
    actividad_minam      VARCHAR,
    indicador            VARCHAR,
    meta_programada      INTEGER,
    presupuesto          NUMERIC,
    sesiones_programadas BIGINT,
    sesiones_ejecutadas  BIGINT,
    sesiones_validadas   BIGINT,
    total_asistentes     BIGINT
)
LANGUAGE sql
STABLE
AS $$
    SELECT
        m.id AS meta_anual_id,
        m.anio,
        m.actividad_minam,
        m.indicador,
        m.meta_programada,
        m.presupuesto,
        COUNT(DISTINCT s.id) FILTER (WHERE s.estado = 'PROGRAMADA') AS sesiones_programadas,
        COUNT(DISTINCT s.id) FILTER (WHERE s.estado = 'EJECUTADA') AS sesiones_ejecutadas,
        COUNT(DISTINCT s.id) FILTER (WHERE s.estado = 'VALIDADA') AS sesiones_validadas,
        COUNT(a.persona_id) FILTER (WHERE s.estado IN ('EJECUTADA', 'VALIDADA')) AS total_asistentes
    FROM meta_anual m
    LEFT JOIN sesion s ON s.meta_anual_id = m.id
    LEFT JOIN asistencia a ON a.sesion_id = s.id
    WHERE p_anio IS NULL OR m.anio = p_anio
    GROUP BY m.id, m.anio, m.actividad_minam, m.indicador, m.meta_programada, m.presupuesto
    ORDER BY m.anio DESC, m.actividad_minam, m.id;
$$;
