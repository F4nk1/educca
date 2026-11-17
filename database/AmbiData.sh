#!/usr/bin/env bash
# ==============================================================================
# Script: AmbiData.sh
# Descripción: Concatena los DDLs de tablas y datos semilla en un único fichero
#              consolidado (database/AmbiData.sql) y opcionalmente lo aplica a MariaDB.
# Uso:
#   ./database/AmbiData.sh            -> Genera database/AmbiData.sql
#   ./database/AmbiData.sh --apply    -> Genera y aplica a la base de datos usando variables de entorno
# ==============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUTPUT_FILE="${SCRIPT_DIR}/AmbiData.sql"

echo "==> Generando ${OUTPUT_FILE}..."

cat > "${OUTPUT_FILE}" << 'EOF'
-- ==============================================================================
-- AMBIDATA DATABASE
-- Esquema consolidado de tablas y datos iniciales para MariaDB (EDUCCA).
-- Autogenerado mediante database/AmbiData.sh
-- ==============================================================================

SET NAMES utf8mb4;
SET FOREIGN_KEY_CHECKS = 0;

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
SET FOREIGN_KEY_CHECKS = 1;
EOF

echo "==> Archivo ${OUTPUT_FILE} generado exitosamente."

# Si se pasa el argumento --apply, ejecutar contra MariaDB
if [[ "${1:-}" == "--apply" ]]; then
    ENV_FILE="${SCRIPT_DIR}/../backend/.env"
    if [[ -f "${ENV_FILE}" ]]; then
        set -a
        # shellcheck disable=SC1090
        source "${ENV_FILE}"
        set +a
    fi

    DB_HOST="${DB_HOST:-localhost}"
    DB_PORT="${DB_PORT:-3306}"
    DB_USER="${DB_USER:-root}"
    DB_NAME="${DB_NAME:-educca}"

    DB_CLIENT=""
    if command -v mariadb >/dev/null 2>&1; then
        DB_CLIENT="mariadb"
    elif command -v mysql >/dev/null 2>&1; then
        DB_CLIENT="mysql"
    else
        echo "Error: no se encontró el cliente 'mariadb' ni 'mysql' en PATH." >&2
        exit 1
    fi

    echo "==> Aplicando esquema en mariadb://${DB_USER}@${DB_HOST}:${DB_PORT}/${DB_NAME}..."
    MYSQL_PWD="${DB_PASSWORD:-}" "${DB_CLIENT}" -h "${DB_HOST}" -P "${DB_PORT}" -u "${DB_USER}" "${DB_NAME}" < "${OUTPUT_FILE}"
    echo "==> Esquema aplicado correctamente en MariaDB."
fi
