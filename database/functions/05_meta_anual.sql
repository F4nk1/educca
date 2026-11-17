-- ==============================================================================
-- Funciones: Meta Anual
-- ==============================================================================

CREATE OR REPLACE FUNCTION fn_meta_anual_listar(p_anio SMALLINT DEFAULT NULL)
RETURNS TABLE (
    id              BIGINT,
    anio            SMALLINT,
    actividad_minam VARCHAR,
    indicador       VARCHAR,
    meta_programada INTEGER,
    presupuesto     NUMERIC
)
LANGUAGE sql
STABLE
AS $$
    SELECT m.id, m.anio, m.actividad_minam, m.indicador, m.meta_programada, m.presupuesto
    FROM meta_anual m
    WHERE p_anio IS NULL OR m.anio = p_anio
    ORDER BY m.anio DESC, m.id;
$$;

CREATE OR REPLACE FUNCTION fn_meta_anual_obtener(p_id BIGINT)
RETURNS TABLE (
    id              BIGINT,
    anio            SMALLINT,
    actividad_minam VARCHAR,
    indicador       VARCHAR,
    meta_programada INTEGER,
    presupuesto     NUMERIC
)
LANGUAGE sql
STABLE
AS $$
    SELECT m.id, m.anio, m.actividad_minam, m.indicador, m.meta_programada, m.presupuesto
    FROM meta_anual m
    WHERE m.id = p_id;
$$;

CREATE OR REPLACE FUNCTION fn_meta_anual_crear(
    p_anio            SMALLINT,
    p_actividad_minam VARCHAR,
    p_indicador       VARCHAR,
    p_meta_programada INTEGER,
    p_presupuesto     NUMERIC
)
RETURNS BIGINT
LANGUAGE sql
AS $$
    INSERT INTO meta_anual (anio, actividad_minam, indicador, meta_programada, presupuesto)
    VALUES (p_anio, p_actividad_minam, p_indicador, p_meta_programada, p_presupuesto)
    RETURNING id;
$$;

CREATE OR REPLACE FUNCTION fn_meta_anual_actualizar(
    p_id              BIGINT,
    p_anio            SMALLINT,
    p_actividad_minam VARCHAR,
    p_indicador       VARCHAR,
    p_meta_programada INTEGER,
    p_presupuesto     NUMERIC
)
RETURNS BOOLEAN
LANGUAGE plpgsql
AS $$
BEGIN
    UPDATE meta_anual
    SET anio = p_anio,
        actividad_minam = p_actividad_minam,
        indicador = p_indicador,
        meta_programada = p_meta_programada,
        presupuesto = p_presupuesto
    WHERE id = p_id;
    RETURN FOUND;
END;
$$;

CREATE OR REPLACE FUNCTION fn_meta_anual_eliminar(p_id BIGINT)
RETURNS BOOLEAN
LANGUAGE plpgsql
AS $$
BEGIN
    DELETE FROM meta_anual WHERE id = p_id;
    RETURN FOUND;
END;
$$;
