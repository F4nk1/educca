# Plan de Arquitectura e Integración Técnica
**Feature ID**: `003-integracion-mobile-backend`  
**Proyecto**: EDUCCA Cusco (EcoCapacita)  
**Estado**: Borrador de Diagnóstico Aprobado para Planificación  
**Fecha**: 2026-11-18  

---

## 1. Arquitectura de Integración

```
┌────────────────────────────────────────────────────────┐
│               Flutter Android App (mobile/)            │
│  [UI Screens: Login, Register, Home, Courses, QR Scan] │
│                           │                            │
│                 [Providers & State]                    │
│      (AuthProvider, CoursesProvider, AttendanceProvider)│
│                           │                            │
│              [EduccaRepository Interface]              │
│               /                         \              │
│    [MockEduccaRepository]      [ApiEduccaRepository]   │
│         (Demo Debug)                     │             │
│                                    [ApiClient]         │
└──────────────────────────────────────────┼─────────────┘
                                           │ HTTP / JSON
                                           │ (10.0.2.2:8080/api/v1)
┌──────────────────────────────────────────┼─────────────┐
│                 Go Backend (backend/)    │             │
│                 Gorilla Mux HTTP Router  │             │
│                           │                            │
│                 [Middlewares Pipeline]                 │
│         (Correlation -> CORS -> Auth JWT -> RBAC)      │
│                           │                            │
│                 [HTTP Handlers & Server]               │
│      (/login, /me, /sesiones, /asistencias/check-in-qr)│
│              │                            │            │
│         [Auth / JWT]                 [QRCache]         │
│              │                            │            │
│                 [Service Layer (Go)]                   │
│              (Haversine Distance <= 80m)               │
│                           │                            │
│                 [PostgreSQL Database]                  │
│       (Tables, Stored Functions fn_asistencia_*)       │
└────────────────────────────────────────────────────────┘
```

---

## 2. Contratos Reales API REST ↔ Adaptador Flutter

### 2.1 Autenticación (`POST /api/v1/login`)
- **Método**: `POST`
- **Ruta**: `/api/v1/login`
- **Auth Requerida**: Ninguna (Pública)
- **Request Body**:
  ```json
  {
    "identificador": "string (email o DNI)",
    "password": "string (>= 8 caracteres)"
  }
  ```
- **Response HTTP 200**:
  ```json
  {
    "access_token": "string (JWT HS256, 15 min)",
    "refresh_token": "string (JWT HS256, 7 días)",
    "expires_in": 900,
    "token_type": "Bearer"
  }
  ```
- **Estrategia en Flutter**: `ApiEduccaRepository.login` invoca `/login` y con el `access_token` recibido realiza inmediatamente `GET /api/v1/me` para armar el `PromoterUser` y devolver el modelo unificado esperado por `AuthProvider`.

### 2.2 Perfil y Roles (`GET /api/v1/me`)
- **Método**: `GET`
- **Ruta**: `/api/v1/me`
- **Auth Requerida**: `Bearer <access_token>`
- **Response HTTP 200**:
  ```json
  {
    "persona": {
      "id": 1,
      "dni": "00000000",
      "nombres": "Nombre",
      "apellidos": "Apellidos",
      "sexo": "M",
      "fecha_nacimiento": "1995-05-10T00:00:00Z",
      "telefono": "+51984123456",
      "email": "promotor@educca.gob.pe",
      "categoria": "PAJ",
      "consentimiento_at": "2026-11-18T10:00:00Z",
      "consentimiento_version": "v1.0-2026",
      "anonimizado": false,
      "activo": true
    },
    "roles": ["capacitando"],
    "permisos": ["organizaciones:leer", "sesiones:leer", "inscripciones:gestionar", "asistencias:checkin_qr"]
  }
  ```

