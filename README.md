# EDUCCA / EcoCapacita Backend

API REST para la gestión operativa, seguimiento en tiempo real y control de asistencia geolocalizada de las capacitaciones del Programa Municipal EDUCCA en Cusco (**EcoCapacita**), construida en Go y PostgreSQL.

## Requisitos

- Go `1.27+`
- PostgreSQL `18+` (cliente `psql` y servidor activo)
- `make`

## Configuración inicial

1. Crear el archivo de variables de entorno local a partir del ejemplo:

```bash
cp backend/.env.example backend/.env
```

2. Ajustar en `backend/.env` las credenciales de PostgreSQL (`DB_HOST`, `DB_PORT`, `DB_NAME`, `DB_USER`, `DB_PASSWORD`, `DB_SSLMODE`), orígenes CORS (`CORS_ALLOWED_ORIGINS`) y secretos criptográficos (`ACCESS_SECRET`, `REFRESH_SECRET`, `QR_SECRET`).

3. Instalar dependencias de Go, regenerar `database/AmbiData.sql` y crear la base de datos desde cero:

```bash
make setup
```

4. Iniciar el servidor backend:

```bash
make run_b
```

## Comandos del `Makefile`

- `make help`: lista las opciones disponibles.
- `make setup`: ejecuta `backend-setup` y `db-setup`.
- `make backend-setup`: ejecuta `go mod tidy` y `go mod download` en `backend/`.
- `make db-setup`: ejecuta `./database/AmbiData.sh --apply` (recrea la BD desde cero con tablas, funciones almacenadas y datos semilla).
- `make run_b`: inicia el servidor HTTP en el puerto configurado (`SERVER_PORT`, por defecto `8080`).
- `make clean`: elimina artefactos compilados en `backend/bin` y `backend/main`.

## Roles del sistema (`database/data/01_rol.sql`)

- `admin`: Administrador del sistema con acceso total.
- `coordinador`: Coordinador municipal responsable de metas, sedes georreferenciadas, catálogo de talleres, validaciones y atención ARCO.
- `capacitador`: Capacitador ambiental encargado de dictar talleres, generar/revocar códigos QR dinámicos, monitorear sesiones y registrar asistencias/calificaciones.
- `capacitando`: Ciudadano participante (`COMERCIANTE`, `RECICLADOR`, `PAC`, `PAJ`) que se registra con consentimiento LPDP (`>= 18` años), se inscribe a talleres, marca asistencia con QR+GPS (`<= 80 m`) y consulta su avance.
- `consulta`: Perfil de solo lectura sobre el catálogo y reportes agregados (sin acceso a PII de ciudadanos).

## Credenciales semilla

El archivo `database/data/04_persona.sql` incluye un usuario administrador inicial:

- **Identificador (`dni` o `email`)**: `00000000` o `admin@educca.gob.pe`
- **Contraseña**: `password123`

## Endpoints principales

### Salud y Autenticación

- `GET /health`
- `POST /api/v1/register` *(registro público de `capacitando` con validación LPDP y mayoría de edad `>= 18`)*
- `POST /api/v1/login`
- `POST /api/v1/refresh`
- `GET /api/v1/me` *(requiere Bearer token)*

### Personas, RBAC y Derechos ARCO (Ley N.° 29733 / D.S. N.° 016-2024-JUS)

- `GET, POST /api/v1/personas`
- `GET, PUT /api/v1/personas/{id}`
- `PATCH /api/v1/personas/{id}/activo`
- `PATCH /api/v1/personas/{id}/password`
- `GET, POST /api/v1/personas/{id}/roles`
- `DELETE /api/v1/personas/{id}/roles/{rol_id}`
- `GET /api/v1/arco/personas/{id}/exportar` *(exportación JSON de datos personales, consentimiento, inscripciones y asistencias)*
- `POST /api/v1/arco/personas/{id}/anonimizar` *(anonimización irreversible de PII conservando métricas agregadas)*
- `GET, POST /api/v1/roles`
- `GET, PUT, DELETE /api/v1/roles/{id}`
- `GET, POST /api/v1/roles/{id}/permisos`
- `DELETE /api/v1/roles/{id}/permisos/{permiso_id}`
- `GET, POST /api/v1/permisos`
- `DELETE /api/v1/permisos/{id}`

### Sedes Georreferenciadas, Metas y Catálogo de Sesiones

- `GET, POST /api/v1/organizaciones` *(incluye `latitud`, `longitud`, `radio_metros` default `80` y tipos `MERCADO`, `CENTRO_ACOPIO`)*
- `GET, PUT, DELETE /api/v1/organizaciones/{id}`
- `GET, POST /api/v1/metas-anuales` *(filtro opcional `?anio=2026`)*
- `GET, PUT, DELETE /api/v1/metas-anuales/{id}`
- `GET, POST /api/v1/promotores` *(filtro opcional `?anio=2026`)*
- `GET, PUT, DELETE /api/v1/promotores/{id}`
- `GET, POST /api/v1/sesiones` *(filtros `?meta_anual_id=&estado=&eje_tematico=&organizacion_id=`, devuelve `inscritos_actuales` y `cupos_disponibles` y valida no solapamiento horario)*
- `GET, PUT, DELETE /api/v1/sesiones/{id}`
- `PATCH /api/v1/sesiones/{id}/estado`

### QR Dinámico, Monitoreo, Check-in GPS (80 m) y Portal del Capacitando

- `POST /api/v1/sesiones/{id}/qr` *(genera/rota token QR firmado con vigencia temporal)*
- `GET /api/v1/sesiones/{id}/qr` *(devuelve el token QR activo y `segundos_restantes`)*
- `DELETE /api/v1/sesiones/{id}/qr` *(revoca el QR activo)*
- `GET /api/v1/sesiones/{id}/monitoreo` *(estado de la sesión, QR activo, inscritos y asistentes en tiempo real)*
- `POST /api/v1/asistencias/check-in-qr` *(valida token QR + distancia Haversine `<= radio_metros` sin almacenar GPS del ciudadano; responde `422` si supera el radio)*
- `POST /api/v1/sesiones/{id}/inscripciones` *(inscribe al usuario actual validando `cupo_maximo`)*
- `DELETE /api/v1/sesiones/{id}/inscripciones/mia` *(cancela la inscripción propia antes del inicio)*
- `GET /api/v1/sesiones/{id}/inscripciones` *(lista de inscritos para capacitador/coordinador)*
- `GET /api/v1/mi/inscripciones` *(talleres inscritos del usuario autenticado)*
- `GET /api/v1/mi/asistencias` *(historial de asistencias y calificaciones del usuario autenticado)*
- `GET, POST /api/v1/sesiones/{id}/asistencias`
- `DELETE /api/v1/sesiones/{id}/asistencias/{persona_id}`
- `GET, POST /api/v1/sesiones/{id}/archivos`
- `DELETE /api/v1/sesiones/{id}/archivos/{archivo_id}`
- `GET /api/v1/reportes/metas` *(filtro opcional `?anio=2026`)*
