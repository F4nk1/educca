-- ==============================================================================
-- Funciones: Archivo de Sesion
-- ==============================================================================

CREATE OR REPLACE FUNCTION fn_archivo_sesion_listar(p_sesion_id BIGINT)
RETURNS TABLE (
    id          BIGINT,
    sesion_id   BIGINT,
    tipo        VARCHAR,
    url_archivo TEXT
)
LANGUAGE sql
STABLE
AS $$
    SELECT a.id, a.sesion_id, a.tipo, a.url_archivo
    FROM archivo_sesion a
    WHERE a.sesion_id = p_sesion_id
    ORDER BY a.id;
$$;

CREATE OR REPLACE FUNCTION fn_archivo_sesion_crear(
    p_sesion_id   BIGINT,
    p_tipo        VARCHAR,
    p_url_archivo TEXT
)
RETURNS BIGINT
LANGUAGE sql
AS $$
    INSERT INTO archivo_sesion (sesion_id, tipo, url_archivo)
    VALUES (p_sesion_id, p_tipo, p_url_archivo)
    RETURNING id;
$$;

CREATE OR REPLACE FUNCTION fn_archivo_sesion_eliminar(p_id BIGINT, p_sesion_id BIGINT)
RETURNS BOOLEAN
LANGUAGE plpgsql
AS $$
BEGIN
    DELETE FROM archivo_sesion WHERE id = p_id AND sesion_id = p_sesion_id;
    RETURN FOUND;
END;
$$;
