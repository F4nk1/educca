-- ==============================================================================
-- AMBIDATA DATABASE
-- Esquema consolidado de tablas y datos iniciales para PostgreSQL (EDUCCA).
-- Autogenerado mediante database/AmbiData.sh
-- ==============================================================================

BEGIN;

-- ================= TABLAS =================

-- ==============================================================================
-- Tabla: persona
-- Descripción: Identidad única de personas del sistema EDUCCA
-- ==============================================================================

CREATE TABLE IF NOT EXISTS persona (
    id               BIGSERIAL PRIMARY KEY,
    dni              VARCHAR(12) NOT NULL UNIQUE,
    nombres          VARCHAR(100) NOT NULL,
    apellidos        VARCHAR(100) NOT NULL,
    sexo             CHAR(1) NOT NULL CHECK (sexo IN ('M', 'F')),
    fecha_nacimiento DATE NOT NULL,
    telefono         VARCHAR(15),
    email            VARCHAR(120) UNIQUE,
    password_hash    TEXT,
    activo           BOOLEAN NOT NULL DEFAULT TRUE
);


-- ==============================================================================
-- Tabla: rol
-- Descripción: Roles del sistema para control de acceso (RBAC dinámico)
-- ==============================================================================

CREATE TABLE IF NOT EXISTS rol (
    id          SMALLSERIAL PRIMARY KEY,
    nombre      VARCHAR(50) NOT NULL UNIQUE,
    descripcion VARCHAR(150) NOT NULL
);


-- ==============================================================================
-- Tabla: permiso
-- Descripción: Permisos granulares del sistema (ej. 'sesiones:crear')
-- ==============================================================================

CREATE TABLE IF NOT EXISTS permiso (
    id          SMALLSERIAL PRIMARY KEY,
    clave       VARCHAR(60) NOT NULL UNIQUE,
    descripcion VARCHAR(150) NOT NULL
);


-- ==============================================================================
-- Tabla: rol_permiso
-- Descripción: Relación N:M entre roles y permisos
-- ==============================================================================

CREATE TABLE IF NOT EXISTS rol_permiso (
    rol_id     SMALLINT NOT NULL REFERENCES rol(id) ON DELETE CASCADE,
    permiso_id SMALLINT NOT NULL REFERENCES permiso(id) ON DELETE CASCADE,
    PRIMARY KEY (rol_id, permiso_id)
);


-- ==============================================================================
-- Tabla: persona_rol
-- Descripción: Relación N:M entre personas y roles
-- ==============================================================================

CREATE TABLE IF NOT EXISTS persona_rol (
    persona_id BIGINT NOT NULL REFERENCES persona(id) ON DELETE CASCADE,
    rol_id     SMALLINT NOT NULL REFERENCES rol(id) ON DELETE CASCADE,
    PRIMARY KEY (persona_id, rol_id)
);


-- ==============================================================================
-- Tabla: organizacion
-- Descripción: Instituciones, colegios, organizaciones sociales y EPEA
-- ==============================================================================

CREATE TABLE IF NOT EXISTS organizacion (
    id                   BIGSERIAL PRIMARY KEY,
    nombre               VARCHAR(150) NOT NULL,
    tipo                 VARCHAR(30) NOT NULL CHECK (tipo IN (
                             'COLEGIO',
                             'EDUCACION_SUPERIOR',
                             'ORGANIZACION_SOCIAL',
                             'ESPACIO_PUBLICO_EPEA',
                             'INSTITUCION_PUBLICA'
                         )),
    codigo_modular_o_ref VARCHAR(30),
    sector_ubicacion     VARCHAR(120) NOT NULL,
    responsable_id       BIGINT REFERENCES persona(id) ON DELETE SET NULL
);


-- ==============================================================================
-- Tabla: meta_anual
-- Descripción: Metas anuales programadas según actividades MINAM
-- ==============================================================================

CREATE TABLE IF NOT EXISTS meta_anual (
    id              BIGSERIAL PRIMARY KEY,
    anio            SMALLINT NOT NULL CHECK (anio >= 2024),
    actividad_minam VARCHAR(20) NOT NULL CHECK (actividad_minam IN (
                        'PAE', 'PAJ', 'PAC', 'EPEA', 'CAMPANA'
                    )),
    indicador       VARCHAR(120) NOT NULL,
    meta_programada INTEGER NOT NULL CHECK (meta_programada > 0),
    presupuesto     NUMERIC(10, 2) NOT NULL DEFAULT 0.00 CHECK (presupuesto >= 0),
    UNIQUE (anio, actividad_minam, indicador)
);


