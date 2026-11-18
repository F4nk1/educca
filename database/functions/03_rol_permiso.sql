-- ==============================================================================
-- Funciones: Rol y Permiso
-- ==============================================================================

CREATE OR REPLACE FUNCTION fn_rol_listar()
RETURNS TABLE (id SMALLINT, nombre VARCHAR, descripcion VARCHAR)
LANGUAGE sql
STABLE
AS $$
    SELECT r.id, r.nombre, r.descripcion FROM rol r ORDER BY r.id;
$$;

CREATE OR REPLACE FUNCTION fn_rol_obtener(p_id SMALLINT)
RETURNS TABLE (id SMALLINT, nombre VARCHAR, descripcion VARCHAR)
LANGUAGE sql
STABLE
AS $$
    SELECT r.id, r.nombre, r.descripcion FROM rol r WHERE r.id = p_id;
$$;

CREATE OR REPLACE FUNCTION fn_rol_crear(p_nombre VARCHAR, p_descripcion VARCHAR)
RETURNS SMALLINT
LANGUAGE sql
AS $$
    INSERT INTO rol (nombre, descripcion) VALUES (p_nombre, p_descripcion) RETURNING id;
$$;

CREATE OR REPLACE FUNCTION fn_rol_actualizar(p_id SMALLINT, p_nombre VARCHAR, p_descripcion VARCHAR)
RETURNS BOOLEAN
LANGUAGE plpgsql
AS $$
BEGIN
    UPDATE rol SET nombre = p_nombre, descripcion = p_descripcion WHERE id = p_id;
    RETURN FOUND;
END;
$$;

CREATE OR REPLACE FUNCTION fn_rol_eliminar(p_id SMALLINT)
RETURNS BOOLEAN
LANGUAGE plpgsql
AS $$
BEGIN
    DELETE FROM rol WHERE id = p_id;
    RETURN FOUND;
END;
$$;

CREATE OR REPLACE FUNCTION fn_permiso_listar()
RETURNS TABLE (id SMALLINT, clave VARCHAR, descripcion VARCHAR)
LANGUAGE sql
STABLE
AS $$
    SELECT p.id, p.clave, p.descripcion FROM permiso p ORDER BY p.id;
$$;

CREATE OR REPLACE FUNCTION fn_permiso_crear(p_clave VARCHAR, p_descripcion VARCHAR)
RETURNS SMALLINT
LANGUAGE sql
AS $$
    INSERT INTO permiso (clave, descripcion) VALUES (p_clave, p_descripcion) RETURNING id;
$$;

CREATE OR REPLACE FUNCTION fn_permiso_eliminar(p_id SMALLINT)
RETURNS BOOLEAN
LANGUAGE plpgsql
AS $$
BEGIN
    DELETE FROM permiso WHERE id = p_id;
    RETURN FOUND;
END;
$$;

CREATE OR REPLACE FUNCTION fn_rol_listar_permisos(p_rol_id SMALLINT)
RETURNS TABLE (id SMALLINT, clave VARCHAR, descripcion VARCHAR)
LANGUAGE plpgsql
STABLE
AS $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM rol r WHERE r.id = p_rol_id) THEN
        RAISE EXCEPTION 'Rol no encontrado' USING ERRCODE = 'P0002';
    END IF;

    RETURN QUERY
    SELECT pm.id, pm.clave, pm.descripcion
    FROM rol_permiso rp
    JOIN permiso pm ON pm.id = rp.permiso_id
    WHERE rp.rol_id = p_rol_id
    ORDER BY pm.id;
END;
$$;

CREATE OR REPLACE FUNCTION fn_rol_asignar_permiso(p_rol_id SMALLINT, p_permiso_id SMALLINT)
RETURNS VOID
LANGUAGE sql
AS $$
    INSERT INTO rol_permiso (rol_id, permiso_id)
    VALUES (p_rol_id, p_permiso_id)
    ON CONFLICT (rol_id, permiso_id) DO NOTHING;
$$;

CREATE OR REPLACE FUNCTION fn_rol_quitar_permiso(p_rol_id SMALLINT, p_permiso_id SMALLINT)
RETURNS BOOLEAN
LANGUAGE plpgsql
AS $$
BEGIN
    DELETE FROM rol_permiso WHERE rol_id = p_rol_id AND permiso_id = p_permiso_id;
    RETURN FOUND;
END;
$$;
