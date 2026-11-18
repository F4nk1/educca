-- ==============================================================================
-- AMBIDATA DATABASE
-- Esquema consolidado de tablas y datos iniciales para PostgreSQL (EDUCCA).
-- Autogenerado mediante database/AmbiData.sh
-- ==============================================================================

BEGIN;

-- ================= TABLAS =================

-- ==============================================================================
-- Tabla: persona
-- Descripción: Identidad única de personas del sistema EDUCCA / EcoCapacita
-- ==============================================================================

CREATE TABLE IF NOT EXISTS persona (
    id                     BIGSERIAL PRIMARY KEY,
    dni                    VARCHAR(20) NOT NULL UNIQUE,
    nombres                VARCHAR(100) NOT NULL,
    apellidos              VARCHAR(100) NOT NULL,
    sexo                   CHAR(1) NOT NULL CHECK (sexo IN ('M', 'F')),
    fecha_nacimiento       DATE NOT NULL,
    telefono               VARCHAR(15),
    email                  VARCHAR(120) UNIQUE,
    password_hash          TEXT,
    categoria              VARCHAR(20) CHECK (categoria IN (
                               'COMERCIANTE', 'RECICLADOR', 'PAC', 'PAJ'
                           )),
    consentimiento_at      TIMESTAMPTZ,
    consentimiento_version VARCHAR(20),
    anonimizado            BOOLEAN NOT NULL DEFAULT FALSE,
    activo                 BOOLEAN NOT NULL DEFAULT TRUE
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
-- Descripción: Instituciones, mercados, centros de acopio, organizaciones sociales y EPEA
-- ==============================================================================

CREATE TABLE IF NOT EXISTS organizacion (
    id                   BIGSERIAL PRIMARY KEY,
    nombre               VARCHAR(150) NOT NULL,
    tipo                 VARCHAR(30) NOT NULL CHECK (tipo IN (
                             'COLEGIO',
                             'EDUCACION_SUPERIOR',
                             'ORGANIZACION_SOCIAL',
                             'ESPACIO_PUBLICO_EPEA',
                             'INSTITUCION_PUBLICA',
                             'MERCADO',
                             'CENTRO_ACOPIO'
                         )),
    codigo_modular_o_ref VARCHAR(30),
    sector_ubicacion     VARCHAR(120) NOT NULL,
    responsable_id       BIGINT REFERENCES persona(id) ON DELETE SET NULL,
    latitud              NUMERIC(9, 6) CHECK (latitud IS NULL OR (latitud >= -90 AND latitud <= 90)),
    longitud             NUMERIC(9, 6) CHECK (longitud IS NULL OR (longitud >= -180 AND longitud <= 180)),
    radio_metros         INTEGER NOT NULL DEFAULT 80 CHECK (radio_metros > 0),
    CHECK ((latitud IS NULL AND longitud IS NULL) OR (latitud IS NOT NULL AND longitud IS NOT NULL))
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
-- Descripción: Registro anual de promotores ambientales, actores acreditados y docentes EDUCCA
-- ==============================================================================

CREATE TABLE IF NOT EXISTS promotor_periodo (
    id                 BIGSERIAL PRIMARY KEY,
    persona_id         BIGINT NOT NULL REFERENCES persona(id) ON DELETE RESTRICT,
    anio               SMALLINT NOT NULL CHECK (anio >= 2024),
    tipo_promotor      VARCHAR(20) NOT NULL CHECK (tipo_promotor IN (
                           'PAE', 'PAJ', 'PAC', 'DOCENTE', 'COMERCIANTE', 'RECICLADOR'
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
    eje_tematico     VARCHAR(40) NOT NULL DEFAULT 'SEGREGACION_RECICLA' CHECK (eje_tematico IN (
                         'SEGREGACION_RECICLA',
                         'RECICLAJE_FORMAL',
                         'COMPOSTAJE',
                         'ECOEFICIENCIA',
                         'GESTION_RESIDUOS'
                     )),
    fecha_inicio     TIMESTAMPTZ NOT NULL,
    duracion_minutos SMALLINT NOT NULL CHECK (duracion_minutos > 0),
    cupo_maximo      INTEGER NOT NULL DEFAULT 50 CHECK (cupo_maximo > 0),
    estado           VARCHAR(20) NOT NULL DEFAULT 'PROGRAMADA' CHECK (estado IN (
                         'PROGRAMADA', 'EJECUTADA', 'VALIDADA', 'CANCELADA'
                     ))
);

CREATE INDEX IF NOT EXISTS idx_sesion_meta_anual_id ON sesion(meta_anual_id);
CREATE INDEX IF NOT EXISTS idx_sesion_estado ON sesion(estado);
CREATE INDEX IF NOT EXISTS idx_sesion_eje_tematico ON sesion(eje_tematico);
CREATE INDEX IF NOT EXISTS idx_sesion_organizacion_fecha ON sesion(organizacion_id, fecha_inicio);
CREATE INDEX IF NOT EXISTS idx_sesion_responsable_fecha ON sesion(responsable_id, fecha_inicio);


-- ==============================================================================
-- Tabla: asistencia
-- Descripción: Registro de participantes por sesión y su calificación
-- ==============================================================================

CREATE TABLE IF NOT EXISTS asistencia (
    sesion_id        BIGINT NOT NULL REFERENCES sesion(id) ON DELETE CASCADE,
    persona_id       BIGINT NOT NULL REFERENCES persona(id) ON DELETE RESTRICT,
    participacion    VARCHAR(20) NOT NULL DEFAULT 'ASISTENTE' CHECK (participacion IN (
                         'ASISTENTE', 'VOLUNTARIO_REPLICA', 'PONENTE'
                     )),
    calificacion     NUMERIC(4, 2) CHECK (calificacion >= 0 AND calificacion <= 20),
    metodo_registro  VARCHAR(15) NOT NULL DEFAULT 'MANUAL' CHECK (metodo_registro IN (
                         'MANUAL', 'QR_GPS'
                     )),
    distancia_metros NUMERIC(8, 2) CHECK (distancia_metros IS NULL OR distancia_metros >= 0),
    registrado_at    TIMESTAMPTZ NOT NULL DEFAULT NOW(),
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


-- ==============================================================================
-- Tabla: inscripcion
-- Descripción: Inscripciones de capacitandos a sesiones educativas EDUCCA
-- ==============================================================================

CREATE TABLE IF NOT EXISTS inscripcion (
    id         BIGSERIAL PRIMARY KEY,
    sesion_id  BIGINT NOT NULL REFERENCES sesion(id) ON DELETE CASCADE,
    persona_id BIGINT NOT NULL REFERENCES persona(id) ON DELETE RESTRICT,
    estado     VARCHAR(15) NOT NULL DEFAULT 'INSCRITO' CHECK (estado IN (
                   'INSCRITO', 'CANCELADO'
               )),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE (sesion_id, persona_id)
);

CREATE INDEX IF NOT EXISTS idx_inscripcion_sesion_estado ON inscripcion(sesion_id, estado);
CREATE INDEX IF NOT EXISTS idx_inscripcion_persona_id ON inscripcion(persona_id);

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
    WHERE (p.dni = p_identificador OR LOWER(p.email) = LOWER(p_identificador))
      AND p.password_hash IS NOT NULL
      AND p.anonimizado = FALSE
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
          AND p.anonimizado = FALSE
          AND pm.clave = p_clave
    );
$$;


-- ==============================================================================
-- Funciones: Persona, registro ciudadano LPDP, roles y derechos ARCO
-- ==============================================================================

CREATE OR REPLACE FUNCTION fn_persona_listar()
RETURNS TABLE (
    id                     BIGINT,
    dni                    VARCHAR,
    nombres                VARCHAR,
    apellidos              VARCHAR,
    sexo                   CHAR(1),
    fecha_nacimiento       DATE,
    telefono               VARCHAR,
    email                  VARCHAR,
    categoria              VARCHAR,
    consentimiento_at      TIMESTAMPTZ,
    consentimiento_version VARCHAR,
    anonimizado            BOOLEAN,
    activo                 BOOLEAN
)
LANGUAGE sql
STABLE
AS $$
    SELECT p.id, p.dni, p.nombres, p.apellidos, p.sexo, p.fecha_nacimiento,
           p.telefono, p.email, p.categoria, p.consentimiento_at,
           p.consentimiento_version, p.anonimizado, p.activo
    FROM persona p
    ORDER BY p.id;
$$;

CREATE OR REPLACE FUNCTION fn_persona_obtener(p_id BIGINT)
RETURNS TABLE (
    id                     BIGINT,
    dni                    VARCHAR,
    nombres                VARCHAR,
    apellidos              VARCHAR,
    sexo                   CHAR(1),
    fecha_nacimiento       DATE,
    telefono               VARCHAR,
    email                  VARCHAR,
    categoria              VARCHAR,
    consentimiento_at      TIMESTAMPTZ,
    consentimiento_version VARCHAR,
    anonimizado            BOOLEAN,
    activo                 BOOLEAN
)
LANGUAGE sql
STABLE
AS $$
    SELECT p.id, p.dni, p.nombres, p.apellidos, p.sexo, p.fecha_nacimiento,
           p.telefono, p.email, p.categoria, p.consentimiento_at,
           p.consentimiento_version, p.anonimizado, p.activo
    FROM persona p
    WHERE p.id = p_id;
$$;

CREATE OR REPLACE FUNCTION fn_persona_crear(
    p_dni                    VARCHAR,
    p_nombres                VARCHAR,
    p_apellidos              VARCHAR,
    p_sexo                   CHAR(1),
    p_fecha_nacimiento       DATE,
    p_telefono               VARCHAR,
    p_email                  VARCHAR,
    p_password_hash          TEXT,
    p_activo                 BOOLEAN,
    p_categoria              VARCHAR DEFAULT NULL,
    p_consentimiento_at      TIMESTAMPTZ DEFAULT NULL,
    p_consentimiento_version VARCHAR DEFAULT NULL
)
RETURNS BIGINT
LANGUAGE sql
AS $$
    INSERT INTO persona (
        dni, nombres, apellidos, sexo, fecha_nacimiento,
        telefono, email, password_hash, activo,
        categoria, consentimiento_at, consentimiento_version
    )
    VALUES (
        BTRIM(p_dni),
        BTRIM(p_nombres),
        BTRIM(p_apellidos),
        p_sexo,
        p_fecha_nacimiento,
        NULLIF(BTRIM(p_telefono), ''),
        LOWER(NULLIF(BTRIM(p_email), '')),
        p_password_hash,
        COALESCE(p_activo, TRUE),
        NULLIF(BTRIM(p_categoria), ''),
        p_consentimiento_at,
        NULLIF(BTRIM(p_consentimiento_version), '')
    )
    RETURNING id;
$$;

CREATE OR REPLACE FUNCTION fn_persona_registrar_capacitando(
    p_dni                    VARCHAR,
    p_nombres                VARCHAR,
    p_apellidos              VARCHAR,
    p_sexo                   CHAR(1),
    p_fecha_nacimiento       DATE,
    p_telefono               VARCHAR,
    p_email                  VARCHAR,
    p_password_hash          TEXT,
    p_categoria              VARCHAR,
    p_consentimiento_version VARCHAR DEFAULT 'v1.0-2026'
)
RETURNS BIGINT
LANGUAGE plpgsql
AS $$
DECLARE
    v_persona_id BIGINT;
    v_rol_id     SMALLINT;
BEGIN
    SELECT id INTO v_rol_id FROM rol WHERE nombre = 'capacitando';
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Rol capacitando no configurado' USING ERRCODE = 'P0002';
    END IF;

    INSERT INTO persona (
        dni, nombres, apellidos, sexo, fecha_nacimiento,
        telefono, email, password_hash, categoria,
        consentimiento_at, consentimiento_version, anonimizado, activo
    )
    VALUES (
        BTRIM(p_dni),
        BTRIM(p_nombres),
        BTRIM(p_apellidos),
        p_sexo,
        p_fecha_nacimiento,
        NULLIF(BTRIM(p_telefono), ''),
        LOWER(NULLIF(BTRIM(p_email), '')),
        p_password_hash,
        NULLIF(BTRIM(p_categoria), ''),
        NOW(),
        COALESCE(NULLIF(BTRIM(p_consentimiento_version), ''), 'v1.0-2026'),
        FALSE,
        TRUE
    )
    RETURNING id INTO v_persona_id;

    INSERT INTO persona_rol (persona_id, rol_id)
    VALUES (v_persona_id, v_rol_id)
    ON CONFLICT (persona_id, rol_id) DO NOTHING;

    RETURN v_persona_id;
END;
$$;

CREATE OR REPLACE FUNCTION fn_persona_actualizar(
    p_id               BIGINT,
    p_dni              VARCHAR,
    p_nombres          VARCHAR,
    p_apellidos        VARCHAR,
    p_sexo             CHAR(1),
    p_fecha_nacimiento DATE,
    p_telefono         VARCHAR,
    p_email            VARCHAR,
    p_categoria        VARCHAR DEFAULT NULL
)
RETURNS BOOLEAN
LANGUAGE plpgsql
AS $$
DECLARE
    v_anonimizado BOOLEAN;
BEGIN
    SELECT anonimizado INTO v_anonimizado FROM persona WHERE id = p_id;
    IF NOT FOUND THEN
        RETURN FALSE;
    END IF;

    IF v_anonimizado THEN
        RAISE EXCEPTION 'No se puede modificar una persona anonimizada' USING ERRCODE = 'P0001';
    END IF;

    UPDATE persona
    SET dni = BTRIM(p_dni),
        nombres = BTRIM(p_nombres),
        apellidos = BTRIM(p_apellidos),
        sexo = p_sexo,
        fecha_nacimiento = p_fecha_nacimiento,
        telefono = NULLIF(BTRIM(p_telefono), ''),
        email = LOWER(NULLIF(BTRIM(p_email), '')),
        categoria = COALESCE(NULLIF(BTRIM(p_categoria), ''), categoria)
    WHERE id = p_id;
    RETURN FOUND;
END;
$$;

CREATE OR REPLACE FUNCTION fn_persona_cambiar_activo(p_id BIGINT, p_activo BOOLEAN)
RETURNS BOOLEAN
LANGUAGE plpgsql
AS $$
DECLARE
    v_anonimizado BOOLEAN;
BEGIN
    SELECT anonimizado INTO v_anonimizado FROM persona WHERE id = p_id;
    IF NOT FOUND THEN
        RETURN FALSE;
    END IF;

    IF v_anonimizado THEN
        RAISE EXCEPTION 'No se puede activar o modificar una persona anonimizada' USING ERRCODE = 'P0001';
    END IF;

    UPDATE persona SET activo = p_activo WHERE id = p_id;
    RETURN FOUND;
END;
$$;

CREATE OR REPLACE FUNCTION fn_persona_cambiar_password(p_id BIGINT, p_password_hash TEXT)
RETURNS BOOLEAN
LANGUAGE plpgsql
AS $$
DECLARE
    v_anonimizado BOOLEAN;
BEGIN
    SELECT anonimizado INTO v_anonimizado FROM persona WHERE id = p_id;
    IF NOT FOUND THEN
        RETURN FALSE;
    END IF;

    IF v_anonimizado THEN
        RAISE EXCEPTION 'No se puede cambiar la contrasena de una persona anonimizada' USING ERRCODE = 'P0001';
    END IF;

    UPDATE persona SET password_hash = p_password_hash WHERE id = p_id;
    RETURN FOUND;
END;
$$;

CREATE OR REPLACE FUNCTION fn_persona_anonimizar_arco(p_id BIGINT)
RETURNS BOOLEAN
LANGUAGE plpgsql
AS $$
DECLARE
    v_anonimizado BOOLEAN;
BEGIN
    SELECT anonimizado INTO v_anonimizado FROM persona WHERE id = p_id FOR UPDATE;
    IF NOT FOUND THEN
        RETURN FALSE;
    END IF;

    IF v_anonimizado THEN
        RAISE EXCEPTION 'La persona ya se encuentra anonimizada' USING ERRCODE = 'P0001';
    END IF;

    IF EXISTS (
        SELECT 1
        FROM persona_rol pr
        JOIN rol r ON r.id = pr.rol_id
        WHERE pr.persona_id = p_id AND r.nombre = 'admin'
    ) THEN
        RAISE EXCEPTION 'No se puede anonimizar una cuenta con rol admin' USING ERRCODE = 'P0001';
    END IF;

    UPDATE persona
    SET dni = 'ANON_' || id::VARCHAR,
        nombres = 'ANONIMIZADO',
        apellidos = 'ANONIMIZADO',
        fecha_nacimiento = DATE '1900-01-01',
        telefono = NULL,
        email = NULL,
        password_hash = NULL,
        activo = FALSE,
        anonimizado = TRUE
    WHERE id = p_id;

    UPDATE promotor_periodo
    SET codigo_certificado = NULL,
        estado = 'RETIRADO'
    WHERE persona_id = p_id;

    UPDATE inscripcion i
    SET estado = 'CANCELADO'
    FROM sesion s
    WHERE i.sesion_id = s.id
      AND i.persona_id = p_id
      AND i.estado = 'INSCRITO'
      AND s.estado = 'PROGRAMADA';

    RETURN TRUE;
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
-- Funciones: Sesion Educativa, Solapamiento Horario y Cupos
-- ==============================================================================

CREATE OR REPLACE FUNCTION fn_sesion_listar(
    p_meta_anual_id   BIGINT DEFAULT NULL,
    p_estado          VARCHAR DEFAULT NULL,
    p_eje_tematico    VARCHAR DEFAULT NULL,
    p_organizacion_id BIGINT DEFAULT NULL
)
RETURNS TABLE (
    id                 BIGINT,
    meta_anual_id      BIGINT,
    organizacion_id    BIGINT,
    responsable_id     BIGINT,
    titulo             VARCHAR,
    modalidad          VARCHAR,
    eje_tematico       VARCHAR,
    fecha_inicio       TIMESTAMPTZ,
    duracion_minutos   SMALLINT,
    cupo_maximo        INTEGER,
    inscritos_actuales INTEGER,
    cupos_disponibles  INTEGER,
    estado             VARCHAR
)
LANGUAGE sql
STABLE
AS $$
    SELECT s.id,
           s.meta_anual_id,
           s.organizacion_id,
           s.responsable_id,
           s.titulo,
           s.modalidad,
           s.eje_tematico,
           s.fecha_inicio,
           s.duracion_minutos,
           s.cupo_maximo,
           COALESCE(ic.inscritos, 0)::INTEGER AS inscritos_actuales,
           GREATEST(s.cupo_maximo - COALESCE(ic.inscritos, 0), 0)::INTEGER AS cupos_disponibles,
           s.estado
    FROM sesion s
    LEFT JOIN (
        SELECT sesion_id, COUNT(*)::INTEGER AS inscritos
        FROM inscripcion
        WHERE estado = 'INSCRITO'
        GROUP BY sesion_id
    ) ic ON ic.sesion_id = s.id
    WHERE (p_meta_anual_id IS NULL OR s.meta_anual_id = p_meta_anual_id)
      AND (p_estado IS NULL OR s.estado = p_estado)
      AND (p_eje_tematico IS NULL OR s.eje_tematico = p_eje_tematico)
      AND (p_organizacion_id IS NULL OR s.organizacion_id = p_organizacion_id)
    ORDER BY s.fecha_inicio DESC, s.id DESC;
$$;

CREATE OR REPLACE FUNCTION fn_sesion_obtener(p_id BIGINT)
RETURNS TABLE (
    id                 BIGINT,
    meta_anual_id      BIGINT,
    organizacion_id    BIGINT,
    responsable_id     BIGINT,
    titulo             VARCHAR,
    modalidad          VARCHAR,
    eje_tematico       VARCHAR,
    fecha_inicio       TIMESTAMPTZ,
    duracion_minutos   SMALLINT,
    cupo_maximo        INTEGER,
    inscritos_actuales INTEGER,
    cupos_disponibles  INTEGER,
    estado             VARCHAR
)
LANGUAGE sql
STABLE
AS $$
    SELECT s.id,
           s.meta_anual_id,
           s.organizacion_id,
           s.responsable_id,
           s.titulo,
           s.modalidad,
           s.eje_tematico,
           s.fecha_inicio,
           s.duracion_minutos,
           s.cupo_maximo,
           COALESCE(ic.inscritos, 0)::INTEGER AS inscritos_actuales,
           GREATEST(s.cupo_maximo - COALESCE(ic.inscritos, 0), 0)::INTEGER AS cupos_disponibles,
           s.estado
    FROM sesion s
    LEFT JOIN (
        SELECT sesion_id, COUNT(*)::INTEGER AS inscritos
        FROM inscripcion
        WHERE estado = 'INSCRITO'
        GROUP BY sesion_id
    ) ic ON ic.sesion_id = s.id
    WHERE s.id = p_id;
$$;

CREATE OR REPLACE FUNCTION fn_sesion_crear(
    p_meta_anual_id    BIGINT,
    p_organizacion_id  BIGINT,
    p_responsable_id   BIGINT,
    p_titulo           VARCHAR,
    p_modalidad        VARCHAR,
    p_eje_tematico     VARCHAR,
    p_fecha_inicio     TIMESTAMPTZ,
    p_duracion_minutos SMALLINT,
    p_cupo_maximo      INTEGER DEFAULT 50
)
RETURNS BIGINT
LANGUAGE plpgsql
AS $$
DECLARE
    v_fecha_fin TIMESTAMPTZ;
    v_id        BIGINT;
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM persona p
        WHERE p.id = p_responsable_id AND p.activo = TRUE AND p.anonimizado = FALSE
    ) THEN
        RAISE EXCEPTION 'El capacitador responsable no existe o no se encuentra activo' USING ERRCODE = 'P0001';
    END IF;

    v_fecha_fin := p_fecha_inicio + (p_duracion_minutos * INTERVAL '1 minute');

    IF p_organizacion_id IS NOT NULL AND EXISTS (
        SELECT 1 FROM sesion s
        WHERE s.organizacion_id = p_organizacion_id
          AND s.estado <> 'CANCELADA'
          AND p_fecha_inicio < (s.fecha_inicio + (s.duracion_minutos * INTERVAL '1 minute'))
          AND s.fecha_inicio < v_fecha_fin
    ) THEN
        RAISE EXCEPTION 'Solapamiento horario: ya existe una sesion programada en la misma sede durante ese horario' USING ERRCODE = 'P0001';
    END IF;

    IF EXISTS (
        SELECT 1 FROM sesion s
        WHERE s.responsable_id = p_responsable_id
          AND s.estado <> 'CANCELADA'
          AND p_fecha_inicio < (s.fecha_inicio + (s.duracion_minutos * INTERVAL '1 minute'))
          AND s.fecha_inicio < v_fecha_fin
    ) THEN
        RAISE EXCEPTION 'Solapamiento horario: el capacitador ya tiene otra sesion asignada durante ese horario' USING ERRCODE = 'P0001';
    END IF;

    INSERT INTO sesion (
        meta_anual_id, organizacion_id, responsable_id,
        titulo, modalidad, eje_tematico,
        fecha_inicio, duracion_minutos, cupo_maximo
    )
    VALUES (
        p_meta_anual_id,
        p_organizacion_id,
        p_responsable_id,
        BTRIM(p_titulo),
        p_modalidad,
        COALESCE(NULLIF(BTRIM(p_eje_tematico), ''), 'SEGREGACION_RECICLA'),
        p_fecha_inicio,
        p_duracion_minutos,
        COALESCE(NULLIF(p_cupo_maximo, 0), 50)
    )
    RETURNING id INTO v_id;

    RETURN v_id;
END;
$$;

CREATE OR REPLACE FUNCTION fn_sesion_actualizar(
    p_id               BIGINT,
    p_meta_anual_id    BIGINT,
    p_organizacion_id  BIGINT,
    p_responsable_id   BIGINT,
    p_titulo           VARCHAR,
    p_modalidad        VARCHAR,
    p_eje_tematico     VARCHAR,
    p_fecha_inicio     TIMESTAMPTZ,
    p_duracion_minutos SMALLINT,
    p_cupo_maximo      INTEGER DEFAULT 50
)
RETURNS BOOLEAN
LANGUAGE plpgsql
AS $$
DECLARE
    v_estado     VARCHAR(20);
    v_fecha_fin  TIMESTAMPTZ;
    v_cupo_final INTEGER;
    v_inscritos  INTEGER;
BEGIN
    SELECT estado INTO v_estado FROM sesion WHERE id = p_id FOR UPDATE;
    IF NOT FOUND THEN
        RETURN FALSE;
    END IF;

    IF v_estado IN ('VALIDADA', 'CANCELADA') THEN
        RAISE EXCEPTION 'No se puede modificar una sesion en estado %', v_estado USING ERRCODE = 'P0001';
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM persona p
        WHERE p.id = p_responsable_id AND p.activo = TRUE AND p.anonimizado = FALSE
    ) THEN
        RAISE EXCEPTION 'El capacitador responsable no existe o no se encuentra activo' USING ERRCODE = 'P0001';
    END IF;

    v_cupo_final := COALESCE(NULLIF(p_cupo_maximo, 0), 50);
    SELECT COUNT(*)::INTEGER INTO v_inscritos
    FROM inscripcion
    WHERE sesion_id = p_id AND estado = 'INSCRITO';

    IF v_cupo_final < v_inscritos THEN
        RAISE EXCEPTION 'El cupo maximo (%) no puede ser menor al numero actual de inscritos (%)', v_cupo_final, v_inscritos USING ERRCODE = 'P0001';
    END IF;

    v_fecha_fin := p_fecha_inicio + (p_duracion_minutos * INTERVAL '1 minute');

    IF p_organizacion_id IS NOT NULL AND EXISTS (
        SELECT 1 FROM sesion s
        WHERE s.organizacion_id = p_organizacion_id
          AND s.id <> p_id
          AND s.estado <> 'CANCELADA'
          AND p_fecha_inicio < (s.fecha_inicio + (s.duracion_minutos * INTERVAL '1 minute'))
          AND s.fecha_inicio < v_fecha_fin
    ) THEN
        RAISE EXCEPTION 'Solapamiento horario: ya existe una sesion programada en la misma sede durante ese horario' USING ERRCODE = 'P0001';
    END IF;

    IF EXISTS (
        SELECT 1 FROM sesion s
        WHERE s.responsable_id = p_responsable_id
          AND s.id <> p_id
          AND s.estado <> 'CANCELADA'
          AND p_fecha_inicio < (s.fecha_inicio + (s.duracion_minutos * INTERVAL '1 minute'))
          AND s.fecha_inicio < v_fecha_fin
    ) THEN
        RAISE EXCEPTION 'Solapamiento horario: el capacitador ya tiene otra sesion asignada durante ese horario' USING ERRCODE = 'P0001';
    END IF;

    UPDATE sesion
    SET meta_anual_id = p_meta_anual_id,
        organizacion_id = p_organizacion_id,
        responsable_id = p_responsable_id,
        titulo = BTRIM(p_titulo),
        modalidad = p_modalidad,
        eje_tematico = COALESCE(NULLIF(BTRIM(p_eje_tematico), ''), eje_tematico),
        fecha_inicio = p_fecha_inicio,
        duracion_minutos = p_duracion_minutos,
        cupo_maximo = v_cupo_final
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
-- Funciones: Asistencia Manual, Check-in QR + GPS e Historial del Capacitando
-- ==============================================================================

CREATE OR REPLACE FUNCTION fn_asistencia_listar_por_sesion(p_sesion_id BIGINT)
RETURNS TABLE (
    sesion_id        BIGINT,
    persona_id       BIGINT,
    participacion    VARCHAR,
    calificacion     NUMERIC,
    metodo_registro  VARCHAR,
    distancia_metros NUMERIC,
    registrado_at    TIMESTAMPTZ
)
LANGUAGE plpgsql
STABLE
AS $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM sesion s WHERE s.id = p_sesion_id) THEN
        RAISE EXCEPTION 'Sesion no encontrada' USING ERRCODE = 'P0002';
    END IF;

    RETURN QUERY
    SELECT a.sesion_id, a.persona_id, a.participacion, a.calificacion,
           a.metodo_registro, a.distancia_metros, a.registrado_at
    FROM asistencia a
    WHERE a.sesion_id = p_sesion_id
    ORDER BY a.registrado_at ASC, a.persona_id ASC;
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

    INSERT INTO asistencia (sesion_id, persona_id, participacion, calificacion, metodo_registro, registrado_at)
    VALUES (p_sesion_id, p_persona_id, COALESCE(NULLIF(BTRIM(p_participacion), ''), 'ASISTENTE'), p_calificacion, 'MANUAL', NOW())
    ON CONFLICT (sesion_id, persona_id) DO UPDATE SET
        participacion = COALESCE(NULLIF(BTRIM(EXCLUDED.participacion), ''), asistencia.participacion),
        calificacion = EXCLUDED.calificacion;
END;
$$;

CREATE OR REPLACE FUNCTION fn_asistencia_checkin_qr(
    p_sesion_id        BIGINT,
    p_persona_id       BIGINT,
    p_distancia_metros NUMERIC
)
RETURNS VOID
LANGUAGE plpgsql
AS $$
DECLARE
    v_estado      VARCHAR(20);
    v_modalidad   VARCHAR(15);
    v_cupo_maximo INTEGER;
    v_inscritos   INTEGER;
BEGIN
    SELECT estado, modalidad, cupo_maximo
    INTO v_estado, v_modalidad, v_cupo_maximo
    FROM sesion
    WHERE id = p_sesion_id
    FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Sesion no encontrada' USING ERRCODE = 'P0002';
    END IF;

    IF v_modalidad <> 'PRESENCIAL' THEN
        RAISE EXCEPTION 'El check-in con QR y GPS solo aplica a sesiones presenciales' USING ERRCODE = 'P0001';
    END IF;

    IF v_estado IN ('VALIDADA', 'CANCELADA') THEN
        RAISE EXCEPTION 'No se puede registrar asistencia en una sesion en estado %', v_estado USING ERRCODE = 'P0001';
    END IF;

    IF EXISTS (
        SELECT 1 FROM asistencia
        WHERE sesion_id = p_sesion_id AND persona_id = p_persona_id
    ) THEN
        RAISE EXCEPTION 'La asistencia ya fue registrada para esta sesion' USING ERRCODE = '23505';
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM inscripcion
        WHERE sesion_id = p_sesion_id AND persona_id = p_persona_id AND estado = 'INSCRITO'
    ) THEN
        SELECT COUNT(*)::INTEGER INTO v_inscritos
        FROM inscripcion
        WHERE sesion_id = p_sesion_id AND estado = 'INSCRITO';

        IF v_inscritos >= v_cupo_maximo THEN
            RAISE EXCEPTION 'No hay cupos disponibles en esta sesion para registrar nuevos participantes' USING ERRCODE = 'P0001';
        END IF;

        INSERT INTO inscripcion (sesion_id, persona_id, estado, created_at)
        VALUES (p_sesion_id, p_persona_id, 'INSCRITO', NOW())
        ON CONFLICT (sesion_id, persona_id) DO UPDATE SET
            estado = 'INSCRITO',
            created_at = NOW();
    END IF;

    INSERT INTO asistencia (
        sesion_id, persona_id, participacion, calificacion,
        metodo_registro, distancia_metros, registrado_at
    )
    VALUES (
        p_sesion_id,
        p_persona_id,
        'ASISTENTE',
        NULL,
        'QR_GPS',
        ROUND(p_distancia_metros, 2),
        NOW()
    );