-- ==============================================================================
-- Tabla: promotor_periodo
-- Descripción: Registro anual de promotores ambientales y docentes EDUCCA
-- ==============================================================================

CREATE TABLE IF NOT EXISTS promotor_periodo (
    id                 BIGSERIAL PRIMARY KEY,
    persona_id         BIGINT NOT NULL REFERENCES persona(id) ON DELETE RESTRICT,
    anio               SMALLINT NOT NULL CHECK (anio >= 2024),
    tipo_promotor      VARCHAR(10) NOT NULL CHECK (tipo_promotor IN (
                           'PAE', 'PAJ', 'PAC', 'DOCENTE'
                       )),
    organizacion_id    BIGINT REFERENCES organizacion(id) ON DELETE SET NULL,
    estado             VARCHAR(20) NOT NULL DEFAULT 'INSCRITO' CHECK (estado IN (
                           'INSCRITO', 'ACREDITADO', 'RETIRADO'
                       )),
    codigo_certificado VARCHAR(40) UNIQUE,
    UNIQUE (persona_id, anio, tipo_promotor)
);

CREATE INDEX IF NOT EXISTS idx_promotor_periodo_anio ON promotor_periodo(anio);


-- ==============================================================================
-- Tabla: sesion
-- Descripción: Sesiones educativas, talleres y campañas ejecutadas en EDUCCA
-- ==============================================================================

CREATE TABLE IF NOT EXISTS sesion (
    id               BIGSERIAL PRIMARY KEY,
    meta_anual_id    BIGINT NOT NULL REFERENCES meta_anual(id) ON DELETE RESTRICT,
    organizacion_id  BIGINT REFERENCES organizacion(id) ON DELETE SET NULL,
    responsable_id   BIGINT NOT NULL REFERENCES persona(id) ON DELETE RESTRICT,
    titulo           VARCHAR(150) NOT NULL,
    modalidad        VARCHAR(15) NOT NULL CHECK (modalidad IN ('PRESENCIAL', 'VIRTUAL')),
    fecha_inicio     TIMESTAMPTZ NOT NULL,
    duracion_minutos SMALLINT NOT NULL CHECK (duracion_minutos > 0),
    estado           VARCHAR(20) NOT NULL DEFAULT 'PROGRAMADA' CHECK (estado IN (
                         'PROGRAMADA', 'EJECUTADA', 'VALIDADA', 'CANCELADA'
                     ))
);

CREATE INDEX IF NOT EXISTS idx_sesion_meta_anual_id ON sesion(meta_anual_id);
CREATE INDEX IF NOT EXISTS idx_sesion_estado ON sesion(estado);


-- ==============================================================================
-- Tabla: asistencia
-- Descripción: Registro de participantes por sesión y su calificación
-- ==============================================================================

CREATE TABLE IF NOT EXISTS asistencia (
    sesion_id     BIGINT NOT NULL REFERENCES sesion(id) ON DELETE CASCADE,
    persona_id    BIGINT NOT NULL REFERENCES persona(id) ON DELETE RESTRICT,
    participacion VARCHAR(20) NOT NULL DEFAULT 'ASISTENTE' CHECK (participacion IN (
                      'ASISTENTE', 'VOLUNTARIO_REPLICA', 'PONENTE'
                  )),
    calificacion  NUMERIC(4, 2) CHECK (calificacion >= 0 AND calificacion <= 20),
    PRIMARY KEY (sesion_id, persona_id)
);


-- ==============================================================================
-- Tabla: archivo_sesion
-- Descripción: Evidencias y documentos asociados a cada sesión
-- ==============================================================================

