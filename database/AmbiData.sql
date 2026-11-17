-- ==============================================================================
-- AMBIDATA DATABASE
-- Esquema consolidado de tablas y datos iniciales para MariaDB (EDUCCA).
-- Autogenerado mediante database/AmbiData.sh
-- ==============================================================================

SET NAMES utf8mb4;
SET FOREIGN_KEY_CHECKS = 0;

-- ================= TABLAS =================

-- ==============================================================================
-- Tabla: persona
-- Descripción: Identidad única de personas del sistema EDUCCA
-- ==============================================================================

CREATE TABLE IF NOT EXISTS persona (
    id               BIGINT AUTO_INCREMENT PRIMARY KEY,
    dni              VARCHAR(12) NOT NULL UNIQUE,
    nombres          VARCHAR(100) NOT NULL,
    apellidos        VARCHAR(100) NOT NULL,
    sexo             CHAR(1) NOT NULL CHECK (sexo IN ('M', 'F')),
    fecha_nacimiento DATE NOT NULL,
    telefono         VARCHAR(15),
    email            VARCHAR(120) UNIQUE,
    password_hash    TEXT,
    activo           BOOLEAN NOT NULL DEFAULT TRUE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- ==============================================================================
-- Tabla: rol
-- Descripción: Roles del sistema para control de acceso (RBAC dinámico)
-- ==============================================================================

CREATE TABLE IF NOT EXISTS rol (
    id          SMALLINT AUTO_INCREMENT PRIMARY KEY,
    nombre      VARCHAR(50) NOT NULL UNIQUE,
    descripcion VARCHAR(150) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- ==============================================================================
-- Tabla: permiso
-- Descripción: Permisos granulares del sistema (ej. 'sesiones:crear')
-- ==============================================================================

CREATE TABLE IF NOT EXISTS permiso (
    id          SMALLINT AUTO_INCREMENT PRIMARY KEY,
    clave       VARCHAR(60) NOT NULL UNIQUE,
    descripcion VARCHAR(150) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- ==============================================================================
-- Tabla: rol_permiso
-- Descripción: Relación N:M entre roles y permisos
-- ==============================================================================

CREATE TABLE IF NOT EXISTS rol_permiso (
    rol_id     SMALLINT NOT NULL,
    permiso_id SMALLINT NOT NULL,
    PRIMARY KEY (rol_id, permiso_id),
    CONSTRAINT fk_rol_permiso_rol FOREIGN KEY (rol_id) REFERENCES rol(id) ON DELETE CASCADE,
    CONSTRAINT fk_rol_permiso_permiso FOREIGN KEY (permiso_id) REFERENCES permiso(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- ==============================================================================
-- Tabla: persona_rol
-- Descripción: Relación N:M entre personas y roles
-- ==============================================================================

CREATE TABLE IF NOT EXISTS persona_rol (
    persona_id BIGINT NOT NULL,
    rol_id     SMALLINT NOT NULL,
    PRIMARY KEY (persona_id, rol_id),
    CONSTRAINT fk_persona_rol_persona FOREIGN KEY (persona_id) REFERENCES persona(id) ON DELETE CASCADE,
    CONSTRAINT fk_persona_rol_rol FOREIGN KEY (rol_id) REFERENCES rol(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- ==============================================================================
-- Tabla: organizacion
-- Descripción: Instituciones, colegios, organizaciones sociales y EPEA
-- ==============================================================================

CREATE TABLE IF NOT EXISTS organizacion (
    id                   BIGINT AUTO_INCREMENT PRIMARY KEY,
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
    responsable_id       BIGINT,
    CONSTRAINT fk_organizacion_responsable FOREIGN KEY (responsable_id) REFERENCES persona(id) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- ==============================================================================
-- Tabla: meta_anual
-- Descripción: Metas anuales programadas según actividades MINAM
-- ==============================================================================

CREATE TABLE IF NOT EXISTS meta_anual (
    id              BIGINT AUTO_INCREMENT PRIMARY KEY,
    anio            SMALLINT NOT NULL CHECK (anio >= 2024),
    actividad_minam VARCHAR(20) NOT NULL CHECK (actividad_minam IN (
                        'PAE', 'PAJ', 'PAC', 'EPEA', 'CAMPANA'
                    )),
    indicador       VARCHAR(120) NOT NULL,
    meta_programada INTEGER NOT NULL CHECK (meta_programada > 0),
    presupuesto     DECIMAL(10, 2) NOT NULL DEFAULT 0.00,
    UNIQUE (anio, actividad_minam, indicador)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- ==============================================================================
-- Tabla: promotor_periodo
-- Descripción: Registro anual de promotores ambientales y docentes EDUCCA
-- ==============================================================================

CREATE TABLE IF NOT EXISTS promotor_periodo (
    id                 BIGINT AUTO_INCREMENT PRIMARY KEY,
    persona_id         BIGINT NOT NULL,
    anio               SMALLINT NOT NULL,
    tipo_promotor      VARCHAR(10) NOT NULL CHECK (tipo_promotor IN (
                           'PAE', 'PAJ', 'PAC', 'DOCENTE'
                       )),
    organizacion_id    BIGINT,
    estado             VARCHAR(20) NOT NULL DEFAULT 'INSCRITO' CHECK (estado IN (
                           'INSCRITO', 'ACREDITADO', 'RETIRADO'
                       )),
    codigo_certificado VARCHAR(40) UNIQUE,
    UNIQUE (persona_id, anio, tipo_promotor),
    CONSTRAINT fk_promotor_periodo_persona FOREIGN KEY (persona_id) REFERENCES persona(id) ON DELETE RESTRICT,
    CONSTRAINT fk_promotor_periodo_organizacion FOREIGN KEY (organizacion_id) REFERENCES organizacion(id) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- ==============================================================================
-- Tabla: sesion
-- Descripción: Sesiones educativas, talleres y campañas ejecutadas en EDUCCA
-- ==============================================================================

CREATE TABLE IF NOT EXISTS sesion (
    id               BIGINT AUTO_INCREMENT PRIMARY KEY,
    meta_anual_id    BIGINT NOT NULL,
    organizacion_id  BIGINT,
    responsable_id   BIGINT NOT NULL,
    titulo           VARCHAR(150) NOT NULL,
    modalidad        VARCHAR(15) NOT NULL CHECK (modalidad IN ('PRESENCIAL', 'VIRTUAL')),
    fecha_inicio     DATETIME NOT NULL,
    duracion_minutos SMALLINT NOT NULL CHECK (duracion_minutos > 0),
    estado           VARCHAR(20) NOT NULL DEFAULT 'PROGRAMADA' CHECK (estado IN (
                         'PROGRAMADA', 'EJECUTADA', 'VALIDADA', 'CANCELADA'
                     )),
    CONSTRAINT fk_sesion_meta_anual FOREIGN KEY (meta_anual_id) REFERENCES meta_anual(id) ON DELETE RESTRICT,
    CONSTRAINT fk_sesion_organizacion FOREIGN KEY (organizacion_id) REFERENCES organizacion(id) ON DELETE SET NULL,
    CONSTRAINT fk_sesion_responsable FOREIGN KEY (responsable_id) REFERENCES persona(id) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- ==============================================================================
-- Tabla: asistencia
-- Descripción: Registro de participantes por sesión y su calificación
-- ==============================================================================

CREATE TABLE IF NOT EXISTS asistencia (
    sesion_id     BIGINT NOT NULL,
    persona_id    BIGINT NOT NULL,
    participacion VARCHAR(20) NOT NULL DEFAULT 'ASISTENTE' CHECK (participacion IN (
                      'ASISTENTE', 'VOLUNTARIO_REPLICA', 'PONENTE'
                  )),
    calificacion  DECIMAL(4, 2),
    PRIMARY KEY (sesion_id, persona_id),
    CONSTRAINT fk_asistencia_sesion FOREIGN KEY (sesion_id) REFERENCES sesion(id) ON DELETE CASCADE,
    CONSTRAINT fk_asistencia_persona FOREIGN KEY (persona_id) REFERENCES persona(id) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- ==============================================================================
-- Tabla: archivo_sesion
-- Descripción: Evidencias y documentos asociados a cada sesión
-- ==============================================================================

CREATE TABLE IF NOT EXISTS archivo_sesion (
    id          BIGINT AUTO_INCREMENT PRIMARY KEY,
    sesion_id   BIGINT NOT NULL,
    tipo        VARCHAR(25) NOT NULL CHECK (tipo IN (
                    'FOTO_EVIDENCIA', 'PADRON_FIRMADO', 'ACTA', 'MATERIAL_DIDACTICO'
                )),
    url_archivo TEXT NOT NULL,
    CONSTRAINT fk_archivo_sesion_sesion FOREIGN KEY (sesion_id) REFERENCES sesion(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ================= DATOS SEMILLA =================

-- ==============================================================================
-- Datos iniciales: rol
-- ==============================================================================

INSERT INTO rol (nombre, descripcion) VALUES
    ('admin', 'Administrador del sistema EDUCCA con acceso total'),
    ('coordinador', 'Coordinador municipal responsable de metas, sesiones y validaciones'),
    ('promotor', 'Promotor ambiental o docente acreditado para registrar actividades'),
    ('consulta', 'Usuario con acceso de solo lectura a reportes y sesiones')
ON DUPLICATE KEY UPDATE
    descripcion = VALUES(descripcion);


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
ON DUPLICATE KEY UPDATE
    descripcion = VALUES(descripcion);


-- ==============================================================================
-- Datos iniciales: rol_permiso
-- ==============================================================================

INSERT INTO rol_permiso (rol_id, permiso_id)
SELECT r.id, p.id
FROM rol r
CROSS JOIN permiso p
WHERE r.nombre = 'admin'
ON DUPLICATE KEY UPDATE rol_id = rol_permiso.rol_id;

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
ON DUPLICATE KEY UPDATE rol_id = rol_permiso.rol_id;

INSERT INTO rol_permiso (rol_id, permiso_id)
SELECT r.id, p.id
FROM rol r
JOIN permiso p ON p.clave IN (
    'personas:leer', 'organizaciones:leer', 'metas:leer', 'promotores:leer',
    'sesiones:leer', 'sesiones:crear',
    'asistencias:registrar', 'archivos:subir'
)
WHERE r.nombre = 'promotor'
ON DUPLICATE KEY UPDATE rol_id = rol_permiso.rol_id;

INSERT INTO rol_permiso (rol_id, permiso_id)
SELECT r.id, p.id
FROM rol r
JOIN permiso p ON p.clave IN (
    'personas:leer', 'organizaciones:leer', 'metas:leer',
    'promotores:leer', 'sesiones:leer', 'reportes:exportar'
)
WHERE r.nombre = 'consulta'
ON DUPLICATE KEY UPDATE rol_id = rol_permiso.rol_id;


-- ==============================================================================
-- Datos iniciales: persona
-- Contraseña por defecto para usuario semilla: password123 (hash bcrypt)
-- ==============================================================================

INSERT INTO persona (dni, nombres, apellidos, sexo, fecha_nacimiento, telefono, email, password_hash, activo) VALUES
    ('00000000', 'Admin', 'Principal', 'M', '1990-01-01', '+51999999999', 'admin@educca.gob.pe', '$2a$10$vI8aWBnW3fID.ZQ4/zo1G.q1lRps.9cGLcZEiGDMVr5yUP1KUOYTa', TRUE)
ON DUPLICATE KEY UPDATE
    nombres = VALUES(nombres),
    apellidos = VALUES(apellidos),
    telefono = VALUES(telefono),
    email = VALUES(email),
    activo = VALUES(activo);


-- ==============================================================================
-- Datos iniciales: persona_rol
-- ==============================================================================

INSERT INTO persona_rol (persona_id, rol_id)
SELECT p.id, r.id
FROM persona p
JOIN rol r ON r.nombre = 'admin'
WHERE p.dni = '00000000'
ON DUPLICATE KEY UPDATE persona_id = persona_rol.persona_id;

SET FOREIGN_KEY_CHECKS = 1;