END;
$$;

CREATE OR REPLACE FUNCTION fn_asistencia_listar_por_persona(p_persona_id BIGINT)
RETURNS TABLE (
    sesion_id        BIGINT,
    titulo           VARCHAR,
    eje_tematico     VARCHAR,
    modalidad        VARCHAR,
    fecha_inicio     TIMESTAMPTZ,
    estado_sesion    VARCHAR,
    participacion    VARCHAR,
    calificacion     NUMERIC,
    metodo_registro  VARCHAR,
    distancia_metros NUMERIC,
    registrado_at    TIMESTAMPTZ
)
LANGUAGE sql
STABLE
AS $$
    SELECT a.sesion_id,
           s.titulo,
           s.eje_tematico,
           s.modalidad,
           s.fecha_inicio,
           s.estado AS estado_sesion,
           a.participacion,
           a.calificacion,
           a.metodo_registro,
           a.distancia_metros,
           a.registrado_at
    FROM asistencia a
    JOIN sesion s ON s.id = a.sesion_id
    WHERE a.persona_id = p_persona_id
    ORDER BY s.fecha_inicio DESC, s.id DESC;
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


-- ==============================================================================
-- Funciones: Inscripcion de Capacitandos a Sesiones
-- ==============================================================================

CREATE OR REPLACE FUNCTION fn_inscripcion_crear(
    p_sesion_id  BIGINT,
    p_persona_id BIGINT
)
RETURNS BIGINT
LANGUAGE plpgsql
AS $$
DECLARE
    v_estado      VARCHAR(20);
    v_cupo_maximo INTEGER;
    v_inscritos   INTEGER;
    v_id          BIGINT;