### 2.3 Registro de Ciudadano / Promotor (`POST /api/v1/register`)
- **Método**: `POST`
- **Ruta**: `/api/v1/register`
- **Auth Requerida**: Ninguna
- **Request Body**:
  ```json
  {
    "dni": "72345678",
    "nombres": "Juan Carlos",
    "apellidos": "Quispe Mamani",
    "sexo": "M",
    "fecha_nacimiento": "2002-04-15",
    "telefono": "+51984123456",
    "email": "juan.quispe@example.org",
    "password": "Password123",
    "categoria": "PAJ",
    "consentimiento_aceptado": true,
    "consentimiento_version": "v1.0-2026"
  }
  ```
- **Response HTTP 201**:
  ```json
  {
    "id": 2,
    "rol": "capacitando",
    "categoria": "PAJ",
    "consentimiento_version": "v1.0-2026",
    "access_token": "...",
    "refresh_token": "...",
    "expires_in": 900,
    "token_type": "Bearer"
  }
  ```

### 2.4 Marcado de Asistencia QR + GPS (`POST /api/v1/asistencias/check-in-qr`)
- **Método**: `POST`
- **Ruta**: `/api/v1/asistencias/check-in-qr`
- **Auth Requerida**: `Bearer <access_token>`
- **Request Body**:
  ```json
  {
    "qr_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
    "latitud": -13.516024,
    "longitud": -71.978051
  }
  ```
- **Response HTTP 201 (Éxito)**:
  ```json
  {
    "message": "Asistencia presencial registrada exitosamente",
    "sesion_id": 1,
    "persona_id": 2,
    "metodo_registro": "QR_GPS",
    "distancia_metros": 24.5,
    "radio_metros": 80
  }
  ```
- **Respuestas de Error en Go**:
  - `HTTP 409 Conflict`: `{"httpStatusCode": 409, "errorCode": 1005, "message": "La asistencia ya fue registrada para esta sesion"}` -> Mapear a `ScanOutcome.duplicate`.
  - `HTTP 422 Unprocessable Entity` (Fuera de radio): `{"httpStatusCode": 422, "errorCode": 1006, "message": "Ubicación fuera del radio permitido de la sede: 115.30 m (máximo 80 m)"}` -> Mapear a `ScanOutcome.outOfRange`.
  - `HTTP 422 Unprocessable Entity` (QR vencido/rotado): `{"httpStatusCode": 422, "errorCode": 1006, "message": "El código QR de la sesión ha expirado o fue rotado/revocado"}` -> Mapear a `ScanOutcome.expired`.
  - `HTTP 422 Unprocessable Entity` (Sesión no presencial o no georreferenciada): -> Mapear a `ScanOutcome.invalid`.

### 2.5 Talleres / Sesiones
- **Catálogo de sesiones**: `GET /api/v1/sesiones?estado=PROGRAMADA`
- **Mis inscripciones**: `GET /api/v1/mi/inscripciones`
- **Inscribirme a taller**: `POST /api/v1/sesiones/{id}/inscripciones`
- **Mapeo a Flutter**: La clase `Course` y `CourseSession` en Flutter se alimentan a partir del DTO plano `Sesion` del backend Go, calculando fecha, duración y sede.

### 2.6 Historial de Asistencias (`GET /api/v1/mi/asistencias`)
- **Método**: `GET`
- **Ruta**: `/api/v1/mi/asistencias`
- **Auth Requerida**: `Bearer <access_token>`
- **Response HTTP 200**:
  ```json
  [
    {
      "sesion_id": 1,
      "titulo": "Manejo Integral de Residuos",
      "eje_tematico": "RESIDUOS_SOLIDOS",
      "modalidad": "PRESENCIAL",
      "fecha_inicio": "2026-11-20T10:00:00Z",
      "estado_sesion": "EN_CURSO",
      "participacion": "ASISTENTE",
      "calificacion": null,
      "metodo_registro": "QR_GPS",
      "distancia_metros": 22.4,
      "registrado_at": "2026-11-20T10:12:00Z"
    }
  ]
  ```