CREATE TABLE IF NOT EXISTS archivo_sesion (
    id          BIGSERIAL PRIMARY KEY,
    sesion_id   BIGINT NOT NULL REFERENCES sesion(id) ON DELETE CASCADE,
    tipo        VARCHAR(25) NOT NULL CHECK (tipo IN (
                    'FOTO_EVIDENCIA', 'PADRON_FIRMADO', 'ACTA', 'MATERIAL_DIDACTICO'
                )),
    url_archivo TEXT NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_archivo_sesion_sesion_id ON archivo_sesion(sesion_id);

-- ================= FUNCIONES =================

-- ==============================================================================
-- Funciones: Autenticación y RBAC
-- ==============================================================================

CREATE OR REPLACE FUNCTION fn_auth_login(p_identificador VARCHAR)
RETURNS TABLE (
    id            BIGINT,
    dni           VARCHAR,
    nombres       VARCHAR,
    apellidos     VARCHAR,
    email         VARCHAR,
    password_hash TEXT,
    activo        BOOLEAN
)
LANGUAGE sql
STABLE
AS $$
    SELECT p.id, p.dni, p.nombres, p.apellidos, p.email, p.password_hash, p.activo
    FROM persona p
    WHERE (p.dni = p_identificador OR p.email = p_identificador)
      AND p.password_hash IS NOT NULL
    LIMIT 1;
$$;

CREATE OR REPLACE FUNCTION fn_persona_roles_nombres(p_persona_id BIGINT)
RETURNS TABLE (nombre VARCHAR)
LANGUAGE sql
STABLE
AS $$
    SELECT r.nombre
    FROM persona_rol pr
    JOIN rol r ON r.id = pr.rol_id
    WHERE pr.persona_id = p_persona_id
    ORDER BY r.nombre;
$$;

CREATE OR REPLACE FUNCTION fn_persona_permisos_claves(p_persona_id BIGINT)
RETURNS TABLE (clave VARCHAR)
LANGUAGE sql
STABLE
AS $$
    SELECT DISTINCT pm.clave
    FROM persona_rol pr
    JOIN rol_permiso rp ON rp.rol_id = pr.rol_id
    JOIN permiso pm ON pm.id = rp.permiso_id
    WHERE pr.persona_id = p_persona_id
    ORDER BY pm.clave;
$$;

CREATE OR REPLACE FUNCTION fn_persona_tiene_permiso(p_persona_id BIGINT, p_clave VARCHAR)
RETURNS BOOLEAN
LANGUAGE sql
STABLE
AS $$
    SELECT EXISTS (
        SELECT 1
        FROM persona p
        JOIN persona_rol pr ON pr.persona_id = p.id
        JOIN rol_permiso rp ON rp.rol_id = pr.rol_id
        JOIN permiso pm ON pm.id = rp.permiso_id
        WHERE p.id = p_persona_id
          AND p.activo = TRUE
          AND pm.clave = p_clave
    );
$$;


-- ==============================================================================
-- Funciones: Persona y asignación de roles
-- ==============================================================================

CREATE OR REPLACE FUNCTION fn_persona_listar()
RETURNS TABLE (
    id               BIGINT,
    dni              VARCHAR,
    nombres          VARCHAR,
    apellidos        VARCHAR,
    sexo             CHAR(1),
    fecha_nacimiento DATE,
    telefono         VARCHAR,
    email            VARCHAR,
    activo           BOOLEAN
)
LANGUAGE sql
STABLE
AS $$
    SELECT p.id, p.dni, p.nombres, p.apellidos, p.sexo, p.fecha_nacimiento, p.telefono, p.email, p.activo
    FROM persona p
    ORDER BY p.id;
$$;

CREATE OR REPLACE FUNCTION fn_persona_obtener(p_id BIGINT)
RETURNS TABLE (
    id               BIGINT,
    dni              VARCHAR,
    nombres          VARCHAR,
    apellidos        VARCHAR,
    sexo             CHAR(1),
    fecha_nacimiento DATE,
    telefono         VARCHAR,
    email            VARCHAR,
    activo           BOOLEAN
)
LANGUAGE sql
STABLE
AS $$
    SELECT p.id, p.dni, p.nombres, p.apellidos, p.sexo, p.fecha_nacimiento, p.telefono, p.email, p.activo
    FROM persona p
    WHERE p.id = p_id;
$$;

CREATE OR REPLACE FUNCTION fn_persona_crear(
    p_dni              VARCHAR,
    p_nombres          VARCHAR,
    p_apellidos        VARCHAR,
    p_sexo             CHAR(1),
    p_fecha_nacimiento DATE,
    p_telefono         VARCHAR,
    p_email            VARCHAR,
    p_password_hash    TEXT,
    p_activo           BOOLEAN
)
RETURNS BIGINT
LANGUAGE sql
AS $$
    INSERT INTO persona (dni, nombres, apellidos, sexo, fecha_nacimiento, telefono, email, password_hash, activo)
    VALUES (p_dni, p_nombres, p_apellidos, p_sexo, p_fecha_nacimiento, NULLIF(BTRIM(p_telefono), ''), NULLIF(BTRIM(p_email), ''), p_password_hash, p_activo)
    RETURNING id;
$$;

CREATE OR REPLACE FUNCTION fn_persona_actualizar(
    p_id               BIGINT,
    p_dni              VARCHAR,
    p_nombres          VARCHAR,
    p_apellidos        VARCHAR,
    p_sexo             CHAR(1),
    p_fecha_nacimiento DATE,
    p_telefono         VARCHAR,
    p_email            VARCHAR
)
RETURNS BOOLEAN
LANGUAGE plpgsql
AS $$
BEGIN
    UPDATE persona
    SET dni = p_dni,
        nombres = p_nombres,
        apellidos = p_apellidos,
        sexo = p_sexo,
        fecha_nacimiento = p_fecha_nacimiento,
        telefono = NULLIF(BTRIM(p_telefono), ''),
        email = NULLIF(BTRIM(p_email), '')
    WHERE id = p_id;
    RETURN FOUND;
END;
$$;

CREATE OR REPLACE FUNCTION fn_persona_cambiar_activo(p_id BIGINT, p_activo BOOLEAN)
RETURNS BOOLEAN
LANGUAGE plpgsql
AS $$
BEGIN
    UPDATE persona SET activo = p_activo WHERE id = p_id;
    RETURN FOUND;
END;
$$;

CREATE OR REPLACE FUNCTION fn_persona_cambiar_password(p_id BIGINT, p_password_hash TEXT)
RETURNS BOOLEAN
LANGUAGE plpgsql
AS $$
BEGIN
    UPDATE persona SET password_hash = p_password_hash WHERE id = p_id;
    RETURN FOUND;
END;
$$;

CREATE OR REPLACE FUNCTION fn_persona_listar_roles(p_persona_id BIGINT)
RETURNS TABLE (id SMALLINT, nombre VARCHAR, descripcion VARCHAR)
LANGUAGE plpgsql
STABLE
AS $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM persona p WHERE p.id = p_persona_id) THEN
        RAISE EXCEPTION 'Persona no encontrada' USING ERRCODE = 'P0002';
    END IF;

    RETURN QUERY
    SELECT r.id, r.nombre, r.descripcion
    FROM persona_rol pr
    JOIN rol r ON r.id = pr.rol_id
    WHERE pr.persona_id = p_persona_id
    ORDER BY r.id;
