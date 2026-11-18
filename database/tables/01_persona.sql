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
