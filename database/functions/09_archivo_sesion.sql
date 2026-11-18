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
LANGUAGE plpgsql
STABLE
AS $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM sesion s WHERE s.id = p_sesion_id) THEN
        RAISE EXCEPTION 'Sesion no encontrada' USING ERRCODE = 'P0002';
    END IF;

    RETURN QUERY
    SELECT a.id, a.sesion_id, a.tipo, a.url_archivo
    FROM archivo_sesion a
    WHERE a.sesion_id = p_sesion_id
    ORDER BY a.id;
END;
$$;

CREATE OR REPLACE FUNCTION fn_archivo_sesion_crear(
    p_sesion_id   BIGINT,
    p_tipo        VARCHAR,
    p_url_archivo TEXT
)
RETURNS BIGINT
LANGUAGE plpgsql
AS $$
DECLARE
    v_estado VARCHAR(20);
    v_id     BIGINT;
BEGIN
    SELECT estado INTO v_estado FROM sesion WHERE id = p_sesion_id;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Sesion no encontrada' USING ERRCODE = 'P0002';
    END IF;

    IF v_estado IN ('VALIDADA', 'CANCELADA') THEN
        RAISE EXCEPTION 'No se puede adjuntar archivos a una sesion en estado %', v_estado USING ERRCODE = 'P0001';
    END IF;

    INSERT INTO archivo_sesion (sesion_id, tipo, url_archivo)
    VALUES (p_sesion_id, p_tipo, p_url_archivo)
    RETURNING id INTO v_id;

    RETURN v_id;
END;
$$;

CREATE OR REPLACE FUNCTION fn_archivo_sesion_eliminar(p_id BIGINT, p_sesion_id BIGINT)
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
        RAISE EXCEPTION 'No se puede eliminar archivos de una sesion en estado %', v_estado USING ERRCODE = 'P0001';
    END IF;

    DELETE FROM archivo_sesion WHERE id = p_id AND sesion_id = p_sesion_id;
    RETURN FOUND;
END;
$$;
