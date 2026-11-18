# Technical Research: Adaptación Móvil EDUCCA Cusco — Sprint 1

**Feature**: `002-educca-mobile-sprint1`  
**Date**: 2026-11-17  
**Status**: Completed  
**Author**: Antigravity (Mobile Architect)

---

## 1. Decisiones Técnicas y Selección de Paquetes

### Decisión 1: Captura de Geolocalización Puntual en Android (HU-04 / RNF-01)
* **Elección**: `geolocator: ^13.0.2`
* **Justificación**:
  * Es el estándar de facto en Flutter para geolocalización nativa en Android (compatible con Android 8.0+ / API 26+).
  * Soporta nativamente la adquisición puntual sin streams continuos mediante `Geolocator.getCurrentPosition(locationSettings: LocationSettings(accuracy: LocationAccuracy.high, timeLimit: Duration(seconds: 10)))`.
  * Permite consultar el estado del servicio (`Geolocator.isLocationServiceEnabled()`) y gestionar permisos en tiempo de ejecución (`Geolocator.checkPermission()` / `Geolocator.requestPermission()`) sin requerir paquetes adicionales como `permission_handler`.
  * No inicia procesos en segundo plano ni requiere `ACCESS_BACKGROUND_LOCATION`.
* **Alternativas evaluadas y descartadas**:
  * `location`: Mayor sobrecarga de configuración y menor control granular sobre timeouts puntuales estrictos.
  * Captura manual vía MethodChannels nativos en Java/Kotlin: Innecesaria sobreingeniería; viola el principio de desarrollo pragmático y agilidad del Sprint 1.

### Decisión 2: Desacoplamiento y Adaptabilidad frente al Backend Go (`EduccaRepository`)
* **Elección**: Patrón Repository mínimo con interfaz abstracta `EduccaRepository` y dos implementaciones:
  1. `ApiEduccaRepository`: Delega llamadas HTTP a través del [ApiClient](file:///C:/Users/Fidel/Desktop/sistema-capacitaciones/lib/core/api_client.dart) existente hacia el servidor Go + PostgreSQL.
  2. `MockEduccaRepository`: Mock en memoria disponible exclusivamente en builds `kDebugMode` para simular casos positivos y negativos (éxito, fuera de radio > 80 m, duplicado, QR vencido) sin depender del despliegue del compañero (Dev 1).
* **Justificación**:
  * Cumple con la Constitución v3.0.0 (Principio I y IV) y la aclaración de la especificación: la UI y los Providers no se atan a rutas HTTP inmutables ni a DTOs rígidos.
  * Si Dev 1 modifica un campo JSON o ruta relativa, el cambio se confina al repositorio sin impactar pantallas ni widgets.
* **Alternativas evaluadas y descartadas**:
  * Llamadas directas de `http` en pantallas/providers: Difícil de testear y alto acoplamiento frente a cambios del backend.
  * Clean Architecture estricta (DataSources, UseCases, Mappers redundantes): Genera boilerplate excesivo prohibido por la Constitución v3.0.0.

### Decisión 3: Serialización Retrocompatible de Usuario (`PromoterUser` vs `StudentUser`)
* **Elección**: Renombrar/extender conceptualmente a `PromoterUser` en [promoter_user.dart](file:///C:/Users/Fidel/Desktop/sistema-capacitaciones/lib/models/promoter_user.dart) manteniendo tolerancia a claves JSON antiguas (`name`, `fullName`, `role`) e introduciendo las claves EDUCCA (`promoterCategory`, `isAdult`, `privacyConsentAccepted`).
* **Justificación**:
  * Permite deserializar respuestas del backend previo y del nuevo backend en Go sin lanzar `FormatException`.
  * Facilita que `SessionStorage` pueda leer tokens y perfiles cacheados previamente sin corromper la sesión del desarrollador.

### Decisión 4: Flujo de Consentimiento y Contención de Menores (HU-01 / RNF-01)
* **Elección**:
  1. Formulario reactivo en [register_screen.dart](file:///C:/Users/Fidel/Desktop/sistema-capacitaciones/lib/screens/register_screen.dart).
  2. Al seleccionar categoría `escolar`, se activa dinámicamente un campo de confirmación: *"Declaro que tengo 18 años o más"*.
  3. Si el usuario indica ser menor de edad (< 18 años), el botón de envío se desactiva y se muestra un banner informativo: *"El registro de promotores escolares menores de edad es coordinado directamente por su institución educativa. Consulta con tu docente o coordinador EDUCCA"*.
  4. Casilla de consentimiento informado con enlace modal al aviso de privacidad.
* **Justificación**:
  * Resuelve la aclaración formal de la sesión 2026-11-17 (Opción A).
  * No inventa representación legal de tutores en la app móvil mientras el Product Owner define el protocolo legal definitivo.

### Decisión 5: Manejo de Timeout (10 s) y Filtro de Precisión GPS (50 m)
* **Elección**:
  * Adquisición de coordenadas con `timeLimit: const Duration(seconds: 10)`.
  * Verificación inmediata: `if (position.accuracy > 50.0)` → se rechaza localmente retornando `ScanOutcome.locationInaccurate`.
  * Si ocurre timeout → se captura `TimeoutException` y se retorna `ScanOutcome.gpsTimeout`.
  * Solo si `position.accuracy <= 50.0` se transmite la posición al backend.
* **Justificación**:
  * Resuelve la aclaración técnica formal (Opción A).
  * Evita que el servidor calcule distancias erráticas sobre lecturas con incertidumbre mayor a 50 metros en Cusco.

---

## 2. Puntos de Homologación con el Desarrollador Backend (Dev 1 / Go + PostgreSQL)

Los siguientes aspectos deben ser ratificados formalmente antes del congelamiento final:

| Aspecto | Propuesta Móvil (Borrador) | Estado / Impacto en Dev 1 (Go) |
|---|---|---|
| Ruta de Registro | `POST /auth/register` | Confirmar ruta y campos del payload (`fullName`, `email`, `password`, `promoterCategory`, `privacyConsentAccepted`). |
| Ruta de Login | `POST /auth/login` | Confirmar ruta, formato de token (JWT en `token` o `accessToken`) y objeto `user`. |
| Ruta de Marcado QR | `POST /attendance/scan` | Confirmar payload con `qrToken` y objeto `location` (`latitude`, `longitude`, `accuracyMeters`, `capturedAt`). |
| Semántica de Fuera de Radio | Código `OUT_OF_RANGE` con HTTP 400 o HTTP 200 con `{ status: "OUT_OF_RANGE" }` | Homologar cómo el handler en Go emite el rechazo cuando la distancia horizontal calculada en Postgres (Haversine/PostGIS) es > 80 m. |
| Formato de Token QR | String alfanumérico o JWT efímero | Confirmar que el QR proyectado por el capacitador (HU-03) contenga solo el token sin datos personales ni coordenadas de sede. |
