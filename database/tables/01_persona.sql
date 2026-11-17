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
