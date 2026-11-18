# Tareas de Implementación: Integración Mobile Flutter ↔ Backend Go
**Feature ID**: `003-integracion-mobile-backend`  
**Proyecto**: EDUCCA Cusco (EcoCapacita)  
**Estado**: Borrador de Diagnóstico Aprobado para Planificación  
**Fecha**: 2026-11-18  

---

## Fase 1: Alineación de Contratos y Repositorio HTTP (Flutter)
- [x] **T01-01**: Actualizar `ApiEduccaRepository.login` para invocar `POST /login` con `identificador` y resolver de inmediato `GET /me` para consolidar el perfil de usuario.
- [x] **T01-02**: Actualizar `ApiEduccaRepository.scanAttendance` para apuntar a `POST /asistencias/check-in-qr` con cuerpo `{"qr_token": "...", "latitud": ..., "longitud": ...}`.
- [x] **T01-03**: Mapear los errores HTTP de Go (`409 Conflict`, `422 Unprocessable Entity` con mensaje de distancia/expiración) hacia los `ScanOutcome` de Flutter (`duplicate`, `outOfRange`, `expired`, `invalid`).
- [x] **T01-04**: Actualizar `ApiEduccaRepository.getAttendanceHistory` para consultar `GET /mi/asistencias`.
- [x] **T01-05**: Adaptar `ApiEduccaRepository.getPromoterSessions` para consultar `GET /sesiones` y `GET /mi/inscripciones`.

## Fase 2: Modelos y Almacenamiento de Sesión
- [x] **T02-01**: Actualizar `PromoterUser` y `Persona` DTO en Flutter para contemplar los campos del backend Go (`dni`, `sexo`, `fechaNacimiento`, `categoria`).
- [x] **T02-02**: Adaptar los valores del enum de categoría del promotor para incluir `PAC`, `PAJ`, `COMERCIANTE`, `RECICLADOR` preservando aliases escolares/juveniles.
- [x] **T02-03**: Ajustar `SessionStorage` para persistir `access_token` y `refresh_token`, con reintento automático en `ApiClient`.

## Fase 3: Conexión de Pantalla de Registro (M02)
- [x] **T03-01**: Actualizar el formulario de registro en `RegisterScreen` y `ApiEduccaRepository.registerPromoter` para recopilar y mapear `dni`, `nombres`, `apellidos`, `sexo` y `fecha_nacimiento` requeridos por la Ley LPDP en el backend Go.

## Fase 4: Entorno Local y Verificación Integral
- [x] **T04-01**: Análisis del entorno de ejecución local (`backend/.env`, PostgreSQL y dependencias). Bloqueo documentado por ausencia de runtime Go/PostgreSQL en el host.
- [x] **T04-02**: Configuración de `AppConfig` con URL `http://10.0.2.2:8080/api/v1` para el emulador Android.
- [x] **T04-03**: Suite de pruebas de contratos y DTOs automatizados implementada en `test/unit/integration_contracts_test.dart`.
- [x] **T04-04**: 40 pruebas automatizadas aprobadas (35 de regresión + 5 de integración) y análisis estático con 0 incidencias (`flutter analyze`).