END;
$$;

CREATE OR REPLACE FUNCTION fn_persona_asignar_rol(p_persona_id BIGINT, p_rol_id SMALLINT)
RETURNS VOID
LANGUAGE sql
AS $$
    INSERT INTO persona_rol (persona_id, rol_id)
    VALUES (p_persona_id, p_rol_id)
    ON CONFLICT (persona_id, rol_id) DO NOTHING;
$$;

CREATE OR REPLACE FUNCTION fn_persona_quitar_rol(p_persona_id BIGINT, p_rol_id SMALLINT)
RETURNS BOOLEAN
LANGUAGE plpgsql
AS $$
BEGIN
    DELETE FROM persona_rol WHERE persona_id = p_persona_id AND rol_id = p_rol_id;
    RETURN FOUND;
END;
$$;


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
    VALUES (p_nombre, p_tipo, NULLIF(BTRIM(p_codigo_modular_o_ref), ''), p_sector_ubicacion, p_responsable_id)
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
        codigo_modular_o_ref = NULLIF(BTRIM(p_codigo_modular_o_ref), ''),
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
    VALUES (p_persona_id, p_anio, p_tipo_promotor, p_organizacion_id, COALESCE(p_estado, 'INSCRITO'), NULLIF(BTRIM(p_codigo_certificado), ''))
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
        codigo_certificado = NULLIF(BTRIM(p_codigo_certificado), '')
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


-- ==============================================================================
-- Funciones: Sesion Educativa
-- ==============================================================================

