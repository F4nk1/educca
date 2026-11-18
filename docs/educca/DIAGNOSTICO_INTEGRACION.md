# Diagnóstico Exhaustivo de Integración: Mobile Flutter ↔ Backend Go
**Proyecto**: EDUCCA Cusco — EcoCapacita  
**Fecha**: 2026-11-18  
**Autor**: Ingeniero de Integración Flutter / Go  
**Rama de trabajo**: `feat/mobile-backend-integration`  
**Hash de respaldo Git**: `2b506b0`  

---

## 1. Arquitectura Real del Repositorio

El repositorio conjunto `educca` presenta una arquitectura modular monorepo sin submódulos git anidados:

```
educca/
├── backend/            # API REST en Go 1.27 + Gorilla Mux + PostgreSQL (pgx/v5)
│   ├── main.go         # Punto de entrada HTTP (:8080)
│   ├── go.mod          # Módulo github.com/F4nk1/educca/backend
│   └── source/
│       ├── auth/       # JWT HS256 (access, refresh y QR tokens con nonce)
│       ├── cache/      # Caché en memoria para estados de QR y correlation
│       ├── common/     # Códigos de error unificados, permisos y respuestas
│       ├── config/     # Carga de variables de entorno con godotenv
│       ├── database/   # Conexión pool con pgx/v5
│       ├── middleware/ # Auth, Permission RBAC, Correlation, Cors, Cache
│       ├── model/      # Modelos de dominio (Persona, Sesion, Asistencia, etc.)
│       ├── server/     # Router Gorilla Mux, handlers HTTP y validadores
│       ├── service/    # Capa de negocio y consultas SQL (Haversine 80 m)
│       └── tracer/     # Logger estructurado con zap
├── database/           # DDL, funciones PL/pgSQL y datos semilla
│   ├── AmbiData.sh     # Script Bash de concatenación y despliegue
│   ├── AmbiData.sql    # Esquema consolidado generado
│   ├── data/           # Datos semilla (01_rol a 05_persona_rol)
│   ├── functions/      # 11 archivos de funciones almacenadas
│   └── tables/         # 12 archivos DDL de tablas relacionales
├── mobile/             # Aplicación Flutter Android / iOS / Web / Desktop
│   ├── lib/            # Código fuente Dart (Arquitectura Provider + Repository)
│   │   ├── config/     # AppConfig (URL base, modo demo) y AppTheme
│   │   ├── core/       # ApiClient, SessionStorage, Result monad
│   │   ├── models/     # PromoterUser, Course, CourseSession, AttendanceModels
│   │   ├── providers/  # AuthProvider, CoursesProvider, AttendanceProvider
│   │   ├── repositories/ # ApiEduccaRepository, MockEduccaRepository
│   │   └── screens/    # Pantallas M01 a M08 + Andean Widgets
│   ├── test/           # 35 pruebas automatizadas (unitarias y de widgets)
│   └── pubspec.yaml    # Dependencias Flutter 3.x
├── Makefile            # Automatización de tareas de compilación y base de datos
└── README.md           # Documentación técnica general del backend
```

---

## 2. Estado del Backend Go

El backend Go se encuentra implementado con alto grado de madurez técnica, seguridad y apego a la Ley N.° 29733 (LPDP):

- **Enrutamiento HTTP**: Implementado mediante `github.com/gorilla/mux v1.8.1` bajo el prefijo `/api/v1`.
- **Mecanismo de Autenticación**: JWT (`github.com/golang-jwt/jwt/v5`) firmado con `HS256`. Genera par de tokens: `access_token` (15 min) y `refresh_token` (7 días).
- **Control de Acceso (RBAC)**: Middleware de permisos declarativo basado en mapa ruta/método contra roles en base de datos. Roles soportados: `admin`, `coordinador`, `capacitador`, `capacitando`, `consulta`.
- **Persistencia**: PostgreSQL con funciones almacenadas PL/pgSQL transaccionales (`fn_asistencia_checkin_qr`, `fn_sesion_listar`, `fn_persona_login`, etc.).
- **Gestión de QR**: Generación dinámica con tokens firmados de vigencia configurable (default 300 s) y nonce rotativo en memoria (`QRCache`).
- **Validación de Geocerca**: Cálculo de distancia horizontal Haversine en la capa de servicio de Go contra la latitud/longitud oficial de la `organizacion` (sede) asociada a la sesión. Radio por defecto: 80 metros.
- **Pruebas Automatizadas en Go**: Actualmente el backend no cuenta con archivos `*_test.go` en su directorio `backend/`. Su validación ha sido manual o mediante scripts de integración.
- **Documentación Swagger / Postman**: No existen colecciones Postman ni archivos OpenAPI/Swagger en el repositorio; la especificación viva reside en `README.md` y en el código Go (`source/server/server.go`).