BEGIN
    SELECT estado, cupo_maximo
    INTO v_estado, v_cupo_maximo
    FROM sesion
    WHERE id = p_sesion_id
    FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Sesion no encontrada' USING ERRCODE = 'P0002';
    END IF;

    IF v_estado <> 'PROGRAMADA' THEN
        RAISE EXCEPTION 'Solo se permite la inscripcion en sesiones con estado PROGRAMADA' USING ERRCODE = 'P0001';
    END IF;

    IF EXISTS (
        SELECT 1 FROM inscripcion
        WHERE sesion_id = p_sesion_id AND persona_id = p_persona_id AND estado = 'INSCRITO'
    ) THEN
        RAISE EXCEPTION 'El usuario ya se encuentra inscrito en esta sesion' USING ERRCODE = '23505';
    END IF;

    SELECT COUNT(*)::INTEGER INTO v_inscritos
    FROM inscripcion
    WHERE sesion_id = p_sesion_id AND estado = 'INSCRITO';

    IF v_inscritos >= v_cupo_maximo THEN
        RAISE EXCEPTION 'La sesion ha alcanzado el cupo maximo permitido (%)' , v_cupo_maximo USING ERRCODE = 'P0001';
    END IF;

    INSERT INTO inscripcion (sesion_id, persona_id, estado, created_at)
    VALUES (p_sesion_id, p_persona_id, 'INSCRITO', NOW())
    ON CONFLICT (sesion_id, persona_id) DO UPDATE SET
        estado = 'INSCRITO',
        created_at = NOW()
    RETURNING id INTO v_id;

    RETURN v_id;