CREATE OR REPLACE FUNCTION fn_sesion_listar(
    p_meta_anual_id BIGINT DEFAULT NULL,
    p_estado        VARCHAR DEFAULT NULL
)
RETURNS TABLE (
    id               BIGINT,
    meta_anual_id    BIGINT,
    organizacion_id  BIGINT,
    responsable_id   BIGINT,
    titulo           VARCHAR,
    modalidad        VARCHAR,
    fecha_inicio     TIMESTAMPTZ,
    duracion_minutos SMALLINT,
    estado           VARCHAR
)
LANGUAGE sql
STABLE
AS $$
    SELECT s.id, s.meta_anual_id, s.organizacion_id, s.responsable_id,
           s.titulo, s.modalidad, s.fecha_inicio, s.duracion_minutos, s.estado
    FROM sesion s
    WHERE (p_meta_anual_id IS NULL OR s.meta_anual_id = p_meta_anual_id)
      AND (p_estado IS NULL OR s.estado = p_estado)
    ORDER BY s.fecha_inicio DESC, s.id DESC;
$$;

CREATE OR REPLACE FUNCTION fn_sesion_obtener(p_id BIGINT)
RETURNS TABLE (
    id               BIGINT,
    meta_anual_id    BIGINT,
    organizacion_id  BIGINT,
    responsable_id   BIGINT,
    titulo           VARCHAR,
    modalidad        VARCHAR,
    fecha_inicio     TIMESTAMPTZ,
    duracion_minutos SMALLINT,
    estado           VARCHAR
)
LANGUAGE sql
STABLE
AS $$
    SELECT s.id, s.meta_anual_id, s.organizacion_id, s.responsable_id,
           s.titulo, s.modalidad, s.fecha_inicio, s.duracion_minutos, s.estado
    FROM sesion s
    WHERE s.id = p_id;
$$;

CREATE OR REPLACE FUNCTION fn_sesion_crear(
    p_meta_anual_id    BIGINT,
    p_organizacion_id  BIGINT,
    p_responsable_id   BIGINT,
    p_titulo           VARCHAR,
    p_modalidad        VARCHAR,
    p_fecha_inicio     TIMESTAMPTZ,
    p_duracion_minutos SMALLINT
)
RETURNS BIGINT
LANGUAGE sql
AS $$
    INSERT INTO sesion (meta_anual_id, organizacion_id, responsable_id, titulo, modalidad, fecha_inicio, duracion_minutos)
    VALUES (p_meta_anual_id, p_organizacion_id, p_responsable_id, p_titulo, p_modalidad, p_fecha_inicio, p_duracion_minutos)
    RETURNING id;
$$;

CREATE OR REPLACE FUNCTION fn_sesion_actualizar(
    p_id               BIGINT,
    p_meta_anual_id    BIGINT,
    p_organizacion_id  BIGINT,
    p_responsable_id   BIGINT,
    p_titulo           VARCHAR,
    p_modalidad        VARCHAR,
    p_fecha_inicio     TIMESTAMPTZ,
    p_duracion_minutos SMALLINT
)
RETURNS BOOLEAN
LANGUAGE plpgsql
AS $$
DECLARE
    v_estado VARCHAR(20);
BEGIN
    SELECT estado INTO v_estado FROM sesion WHERE id = p_id;
    IF NOT FOUND THEN
        RETURN FALSE;
    END IF;

    IF v_estado IN ('VALIDADA', 'CANCELADA') THEN
        RAISE EXCEPTION 'No se puede modificar una sesion en estado %', v_estado USING ERRCODE = 'P0001';
    END IF;

    UPDATE sesion
    SET meta_anual_id = p_meta_anual_id,
        organizacion_id = p_organizacion_id,
        responsable_id = p_responsable_id,
        titulo = p_titulo,
        modalidad = p_modalidad,
        fecha_inicio = p_fecha_inicio,
        duracion_minutos = p_duracion_minutos
    WHERE id = p_id;
    RETURN TRUE;
END;
$$;

CREATE OR REPLACE FUNCTION fn_sesion_cambiar_estado(p_id BIGINT, p_nuevo_estado VARCHAR)
RETURNS BOOLEAN
LANGUAGE plpgsql
AS $$
DECLARE
    v_estado VARCHAR(20);
BEGIN
    SELECT estado INTO v_estado FROM sesion WHERE id = p_id;
    IF NOT FOUND THEN
        RETURN FALSE;
    END IF;

    IF NOT (
        (v_estado = 'PROGRAMADA' AND p_nuevo_estado IN ('EJECUTADA', 'CANCELADA')) OR
        (v_estado = 'EJECUTADA' AND p_nuevo_estado IN ('VALIDADA', 'CANCELADA'))
    ) THEN
        RAISE EXCEPTION 'Transicion de estado invalida: % -> %', v_estado, p_nuevo_estado USING ERRCODE = 'P0001';
    END IF;

    UPDATE sesion SET estado = p_nuevo_estado WHERE id = p_id;
    RETURN TRUE;