---

## 3. Tabla de Compatibilidad API REST ↔ Flutter

| Funcionalidad | Endpoint Real Backend Go | Ruta Esperada Flutter Actual | Parámetros Enviados (Flutter) | Parámetros Requeridos (Go) | Estado de Compatibilidad |
|---|---|---|---|---|---|
| **Health Check** | `GET /health` | No invocado explícitamente | Ninguno | Ninguno | Compatible (Listo para ping) |
| **Login** | `POST /api/v1/login` | `POST /auth/login` | `{"email", "password"}` | `{"identificador", "password"}` | **Incompatible en ruta y campos** (Ver punto 5) |
| **Perfil Usuario** | `GET /api/v1/me` | No invocado (asumía retorno en login) | Token Bearer | Token Bearer | **Compatible** (Requiere invocar tras login) |
| **Refresh Token** | `POST /api/v1/refresh` | No implementado en Flutter | N/A | `{"refresh_token"}` | **Disponible en Go** (Pendiente en Flutter) |
| **Registro** | `POST /api/v1/register` | `POST /auth/register` | `fullName`, `email`, `password`, `promoterCategory`, `isAdult`, `privacyConsentAccepted` | `dni`, `nombres`, `apellidos`, `sexo`, `fecha_nacimiento`, `telefono`, `email`, `password`, `categoria`, `consentimiento_aceptado`, `consentimiento_version` | **Incompatible en DTO** (Requiere adaptar formulario) |
| **Sesiones / Talleres** | `GET /api/v1/sesiones` | `GET /student/courses` | Query params | Query params (`?meta_anual_id=&estado=&eje_tematico=`) | **Incompatible en contrato** (Ver punto 5) |
| **Mis Inscripciones**| `GET /api/v1/mi/inscripciones`| No invocado | Token Bearer | Token Bearer | **Disponible en Go** (Ideal para móvil) |
| **Inscribirse a Taller**| `POST /api/v1/sesiones/{id}/inscripciones`| No invocado | Token Bearer | Token Bearer | **Disponible en Go** |
| **Check-in QR + GPS** | `POST /api/v1/asistencias/check-in-qr` | `POST /attendance/scan` | `{"qrToken", "location": {"latitude", "longitude", ...}}` | `{"qr_token", "latitud", "longitud"}` | **Incompatible en ruta y estructura JSON** |
| **Historial Asistencia**| `GET /api/v1/mi/asistencias` | `GET /student/attendance/history` | Token Bearer | Token Bearer | **Incompatible solo en URL** (DTO compatible) |

---

## 4. Endpoints Disponibles y Pendientes

### Endpoints 100% Implementados en Go
1. `GET /health`: Estado del servicio y conectividad a base de datos.
2. `POST /api/v1/login`: Autenticación con identificador y contraseña.
3. `POST /api/v1/register`: Auto-registro de capacitandos con consentimiento LPDP y mayoría de edad.
4. `POST /api/v1/refresh`: Rotación de access token mediante refresh token.
5. `GET /api/v1/me`: Consulta de identidad (`Persona`), roles y permisos asignados.
6. `GET /api/v1/sesiones`: Catálogo de sesiones con cupos y fechas.
7. `GET /api/v1/sesiones/{id}`: Detalle de sesión.
8. `GET /api/v1/mi/inscripciones`: Sesiones en las que el usuario está inscrito.
9. `POST /api/v1/sesiones/{id}/inscripciones`: Inscripción a taller presencial o virtual.
10. `DELETE /api/v1/sesiones/{id}/inscripciones/mia`: Cancelación de inscripción propia.
11. `POST /api/v1/asistencias/check-in-qr`: Validación de asistencia presencial mediante QR + Haversine (80 m).
12. `GET /api/v1/mi/asistencias`: Historial de asistencias registradas por el usuario.
13. `POST /api/v1/sesiones/{id}/qr`: Generación de QR dinámico (rol capacitador/coordinador).
14. `GET /api/v1/sesiones/{id}/qr`: Consulta de QR activo (rol capacitador/coordinador).
15. `DELETE /api/v1/sesiones/{id}/qr`: Revocación inmediata del QR (rol capacitador/coordinador).
16. `GET /api/v1/sesiones/{id}/monitoreo`: Monitoreo en tiempo real de inscritos y asistentes.

### Endpoints Pendientes / Inexistentes en Go
1. `/student/courses` y `/student/courses/{id}/sessions`: Rutas heredadas del MVP formativo universitario; **no existen en Go**. Se deben mapear a `/api/v1/sesiones` y `/api/v1/mi/inscripciones`.
2. `/student/attendance/history`: Se debe mapear a `/api/v1/mi/asistencias`.
3. `/attendance/scan`: Se debe mapear a `/api/v1/asistencias/check-in-qr`.