END;
$$;

CREATE OR REPLACE FUNCTION fn_inscripcion_cancelar(
    p_sesion_id  BIGINT,
    p_persona_id BIGINT
)
RETURNS BOOLEAN
LANGUAGE plpgsql
AS $$
DECLARE
    v_estado_sesion VARCHAR(20);
    v_fecha_inicio  TIMESTAMPTZ;
    v_estado_insc   VARCHAR(15);
BEGIN
    SELECT estado, fecha_inicio
    INTO v_estado_sesion, v_fecha_inicio
    FROM sesion
    WHERE id = p_sesion_id
    FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Sesion no encontrada' USING ERRCODE = 'P0002';
    END IF;

    SELECT estado INTO v_estado_insc
    FROM inscripcion
    WHERE sesion_id = p_sesion_id AND persona_id = p_persona_id;

    IF NOT FOUND OR v_estado_insc = 'CANCELADO' THEN
        RETURN FALSE;
    END IF;

    IF v_estado_sesion <> 'PROGRAMADA' OR NOW() >= v_fecha_inicio THEN
        RAISE EXCEPTION 'Solo se puede cancelar la inscripcion antes del inicio de una sesion PROGRAMADA' USING ERRCODE = 'P0001';
    END IF;

    UPDATE inscripcion
    SET estado = 'CANCELADO'
    WHERE sesion_id = p_sesion_id AND persona_id = p_persona_id;

    RETURN TRUE;