END;
$$;

CREATE OR REPLACE FUNCTION fn_sesion_eliminar(p_id BIGINT)
RETURNS BOOLEAN
LANGUAGE plpgsql
AS $$
DECLARE
    v_estado VARCHAR(20);
BEGIN
    SELECT estado INTO v_estado FROM sesion WHERE id = p_id;
    IF NOT FOUND THEN
        RETURN FALSE;
    END IF;

    IF v_estado IN ('VALIDADA', 'CANCELADA') THEN
        RAISE EXCEPTION 'No se puede eliminar una sesion en estado %', v_estado USING ERRCODE = 'P0001';
    END IF;

    DELETE FROM sesion WHERE id = p_id;
    RETURN TRUE;
END;
$$;


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
LANGUAGE plpgsql
STABLE
AS $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM sesion s WHERE s.id = p_sesion_id) THEN
        RAISE EXCEPTION 'Sesion no encontrada' USING ERRCODE = 'P0002';
    END IF;

    RETURN QUERY
    SELECT a.sesion_id, a.persona_id, a.participacion, a.calificacion
    FROM asistencia a
    WHERE a.sesion_id = p_sesion_id
    ORDER BY a.persona_id;
END;
$$;

CREATE OR REPLACE FUNCTION fn_asistencia_registrar(
    p_sesion_id     BIGINT,
    p_persona_id    BIGINT,
    p_participacion VARCHAR,
    p_calificacion  NUMERIC
)
RETURNS VOID
LANGUAGE plpgsql
AS $$
DECLARE
    v_estado VARCHAR(20);
BEGIN
    SELECT estado INTO v_estado FROM sesion WHERE id = p_sesion_id;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Sesion no encontrada' USING ERRCODE = 'P0002';
    END IF;

    IF v_estado IN ('VALIDADA', 'CANCELADA') THEN
        RAISE EXCEPTION 'No se puede registrar asistencia en una sesion en estado %', v_estado USING ERRCODE = 'P0001';
    END IF;

    INSERT INTO asistencia (sesion_id, persona_id, participacion, calificacion)
    VALUES (p_sesion_id, p_persona_id, COALESCE(p_participacion, 'ASISTENTE'), p_calificacion)
    ON CONFLICT (sesion_id, persona_id) DO UPDATE SET
        participacion = EXCLUDED.participacion,
        calificacion = EXCLUDED.calificacion;
END;
$$;

CREATE OR REPLACE FUNCTION fn_asistencia_eliminar(p_sesion_id BIGINT, p_persona_id BIGINT)
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
        RAISE EXCEPTION 'No se puede eliminar asistencia de una sesion en estado %', v_estado USING ERRCODE = 'P0001';
    END IF;

    DELETE FROM asistencia WHERE sesion_id = p_sesion_id AND persona_id = p_persona_id;
    RETURN FOUND;
END;
$$;


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
        COUNT(a.persona_id) FILTER (WHERE s.estado IN ('EJECUTADA', 'VALIDADA') AND a.participacion = 'ASISTENTE') AS total_asistentes
    FROM meta_anual m
    LEFT JOIN sesion s ON s.meta_anual_id = m.id
    LEFT JOIN asistencia a ON a.sesion_id = s.id
    WHERE p_anio IS NULL OR m.anio = p_anio
    GROUP BY m.id, m.anio, m.actividad_minam, m.indicador, m.meta_programada, m.presupuesto
    ORDER BY m.anio DESC, m.actividad_minam, m.id;
$$;

-- ================= DATOS SEMILLA =================

-- ==============================================================================
-- Datos iniciales: rol
-- ==============================================================================

INSERT INTO rol (nombre, descripcion) VALUES
    ('admin', 'Administrador del sistema EDUCCA con acceso total'),
    ('coordinador', 'Coordinador municipal responsable de metas, sesiones y validaciones'),
    ('promotor', 'Promotor ambiental o docente acreditado para registrar actividades'),
    ('consulta', 'Usuario con acceso de solo lectura a reportes y sesiones')
ON CONFLICT (nombre) DO UPDATE SET
    descripcion = EXCLUDED.descripcion;


-- ==============================================================================
-- Datos iniciales: permiso
-- ==============================================================================