---

## 5. Incompatibilidades Críticas Detectadas

### Incompatibilidad 1: Nombres de Rutas y Prefijo Base
- **Problema**: `AppConfig.defaultBaseUrl` en Flutter es `http://10.0.2.2:8080/api/v1`. Al llamar a `/auth/login`, `ApiClient` construye `http://10.0.2.2:8080/api/v1/auth/login`. En Go el handler está registrado como `/api/v1/login`.
- **Impacto**: HTTP 404 Not Found en todas las peticiones si no se corrige el path relativo.
- **Solución**: Los endpoints en `ApiEduccaRepository` deben ser `/login`, `/register`, `/me`, `/sesiones`, `/asistencias/check-in-qr` y `/mi/asistencias`.

### Incompatibilidad 2: DTO y Flujo de Login
- **Problema en Request**: Flutter envía `{"email": "...", "password": "..."}`. Go espera `{"identificador": "...", "password": "..."}`.
- **Problema en Response**: Flutter espera `{"token": "...", "user": {...}}`. Go devuelve `{"access_token": "...", "refresh_token": "...", "expires_in": 900, "token_type": "Bearer"}` (sin objeto de usuario).
- **Solución**: Adaptar `ApiEduccaRepository.login` para enviar `identificador` e inmediatamente después de recibir el `access_token` realizar un `GET /me`, consolidando la sesión en memoria.

### Incompatibilidad 3: DTO de Marcado de Asistencia (Check-in QR)
- **Problema**: Flutter envía un objeto anidado `{"qrToken": "...", "location": {"latitude": ..., "longitude": ..., "accuracyMeters": ..., "capturedAt": ...}}`. Go espera campos planos en snake_case: `{"qr_token": "...", "latitud": ..., "longitud": ...}`.
- **Solución**: Modificar el serializador en `ApiEduccaRepository.scanAttendance` para enviar el JSON plano esperado por Go.

### Incompatibilidad 4: Categorías del Promotor y Restricciones de Base de Datos
- **Problema**: En Flutter existen las categorías `ESCOLAR`, `JUVENIL`, `COMUNITARIO`. En PostgreSQL existe un check constraint estricto: `CHECK (categoria IN ('COMERCIANTE', 'RECICLADOR', 'PAC', 'PAJ'))`.
- **Mapeo sugerido**:
  - `JUVENIL` ↔ `PAJ` (Promotor Ambiental Juvenil)
  - `COMUNITARIO` ↔ `PAC` (Promotor Ambiental Comunitario)
  - `ESCOLAR`: El backend Go por normativa LPDP exige mayoría de edad (`>= 18` años) en auto-registro público. Los escolares menores requieren tratamiento especial o enrolamiento por parte del coordinador.

### Incompatibilidad 5: Modelo Jerárquico de Talleres
- **Problema**: Flutter esperaba una entidad `Course` con sub-entidades `CourseSession`. En el backend municipal EDUCCA, la unidad operativa fundamental es la `Sesion` directamente vinculada a una meta anual y una organización/sede georreferenciada.
- **Solución**: Adaptar `CoursesProvider` para mostrar las sesiones directamente como talleres independientes, o agruparlas por `eje_tematico` / `meta_anual_id`.

---

## 6. Orden Recomendado de Implementación

1. **Paso 1: Conexión de Autenticación (`POST /login` + `GET /me`)**
   - Modificar `ApiEduccaRepository.login` y verificar con el usuario administrador semilla (`admin@educca.gob.pe` / `password123`) o un usuario registrado.
2. **Paso 2: Conexión de Marcado de Asistencia (`POST /asistencias/check-in-qr`)**
   - Adaptar DTO de envío (`qr_token`, `latitud`, `longitud`) y mapear respuestas de error HTTP 409 y HTTP 422.
3. **Paso 3: Conexión de Historial (`GET /mi/asistencias`)**
   - Conectar la pantalla M07 directamente con las asistencias registradas del usuario.
4. **Paso 4: Conexión de Catálogo y Próxima Sesión (`GET /sesiones` + `GET /mi/inscripciones`)**
   - Adaptar `CoursesProvider` para listar las sesiones y mostrar la próxima actividad en la pantalla principal M03.
5. **Paso 5: Ajuste de Pantalla de Registro (`POST /register`)**
   - Adaptar el formulario M02 para capturar DNI, fecha de nacimiento y categoría válida (`PAC`, `PAJ`).

---

## 7. Bloqueos que Requieren Coordinación con el Desarrollador Backend

