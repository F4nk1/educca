#!/usr/bin/env bash
# ==============================================================================
# Script: AmbiData.sh
# Descripción: Concatena los DDLs de tablas y datos semilla en un único fichero
#              consolidado (database/AmbiData.sql) y opcionalmente lo aplica a PostgreSQL.
# Uso:
#   ./database/AmbiData.sh            -> Genera database/AmbiData.sql
#   ./database/AmbiData.sh --apply    -> Genera y aplica a la base de datos usando backend/.env
# ==============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUTPUT_FILE="${SCRIPT_DIR}/AmbiData.sql"

echo "==> Generando ${OUTPUT_FILE}..."

cat > "${OUTPUT_FILE}" << 'EOF'
-- ==============================================================================
-- AMBIDATA DATABASE
-- Esquema consolidado de tablas y datos iniciales para PostgreSQL (EDUCCA).
-- Autogenerado mediante database/AmbiData.sh
-- ==============================================================================

BEGIN;

EOF

# 1. Agregar definición de tablas en orden numérico/dependencia
echo "-- ================= TABLAS =================" >> "${OUTPUT_FILE}"
for table_file in $(ls -1 "${SCRIPT_DIR}/tables/"*.sql | sort); do
    echo "Agregando tabla: $(basename "${table_file}")"
    echo "" >> "${OUTPUT_FILE}"
    cat "${table_file}" >> "${OUTPUT_FILE}"
    echo "" >> "${OUTPUT_FILE}"
done

# 2. Agregar datos iniciales (semillas)
echo "-- ================= DATOS SEMILLA =================" >> "${OUTPUT_FILE}"
for data_file in $(ls -1 "${SCRIPT_DIR}/data/"*.sql | sort); do
    echo "Agregando datos: $(basename "${data_file}")"
    echo "" >> "${OUTPUT_FILE}"
    cat "${data_file}" >> "${OUTPUT_FILE}"
    echo "" >> "${OUTPUT_FILE}"
done

cat >> "${OUTPUT_FILE}" << 'EOF'
COMMIT;
EOF

echo "==> Archivo ${OUTPUT_FILE} generado exitosamente."

# Si se pasa el argumento --apply, ejecutar contra PostgreSQL
if [[ "${1:-}" == "--apply" ]]; then
    ENV_FILE="${SCRIPT_DIR}/../backend/.env"
    if [[ -f "${ENV_FILE}" ]]; then
        set -a
        # shellcheck disable=SC1090
        source "${ENV_FILE}"
        set +a
    fi

    DB_HOST="${DB_HOST:-localhost}"
    DB_PORT="${DB_PORT:-5432}"
    DB_USER="${DB_USER:-postgres}"
    DB_NAME="${DB_NAME:-educca}"

    if ! command -v psql >/dev/null 2>&1; then
        echo "Error: no se encontró el cliente 'psql' en PATH." >&2
        exit 1
    fi

    echo "==> Verificando base de datos '${DB_NAME}' en postgres://${DB_USER}@${DB_HOST}:${DB_PORT}..."
    if ! PGPASSWORD="${DB_PASSWORD:-}" psql -h "${DB_HOST}" -p "${DB_PORT}" -U "${DB_USER}" -d postgres -tAc "SELECT 1 FROM pg_database WHERE datname = '${DB_NAME}'" | grep -q 1; then
        echo "==> Creando base de datos '${DB_NAME}'..."
        PGPASSWORD="${DB_PASSWORD:-}" psql -v ON_ERROR_STOP=1 -h "${DB_HOST}" -p "${DB_PORT}" -U "${DB_USER}" -d postgres -c "CREATE DATABASE \"${DB_NAME}\";"
    fi

    echo "==> Aplicando esquema en postgres://${DB_USER}@${DB_HOST}:${DB_PORT}/${DB_NAME}..."
    PGPASSWORD="${DB_PASSWORD:-}" psql -v ON_ERROR_STOP=1 -h "${DB_HOST}" -p "${DB_PORT}" -U "${DB_USER}" -d "${DB_NAME}" -f "${OUTPUT_FILE}"
    echo "==> Esquema aplicado correctamente en PostgreSQL."
fi
