# EDUCCA Cusco — Frontend Web (Integración Go REST API)

Aplicación web administrativa para el Programa Municipal de Educación, Cultura y Ciudadanía Ambiental (EDUCCA) de Cusco (**EcoCapacita**).

Construida con React 18, TypeScript, Vite, React Router 6, CSS Modules y Fetch API con renovación transparente de tokens JWT.

---

## 1. Configuración de Entorno

Crear el archivo `.env` en la raíz de `web/` a partir de `.env.example`:

```bash
cp .env.example .env
```

Variables disponibles:

```env
# URL base de la API REST en Go (subdominio de pruebas o http://localhost:8080/api/v1 en local)
VITE_API_BASE_URL=https://educca.cocorium.online/api/v1

# Modo de datos inicial: "api" (backend Go real) o "demo" (datos locales simulados)
VITE_DEFAULT_DATA_MODE=api
```

> **Nota**: El frontend se ejecuta en el navegador del usuario, por lo que utiliza `localhost:8080` (a diferencia del emulador Android de Flutter que usa `10.0.2.2`).

---

## 2. Comandos de Ejecución

### Modo Desarrollo
```bash
cd web
npm install
npm run dev
```
La aplicación iniciará en `http://localhost:5173`.

### Compilación para Producción
```bash
npm run build
npm run preview
```

---

## 3. Matriz de Endpoints Go ↔ Frontend Web

| Pantalla | Funcionalidad | Método y Endpoint en Go | Permiso RBAC |
|---|---|---|---|
| **W01 — Login** | Autenticación con identificador (`email` o `dni`) y contraseña | `POST /api/v1/login` | Público |
| **W01 — Login** | Renovación de access token mediante refresh token | `POST /api/v1/refresh` | Público |
| **W01 — Login** | Consulta de identidad, roles asignados y permisos | `GET /api/v1/me` | `authenticated` |
| **W02 — Inicio** | Conteo y catálogo operativo | `GET /api/v1/sesiones`, `/organizaciones`, `/personas` | `sesiones:leer` |
| **W03 — Sedes** | Listado de organizaciones georreferenciadas | `GET /api/v1/organizaciones` | `organizaciones:leer` |
| **W03 — Sedes** | Creación y edición de sede con radio de geocerca (80 m) | `POST /api/v1/organizaciones`<br>`PUT /api/v1/organizaciones/{id}` | `organizaciones:escribir` |
| **W03 — Sedes** | Eliminación de sede | `DELETE /api/v1/organizaciones/{id}` | `organizaciones:escribir` |
| **W04 — Talleres** | Listado de sesiones/talleres con cupos y fechas | `GET /api/v1/sesiones` | `sesiones:leer` |
| **W05 — Programar** | Creación de sesión asociada a meta anual y sede | `POST /api/v1/sesiones` | `sesiones:crear` |
| **W05 — Programar** | Consulta de metas anuales disponibles | `GET /api/v1/metas-anuales` | `metas:leer` |
| **W06 — Usuarios** | Directorio de personas registradas | `GET /api/v1/personas` | `personas:leer` |
| **W06 — Usuarios** | Alta de persona con DNI, contacto y categoría | `POST /api/v1/personas` | `personas:escribir` |
| **W06 — Usuarios** | Activación o inactivación de usuario | `PATCH /api/v1/personas/{id}/activo` | `personas:escribir` |
| **W07 — Sesiones** | Listado y transiciones de estado (`PROGRAMADA`, `EJECUTADA`, `VALIDADA`, `CANCELADA`) | `PATCH /api/v1/sesiones/{id}/estado` | `sesiones:crear` / `sesiones:validar` |
| **W08 — Panel QR** | Emisión de token JWT dinámico rotativo con TTL (300 s) y nonce | `POST /api/v1/sesiones/{id}/qr` | `sesiones:qr` |
| **W08 — Panel QR** | Consulta de QR activo y segundos restantes | `GET /api/v1/sesiones/{id}/qr` | `sesiones:qr` |
| **W08 — Panel QR** | Revocación inmediata del QR | `DELETE /api/v1/sesiones/{id}/qr` | `sesiones:qr` |
| **W08 — Panel QR** | Monitoreo en tiempo real de inscritos y asistentes | `GET /api/v1/sesiones/{id}/monitoreo` | `sesiones:qr` / `sesiones:leer` |
| **W09 — Asistencias** | Listado de asistentes y participantes de la sesión | `GET /api/v1/sesiones/{id}/asistencias`<br>`GET /api/v1/sesiones/{id}/inscripciones` | `asistencias:registrar` |
| **W09 — Asistencias** | Marcado manual asistido para participantes sin smartphone | `POST /api/v1/sesiones/{id}/asistencias` | `asistencias:registrar` |
| **W09 — Asistencias** | Reversión de asistencia | `DELETE /api/v1/sesiones/{id}/asistencias/{persona_id}` | `asistencias:registrar` |
| **W09-C — Global** | Consulta consolidada de asistencias y geocerca Haversine | `GET /api/v1/sesiones/{id}/monitoreo` | `sesiones:leer` |
| **W09-C — Global** | Exportación de padrón en formato CSV | Generación del lado del cliente | `reportes:exportar` |

---

## 4. Interoperabilidad con la Aplicación Flutter

El código QR mostrado en la pantalla **W08** es generado directamente a partir del token JWT emitido por Go (`POST /api/v1/sesiones/{id}/qr`).

1. La web solicita el token al backend y lo renderiza como SVG con `qrcode.react`.
2. El promotor escanea el QR desde la app móvil Flutter (pantalla M04).
3. La app móvil envía el token y sus coordenadas GPS al backend (`POST /api/v1/asistencias/check-in-qr`).
4. Go valida la firma criptográfica con `QRSecret`, verifica que el nonce coincida con el QR activo en memoria, y calcula la distancia Haversine a la sede. Si está dentro del radio de 80 m, registra la asistencia en PostgreSQL.
5. El panel web del capacitador (W08) y de asistencias (W09) actualiza su conteo en tiempo real.

---

## 5. Credenciales Semilla para Pruebas

El script inicial de base de datos (`database/data/04_persona.sql`) incluye el usuario administrador inicial:

- **Identificador**: `admin@educca.gob.pe` o `00000000`
- **Contraseña**: `password123`
- **Rol en BD**: `admin` (incluye todos los permisos de coordinador y capacitador).

---

## 6. Alternancia entre Modo API y Modo Demo

La barra superior incluye un botón indicador de modo:
- **API Real** (verde): Todas las peticiones van directamente al servidor Go. Si el backend no está encendido o devuelve error, se muestra el mensaje de error HTTP real.
- **Demo** (ámbar): Utiliza datos simulados en memoria para demostración sin servidor.