1. **Datos de Prueba y Semillas de Sesiones**:
   - Actualmente `database/data/` solo incluye el usuario `admin`. No hay sesiones creadas ni organizaciones con coordenadas en Cusco para probar inmediatamente el flujo en el emulador.
   - *Petición al backend*: Añadir una sede semilla en Cusco (ej. Plaza Mayor de Cusco: `-13.516024, -71.978051`, radio 80 m) y una sesión presencial en estado `EN_CURSO` para pruebas directas.
2. **Generador de QR para Pruebas del Móvil**:
   - Para que el móvil escanee un QR real en el emulador, el backend o una interfaz web debe emitir el QR firmado (`POST /api/v1/sesiones/{id}/qr`).
   - Se debe acordar un mecanismo simple para obtener o visualizar dicho QR durante las pruebas de integración (ej. endpoint público de prueba o script auxiliar).
3. **Manejo de Promotores Escolares (< 18 años)**:
   - Validar con el Product Owner si la app móvil permitirá registro escolar o si los promotores escolares serán dados de alta exclusivamente por el coordinador municipal.

---

## 8. Pruebas Necesarias para Demostrar la Integración

1. **Prueba 1: Login Real**
   - Entrar con credenciales válidas y comprobar que `GET /me` devuelva el nombre del promotor y el rol `capacitando`.
2. **Prueba 2: Marcado Exitoso Dentro del Radio (<= 80 m)**
   - Generar un QR en Go para una sesión presencial en sede Cusco.
   - Enviar ubicación a 20 metros de la sede.
   - Comprobar que Go responde HTTP 201 y la app muestra la pantalla de éxito con `distancia_metros`.
3. **Prueba 3: Rechazo por Distancia (> 80 m)**
   - Enviar ubicación a 150 metros de la sede.
   - Comprobar que Go responde HTTP 422 con mensaje descriptivo y la app muestra `ScanOutcome.outOfRange`.
4. **Prueba 4: Rechazo por Asistencia Duplicada**
   - Reintentar el escaneo en la misma sesión.
   - Comprobar que Go responde HTTP 409 y la app muestra `ScanOutcome.duplicate`.
5. **Prueba 5: Rechazo por QR Expirado / Revocado**
   - Intentar marcar con un QR revocado o con más de 300 segundos de antigüedad.
   - Comprobar que Go responde HTTP 422 y la app muestra `ScanOutcome.expired`.
6. **Prueba 6: Historial Real**
   - Entrar a la pantalla de asistencias y validar que aparezca el registro confirmado en la base de datos.

---

## 9. Estado de Ejecución de la Integración (Noviembre 2026)

- **Endpoints Conectados**:
  - `POST /api/v1/login`: Conectado con `identificador`, persistencia de `access_token` y `refresh_token`.
  - `GET /api/v1/me`: Invocado inmediatamente tras el login y disponible para sincronización de perfil.
  - `POST /api/v1/refresh`: Integrado en `ApiClient` con reintento transparente ante respuestas HTTP 401 y método público en `AuthProvider`.
  - `GET /api/v1/sesiones`: Conectado en `CoursesProvider.fetchCourses()` y `ApiEduccaRepository.getPromoterSessions()`.
  - `GET /api/v1/sesiones/{id}`: Conectado en `CoursesProvider.fetchSessions()`.
  - `GET /api/v1/mi/inscripciones`: Conectado en `CoursesProvider.fetchMyEnrollments()`.
  - `POST /api/v1/sesiones/{id}/inscripciones`: Conectado en `CoursesProvider.enrollSession()`.
  - `POST /api/v1/asistencias/check-in-qr`: Conectado en `ApiEduccaRepository.scanAttendance()` con DTO plano `{"qr_token", "latitud", "longitud"}` y mapeo de HTTP 201, 409 y 422.
  - `GET /api/v1/mi/asistencias`: Conectado en `AttendanceProvider.fetchHistory()` mapeando `AttendanceRecord`.
  - `POST /api/v1/register`: Conectado en `ApiEduccaRepository.registerPromoter()` con campos y categorías LPDP (`PAJ`, `PAC`, `COMERCIANTE`, `RECICLADOR`).
- **Verificación de Pruebas**:
  - `flutter analyze`: **0 incidencias** (código 100% limpio).
  - `flutter test`: **40 pruebas aprobadas** (35 de regresión + 5 nuevas de contratos de integración).
  - `MockEduccaRepository`: 100% operativo y disponible en modo debug para demostraciones sin backend.
- **Entorno Local**:
  - `go` y `psql` no están instalados en el host de Windows actual. El cliente Flutter está listo para apuntar a `http://10.0.2.2:8080/api/v1` en cuanto el backend se inicie.
