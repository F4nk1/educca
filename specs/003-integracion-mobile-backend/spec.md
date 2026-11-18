# Especificación de Integración: Mobile Flutter ↔ Backend Go
**Feature ID**: `003-integracion-mobile-backend`  
**Proyecto**: EDUCCA Cusco (EcoCapacita)  
**Estado**: Borrador de Diagnóstico Aprobado para Planificación  
**Fecha**: 2026-11-18  

---

## 1. Alcance y Contexto

Esta especificación define el contrato de integración real entre la aplicación móvil Android (`mobile/`) desarrollada en Flutter/Dart y la API REST del backend (`backend/`) desarrollada en Go con PostgreSQL.

El objetivo es sustituir el consumo simulado (`MockEduccaRepository`) por llamadas HTTP efectivas al backend Go a través de `ApiEduccaRepository`, adaptando los contratos sin alterar la experiencia visual ni romper el modo demostración necesario para pruebas aisladas.

---

## 2. Criterios de Aceptación

### CA-01: Autenticación Unificada y Sesión JWT
- **CA-01.1**: El inicio de sesión móvil debe consumir `POST /api/v1/login` enviando `{"identificador": "...", "password": "..."}`.
- **CA-01.2**: Tras recibir el par de tokens (`access_token`, `refresh_token`), la aplicación debe consultar de inmediato `GET /api/v1/me` para obtener el perfil de la `Persona` y sus roles/permisos.
- **CA-01.3**: El token de acceso y los datos de perfil deben persistirse en `SessionStorage` de forma cifrada.
- **CA-01.4**: Las peticiones protegidas deben incluir la cabecera `Authorization: Bearer <access_token>`.

### CA-02: Registro de Ciudadanos / Promotores
- **CA-02.1**: El registro desde el móvil debe consumir `POST /api/v1/register` enviando el DTO completo requerido por el backend Go (`dni`, `nombres`, `apellidos`, `sexo`, `fecha_nacimiento`, `telefono`, `email`, `password`, `categoria`, `consentimiento_aceptado`, `consentimiento_version`).
- **CA-02.2**: El registro asigna en el backend el rol `capacitando` con la categoría válida (`PAC`, `PAJ`, `COMERCIANTE`, `RECICLADOR`).
- **CA-02.3**: Si la persona es menor de 18 años o no acepta el consentimiento LPDP, el backend devuelve HTTP 422 y la app debe mostrar un mensaje amigable sin crash.

### CA-03: Catálogo de Talleres y Próxima Actividad
- **CA-03.1**: La consulta de capacitaciones debe consumir `GET /api/v1/sesiones` (catálogo disponible) y `GET /api/v1/mi/inscripciones` (talleres inscritos del promotor).
- **CA-03.2**: La pantalla principal y la lista de talleres deben mapear las `Sesiones` del backend a los modelos visuales sin perder estados (`PROGRAMADA`, `EN_CURSO`, `CONCLUIDA`, `VALIDADA`).

### CA-04: Marcado de Asistencia QR + GPS (Geocerca 80 metros)
- **CA-04.1**: El marcado presencial debe consumir `POST /api/v1/asistencias/check-in-qr` enviando `{"qr_token": "...", "latitud": ..., "longitud": ...}`.
- **CA-04.2**: El token QR escaneado es un JWT firmado por el backend con claim `token_use: "qr_checkin"`.
- **CA-04.3**: Si la distancia calculada en el backend excede `radio_metros` (80 m), el backend responde HTTP 422 con mensaje de distancia; la app debe mapear este resultado a `ScanOutcome.outOfRange`.
- **CA-04.4**: Si la asistencia ya fue registrada, el backend responde HTTP 409; la app debe mapear el resultado a `ScanOutcome.duplicate`.
- **CA-04.5**: Si el QR expiró o fue revocado, el backend responde HTTP 422; la app debe mapear a `ScanOutcome.expired`.
- **CA-04.6**: En caso de éxito, el backend responde HTTP 201; la app actualiza el estado y añade el registro a `AttendanceProvider`.

### CA-05: Historial de Asistencias
- **CA-05.1**: La pantalla de historial debe consumir `GET /api/v1/mi/asistencias`.
- **CA-05.2**: Los registros deben reflejar `distancia_metros`, `metodo_registro` (`QR_GPS`) y fecha de confirmación.

### CA-06: Preservación del Modo Demostración
- **CA-06.1**: El modo demo simulado (`MockEduccaRepository`) debe continuar disponible mediante el selector de entorno en modo debug.
