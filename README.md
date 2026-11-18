# EDUCCA Backend

API REST para la gestión operativa del Programa Municipal EDUCCA, construida en Go y PostgreSQL.

## Requisitos

- Go `1.27+`
- PostgreSQL `18+` (cliente `psql` y servidor activo)
- `make`

## Configuración inicial

1. Crear el archivo de variables de entorno local a partir del ejemplo:

```bash
cp backend/.env.example backend/.env
```

2. Ajustar en `backend/.env` las credenciales de tu instancia PostgreSQL (`DB_HOST`, `DB_PORT`, `DB_NAME`, `DB_USER`, `DB_PASSWORD`).

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

## Credenciales semilla

El archivo `database/data/04_persona.sql` incluye un usuario administrador inicial:

- **Identificador (`dni` o `email`)**: `00000000` o `admin@educca.gob.pe`
- **Contraseña**: `password123`

## Endpoints principales (`/api/v1`)

### Autenticación

- `POST /api/v1/login`
- `POST /api/v1/refresh`
- `GET /api/v1/me` *(requiere Bearer token)*

### Personas y RBAC

- `GET, POST /api/v1/personas`
- `GET, PUT /api/v1/personas/{id}`
- `PATCH /api/v1/personas/{id}/activo`
- `PATCH /api/v1/personas/{id}/password`
- `GET, POST /api/v1/personas/{id}/roles`
- `DELETE /api/v1/personas/{id}/roles/{rol_id}`
- `GET, POST /api/v1/roles`
- `GET, PUT, DELETE /api/v1/roles/{id}`
- `GET, POST /api/v1/roles/{id}/permisos`
- `DELETE /api/v1/roles/{id}/permisos/{permiso_id}`
- `GET, POST /api/v1/permisos`
- `DELETE /api/v1/permisos/{id}`

### Núcleo EDUCCA

- `GET, POST /api/v1/organizaciones`
- `GET, PUT, DELETE /api/v1/organizaciones/{id}`
- `GET, POST /api/v1/metas-anuales` *(filtro opcional `?anio=2026`)*
- `GET, PUT, DELETE /api/v1/metas-anuales/{id}`
- `GET, POST /api/v1/promotores` *(filtro opcional `?anio=2026`)*
- `GET, PUT, DELETE /api/v1/promotores/{id}`
- `GET, POST /api/v1/sesiones` *(filtros opcionales `?meta_anual_id=1&estado=PROGRAMADA`)*
- `GET, PUT, DELETE /api/v1/sesiones/{id}`
- `PATCH /api/v1/sesiones/{id}/estado`
- `GET, POST /api/v1/sesiones/{id}/asistencias`
- `DELETE /api/v1/sesiones/{id}/asistencias/{persona_id}`
- `GET, POST /api/v1/sesiones/{id}/archivos`
- `DELETE /api/v1/sesiones/{id}/archivos/{archivo_id}`
- `GET /api/v1/reportes/metas` *(filtro opcional `?anio=2026`)*

## Prueba rápida con `curl`

```bash
TOKEN=$(curl -s -X POST http://localhost:8080/api/v1/login \
  -H "Content-Type: application/json" \
  -d '{"identificador":"00000000","password":"password123"}' | jq -r '.access_token')

curl -s http://localhost:8080/api/v1/me \
  -H "Authorization: Bearer $TOKEN" | jq .

curl -s http://localhost:8080/api/v1/reportes/metas \
  -H "Authorization: Bearer $TOKEN" | jq .
```