END;
$$;

CREATE OR REPLACE FUNCTION fn_inscripcion_listar_por_sesion(p_sesion_id BIGINT)
RETURNS TABLE (
    id         BIGINT,
    sesion_id  BIGINT,
    persona_id BIGINT,
    dni        VARCHAR,
    nombres    VARCHAR,
    apellidos  VARCHAR,
    categoria  VARCHAR,
    estado     VARCHAR,
    created_at TIMESTAMPTZ
)
LANGUAGE plpgsql
STABLE
AS $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM sesion s WHERE s.id = p_sesion_id) THEN
        RAISE EXCEPTION 'Sesion no encontrada' USING ERRCODE = 'P0002';
    END IF;

    RETURN QUERY
    SELECT i.id,
           i.sesion_id,
           i.persona_id,
           p.dni,
           p.nombres,
           p.apellidos,
           p.categoria,
           i.estado,
           i.created_at
    FROM inscripcion i
    JOIN persona p ON p.id = i.persona_id
    WHERE i.sesion_id = p_sesion_id
    ORDER BY i.created_at ASC, i.id ASC;
END;
$$;

CREATE OR REPLACE FUNCTION fn_inscripcion_listar_por_persona(p_persona_id BIGINT)
RETURNS TABLE (
    id               BIGINT,
    sesion_id        BIGINT,
    titulo           VARCHAR,
    eje_tematico     VARCHAR,
    modalidad        VARCHAR,
    fecha_inicio     TIMESTAMPTZ,
    duracion_minutos SMALLINT,
    organizacion_id  BIGINT,
    estado_sesion    VARCHAR,
    estado           VARCHAR,
    created_at       TIMESTAMPTZ
)
LANGUAGE sql
STABLE
AS $$
    SELECT i.id,
           i.sesion_id,
           s.titulo,
           s.eje_tematico,
           s.modalidad,
           s.fecha_inicio,
           s.duracion_minutos,
           s.organizacion_id,
           s.estado AS estado_sesion,
           i.estado,
           i.created_at
    FROM inscripcion i
    JOIN sesion s ON s.id = i.sesion_id
    WHERE i.persona_id = p_persona_id
    ORDER BY s.fecha_inicio DESC, i.id DESC;
