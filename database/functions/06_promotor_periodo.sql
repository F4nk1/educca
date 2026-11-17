-- ==============================================================================
-- Funciones: Promotor por Periodo
-- ==============================================================================

CREATE OR REPLACE FUNCTION fn_promotor_periodo_listar(p_anio SMALLINT DEFAULT NULL)
RETURNS TABLE (
    id                 BIGINT,
    persona_id         BIGINT,
    anio               SMALLINT,
    tipo_promotor      VARCHAR,
    organizacion_id    BIGINT,
    estado             VARCHAR,
    codigo_certificado VARCHAR
)
LANGUAGE sql
STABLE
AS $$
    SELECT pp.id, pp.persona_id, pp.anio, pp.tipo_promotor, pp.organizacion_id, pp.estado, pp.codigo_certificado
    FROM promotor_periodo pp
    WHERE p_anio IS NULL OR pp.anio = p_anio
    ORDER BY pp.anio DESC, pp.id;
$$;

CREATE OR REPLACE FUNCTION fn_promotor_periodo_obtener(p_id BIGINT)
RETURNS TABLE (
    id                 BIGINT,
    persona_id         BIGINT,
    anio               SMALLINT,
    tipo_promotor      VARCHAR,
    organizacion_id    BIGINT,
    estado             VARCHAR,
    codigo_certificado VARCHAR
)
LANGUAGE sql
STABLE
AS $$
    SELECT pp.id, pp.persona_id, pp.anio, pp.tipo_promotor, pp.organizacion_id, pp.estado, pp.codigo_certificado
    FROM promotor_periodo pp
    WHERE pp.id = p_id;
$$;

CREATE OR REPLACE FUNCTION fn_promotor_periodo_crear(
    p_persona_id         BIGINT,
    p_anio               SMALLINT,
    p_tipo_promotor      VARCHAR,
    p_organizacion_id    BIGINT,
    p_estado             VARCHAR,
    p_codigo_certificado VARCHAR
)
RETURNS BIGINT
LANGUAGE sql
AS $$
    INSERT INTO promotor_periodo (persona_id, anio, tipo_promotor, organizacion_id, estado, codigo_certificado)
    VALUES (p_persona_id, p_anio, p_tipo_promotor, p_organizacion_id, COALESCE(p_estado, 'INSCRITO'), p_codigo_certificado)
    RETURNING id;
$$;

CREATE OR REPLACE FUNCTION fn_promotor_periodo_actualizar(
    p_id                 BIGINT,
    p_persona_id         BIGINT,
    p_anio               SMALLINT,
    p_tipo_promotor      VARCHAR,
    p_organizacion_id    BIGINT,
    p_estado             VARCHAR,
    p_codigo_certificado VARCHAR
)
RETURNS BOOLEAN
LANGUAGE plpgsql
AS $$
BEGIN
    UPDATE promotor_periodo
    SET persona_id = p_persona_id,
        anio = p_anio,
        tipo_promotor = p_tipo_promotor,
        organizacion_id = p_organizacion_id,
        estado = p_estado,
        codigo_certificado = p_codigo_certificado
    WHERE id = p_id;
    RETURN FOUND;
END;
$$;

CREATE OR REPLACE FUNCTION fn_promotor_periodo_eliminar(p_id BIGINT)
RETURNS BOOLEAN
LANGUAGE plpgsql
AS $$
BEGIN
    DELETE FROM promotor_periodo WHERE id = p_id;
    RETURN FOUND;
END;
$$;
