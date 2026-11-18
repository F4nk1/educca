-- ==============================================================================
-- Funciones: Organizacion y Sedes Georreferenciadas
-- ==============================================================================

CREATE OR REPLACE FUNCTION fn_organizacion_listar()
RETURNS TABLE (
    id                   BIGINT,
    nombre               VARCHAR,
    tipo                 VARCHAR,
    codigo_modular_o_ref VARCHAR,
    sector_ubicacion     VARCHAR,
    responsable_id       BIGINT,
    latitud              NUMERIC,
    longitud             NUMERIC,
    radio_metros         INTEGER
)
LANGUAGE sql
STABLE
AS $$
    SELECT o.id, o.nombre, o.tipo, o.codigo_modular_o_ref, o.sector_ubicacion,
           o.responsable_id, o.latitud, o.longitud, o.radio_metros
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
    responsable_id       BIGINT,
    latitud              NUMERIC,
    longitud             NUMERIC,
    radio_metros         INTEGER
)
LANGUAGE sql
STABLE
AS $$
    SELECT o.id, o.nombre, o.tipo, o.codigo_modular_o_ref, o.sector_ubicacion,
           o.responsable_id, o.latitud, o.longitud, o.radio_metros
    FROM organizacion o
    WHERE o.id = p_id;
$$;

CREATE OR REPLACE FUNCTION fn_organizacion_crear(
    p_nombre               VARCHAR,
    p_tipo                 VARCHAR,
    p_codigo_modular_o_ref VARCHAR,
    p_sector_ubicacion     VARCHAR,
    p_responsable_id       BIGINT,
    p_latitud              NUMERIC DEFAULT NULL,
    p_longitud             NUMERIC DEFAULT NULL,
    p_radio_metros         INTEGER DEFAULT 80
)
RETURNS BIGINT
LANGUAGE sql
AS $$
    INSERT INTO organizacion (
        nombre, tipo, codigo_modular_o_ref, sector_ubicacion,
        responsable_id, latitud, longitud, radio_metros
    )
    VALUES (
        BTRIM(p_nombre),
        p_tipo,
        NULLIF(BTRIM(p_codigo_modular_o_ref), ''),
        BTRIM(p_sector_ubicacion),
        p_responsable_id,
        p_latitud,
        p_longitud,
        COALESCE(NULLIF(p_radio_metros, 0), 80)
    )
    RETURNING id;
$$;

CREATE OR REPLACE FUNCTION fn_organizacion_actualizar(
    p_id                   BIGINT,
    p_nombre               VARCHAR,
    p_tipo                 VARCHAR,
    p_codigo_modular_o_ref VARCHAR,
    p_sector_ubicacion     VARCHAR,
    p_responsable_id       BIGINT,
    p_latitud              NUMERIC DEFAULT NULL,
    p_longitud             NUMERIC DEFAULT NULL,
    p_radio_metros         INTEGER DEFAULT 80
)
RETURNS BOOLEAN
LANGUAGE plpgsql
AS $$
BEGIN
    UPDATE organizacion
    SET nombre = BTRIM(p_nombre),
        tipo = p_tipo,
        codigo_modular_o_ref = NULLIF(BTRIM(p_codigo_modular_o_ref), ''),
        sector_ubicacion = BTRIM(p_sector_ubicacion),
        responsable_id = p_responsable_id,
        latitud = p_latitud,
        longitud = p_longitud,
        radio_metros = COALESCE(NULLIF(p_radio_metros, 0), 80)
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