$$;

-- ================= DATOS SEMILLA =================

-- ==============================================================================
-- Datos iniciales: rol
-- ==============================================================================

INSERT INTO rol (nombre, descripcion) VALUES
    ('admin', 'Administrador del sistema EDUCCA con acceso total'),
    ('coordinador', 'Coordinador municipal responsable de metas, sedes, sesiones, validaciones y ARCO'),
    ('capacitador', 'Capacitador ambiental encargado de dictar talleres, generar QR y registrar asistencias'),
    ('capacitando', 'Ciudadano participante que se inscribe a talleres, marca asistencia QR+GPS y consulta su avance'),
    ('consulta', 'Usuario con acceso de solo lectura a catálogo y reportes agregados')
ON CONFLICT (nombre) DO UPDATE SET
    descripcion = EXCLUDED.descripcion;


-- ==============================================================================
-- Datos iniciales: permiso
-- ==============================================================================

INSERT INTO permiso (clave, descripcion) VALUES
    ('personas:leer', 'Consultar personas registradas'),
    ('personas:escribir', 'Registrar y actualizar personas'),
    ('roles:gestionar', 'Administrar roles y permisos'),
    ('organizaciones:leer', 'Consultar organizaciones y sedes registradas'),
    ('organizaciones:escribir', 'Registrar y actualizar organizaciones y sedes georreferenciadas'),
    ('metas:leer', 'Consultar metas anuales MINAM'),
    ('metas:escribir', 'Programar y actualizar metas anuales'),
    ('promotores:leer', 'Consultar promotores por periodo'),
    ('promotores:escribir', 'Inscribir y acreditar promotores'),
    ('sesiones:leer', 'Consultar catálogo de sesiones educativas'),
    ('sesiones:crear', 'Programar, actualizar y eliminar sesiones educativas'),
    ('sesiones:validar', 'Validar o cancelar sesiones ejecutadas'),
    ('sesiones:qr', 'Generar, consultar y revocar código QR dinámico y monitorear sesión en tiempo real'),
    ('inscripciones:leer', 'Consultar lista de inscritos de una sesión'),
    ('inscripciones:gestionar', 'Inscribirse, cancelar inscripción propia y consultar talleres inscritos'),
    ('asistencias:registrar', 'Registrar y consultar asistencia y calificaciones de una sesión'),
    ('asistencias:checkin_qr', 'Registrar asistencia presencial con QR y GPS y consultar historial propio'),
    ('archivos:subir', 'Adjuntar evidencias, actas y material didáctico a sesiones'),
    ('reportes:exportar', 'Exportar reportes consolidados EDUCCA'),
    ('arco:gestionar', 'Gestionar exportación y anonimización de datos personales conforme a la LPDP (ARCO)')
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
    'sesiones:leer', 'sesiones:crear', 'sesiones:validar', 'sesiones:qr',
    'inscripciones:leer', 'inscripciones:gestionar',
    'asistencias:registrar', 'asistencias:checkin_qr',
    'archivos:subir', 'reportes:exportar', 'arco:gestionar'
)
WHERE r.nombre = 'coordinador'
ON CONFLICT (rol_id, permiso_id) DO NOTHING;

INSERT INTO rol_permiso (rol_id, permiso_id)
SELECT r.id, p.id
FROM rol r
JOIN permiso p ON p.clave IN (
    'organizaciones:leer', 'metas:leer', 'promotores:leer',
    'sesiones:leer', 'sesiones:qr',
    'inscripciones:leer',
    'asistencias:registrar', 'archivos:subir'
)
WHERE r.nombre = 'capacitador'
ON CONFLICT (rol_id, permiso_id) DO NOTHING;

INSERT INTO rol_permiso (rol_id, permiso_id)
SELECT r.id, p.id
FROM rol r
JOIN permiso p ON p.clave IN (
    'organizaciones:leer', 'sesiones:leer',
    'inscripciones:gestionar', 'asistencias:checkin_qr'
)
WHERE r.nombre = 'capacitando'
ON CONFLICT (rol_id, permiso_id) DO NOTHING;

INSERT INTO rol_permiso (rol_id, permiso_id)
SELECT r.id, p.id
FROM rol r
JOIN permiso p ON p.clave IN (
    'organizaciones:leer', 'metas:leer',
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