INSERT INTO permiso (clave, descripcion) VALUES
    ('personas:leer', 'Consultar personas registradas'),
    ('personas:escribir', 'Registrar y actualizar personas'),
    ('roles:gestionar', 'Administrar roles y permisos'),
    ('organizaciones:leer', 'Consultar organizaciones registradas'),
    ('organizaciones:escribir', 'Registrar y actualizar organizaciones'),
    ('metas:leer', 'Consultar metas anuales MINAM'),
    ('metas:escribir', 'Programar y actualizar metas anuales'),
    ('promotores:leer', 'Consultar promotores por periodo'),
    ('promotores:escribir', 'Inscribir y acreditar promotores'),
    ('sesiones:leer', 'Consultar sesiones educativas'),
    ('sesiones:crear', 'Programar y registrar sesiones educativas'),
    ('sesiones:validar', 'Validar o cancelar sesiones ejecutadas'),
    ('asistencias:registrar', 'Registrar asistencia y calificaciones'),
    ('archivos:subir', 'Adjuntar evidencias y actas a sesiones'),
    ('reportes:exportar', 'Exportar reportes consolidados EDUCCA')
ON CONFLICT (clave) DO UPDATE SET
    descripcion = EXCLUDED.descripcion;


-- ==============================================================================
-- Datos iniciales: rol_permiso
-- ==============================================================================

INSERT INTO rol_permiso (rol_id, permiso_id)
SELECT r.id, p.id
FROM rol r
CROSS JOIN permiso p
WHERE r.nombre = 'admin'
ON CONFLICT (rol_id, permiso_id) DO NOTHING;

INSERT INTO rol_permiso (rol_id, permiso_id)
SELECT r.id, p.id
FROM rol r
JOIN permiso p ON p.clave IN (
    'personas:leer', 'personas:escribir',
    'organizaciones:leer', 'organizaciones:escribir',
    'metas:leer', 'metas:escribir',
    'promotores:leer', 'promotores:escribir',
    'sesiones:leer', 'sesiones:crear', 'sesiones:validar',
    'asistencias:registrar', 'archivos:subir',
    'reportes:exportar'
)
WHERE r.nombre = 'coordinador'
ON CONFLICT (rol_id, permiso_id) DO NOTHING;

INSERT INTO rol_permiso (rol_id, permiso_id)
SELECT r.id, p.id
FROM rol r
JOIN permiso p ON p.clave IN (
    'personas:leer', 'organizaciones:leer', 'metas:leer', 'promotores:leer',
    'sesiones:leer', 'sesiones:crear',
    'asistencias:registrar', 'archivos:subir'
)
WHERE r.nombre = 'promotor'
ON CONFLICT (rol_id, permiso_id) DO NOTHING;

INSERT INTO rol_permiso (rol_id, permiso_id)
SELECT r.id, p.id
FROM rol r
JOIN permiso p ON p.clave IN (
    'personas:leer', 'organizaciones:leer', 'metas:leer',
    'promotores:leer', 'sesiones:leer', 'reportes:exportar'
)
WHERE r.nombre = 'consulta'
ON CONFLICT (rol_id, permiso_id) DO NOTHING;


-- ==============================================================================
-- Datos iniciales: persona
-- Contraseña por defecto para usuario semilla: password123 (hash bcrypt)
-- ==============================================================================

INSERT INTO persona (dni, nombres, apellidos, sexo, fecha_nacimiento, telefono, email, password_hash, activo) VALUES
    ('00000000', 'Admin', 'Principal', 'M', '1990-01-01', '+51999999999', 'admin@educca.gob.pe', '$2a$10$vI8aWBnW3fID.ZQ4/zo1G.q1lRps.9cGLcZEiGDMVr5yUP1KUOYTa', TRUE)
ON CONFLICT (dni) DO UPDATE SET
    nombres = EXCLUDED.nombres,
    apellidos = EXCLUDED.apellidos,
    telefono = EXCLUDED.telefono,
    email = EXCLUDED.email,
    activo = EXCLUDED.activo;


-- ==============================================================================
-- Datos iniciales: persona_rol
-- ==============================================================================

INSERT INTO persona_rol (persona_id, rol_id)
SELECT p.id, r.id
FROM persona p
JOIN rol r ON r.nombre = 'admin'
WHERE p.dni = '00000000'
ON CONFLICT (persona_id, rol_id) DO NOTHING;

COMMIT;
