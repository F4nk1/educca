-- ==============================================================================
-- Funciones: Organizacion
-- ==============================================================================

CREATE OR REPLACE FUNCTION fn_organizacion_listar()
RETURNS TABLE (
    id                   BIGINT,
    nombre               VARCHAR,
    tipo                 VARCHAR,
    codigo_modular_o_ref VARCHAR,
    sector_ubicacion     VARCHAR,
    responsable_id       BIGINT
)
LANGUAGE sql
STABLE
AS $$
    SELECT o.id, o.nombre, o.tipo, o.codigo_modular_o_ref, o.sector_ubicacion, o.responsable_id
    FROM organizacion o
    ORDER BY o.id;
$$;

CREATE OR REPLACE FUNCTION fn_organizacion_obtener(p_id BIGINT)
RETURNS TABLE (
    id                   BIGINT,
    nombre               VARCHAR,
    tipo                 VARCHAR,
    codigo_modular_o_ref VARCHAR,
    sector_ubicacion     VARCHAR,
    responsable_id       BIGINT
)
LANGUAGE sql
STABLE
AS $$
    SELECT o.id, o.nombre, o.tipo, o.codigo_modular_o_ref, o.sector_ubicacion, o.responsable_id
    FROM organizacion o
    WHERE o.id = p_id;
$$;

CREATE OR REPLACE FUNCTION fn_organizacion_crear(
    p_nombre               VARCHAR,
    p_tipo                 VARCHAR,
    p_codigo_modular_o_ref VARCHAR,
    p_sector_ubicacion     VARCHAR,
    p_responsable_id       BIGINT
)
RETURNS BIGINT
LANGUAGE sql
AS $$
    INSERT INTO organizacion (nombre, tipo, codigo_modular_o_ref, sector_ubicacion, responsable_id)
    VALUES (p_nombre, p_tipo, p_codigo_modular_o_ref, p_sector_ubicacion, p_responsable_id)
    RETURNING id;
$$;

CREATE OR REPLACE FUNCTION fn_organizacion_actualizar(
    p_id                   BIGINT,
    p_nombre               VARCHAR,
    p_tipo                 VARCHAR,
    p_codigo_modular_o_ref VARCHAR,
    p_sector_ubicacion     VARCHAR,
    p_responsable_id       BIGINT
)
RETURNS BOOLEAN
LANGUAGE plpgsql
AS $$
BEGIN
    UPDATE organizacion
    SET nombre = p_nombre,
        tipo = p_tipo,
        codigo_modular_o_ref = p_codigo_modular_o_ref,
        sector_ubicacion = p_sector_ubicacion,
        responsable_id = p_responsable_id
    WHERE id = p_id;
    RETURN FOUND;
END;
$$;

CREATE OR REPLACE FUNCTION fn_organizacion_eliminar(p_id BIGINT)
RETURNS BOOLEAN
LANGUAGE plpgsql
AS $$
BEGIN
    DELETE FROM organizacion WHERE id = p_id;
    RETURN FOUND;
END;
$$;
