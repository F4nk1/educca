# Research & Architecture Decisions: MVP Aplicación Móvil

**Feature**: `specs/001-mobile-training-mvp`  
**Date**: 2026-11-17  
**Scope**: Cliente móvil Flutter/Dart exclusivo para la Entrega 2 (E2) de Ingeniería de Software I.

---

## 1. Decisiones Tecnológicas Principales

### Decisión 1: Cliente de Red y Comunicación REST
- **Elección**: `http` (v1.2.0+) con un servicio base centralizado (`ApiClient`).
- **Razón**: 
  - La aplicación móvil solo requiere operaciones REST estándar (JSON GET y POST con encabezados `Authorization: Bearer <token>`).
  - La biblioteca oficial `http` es ligera, sumamente estable, no introduce dependencias nativas complejas y facilita el mock testing mediante `http.Client`.
  - Un wrapper personalizado `ApiClient` centraliza la URL base configurable, inyección de tokens y mapeo unificado de errores HTTP (401, 403, 422, 500 y timeouts).
- **Alternativas consideradas**:
  - `dio`: Muy potente con interceptores avanzados, pero introduce dependencias más pesadas e innecesarias para el alcance acotado del MVP E2.
  - Paquetes GraphQL / WebSockets: Descartados porque el contrato acordado con el equipo backend es una API REST JSON.

### Decisión 2: Lector de Códigos QR en Dispositivo Móvil
- **Elección**: `mobile_scanner` (v5.x / v6.x).
- **Razón**: 
  - Basado en Google ML Kit para Android y AVFoundation para iOS.
  - Ofrece alto rendimiento en tiempo real, detección instantánea de códigos QR en pantallas (proyector o monitor de la web del instructor), compatibilidad comprobada con emuladores Android (cámara virtual o emulada) y ciclo de vida de widget directo (`MobileScannerController`).
  - Permite congelar el controlador (`controller.stop()` o bandera de control en memoria) inmediatamente tras detectar el primer código para evitar ráfagas de peticiones de escaneo.
- **Alternativas consideradas**:
  - `qr_code_scanner`: Paquete legacy ampliamente utilizado en el pasado, pero oficialmente discontinuado y con problemas de compatibilidad con versiones recientes de Android SDK y Flutter 3.x.
  - `fast_qr_reader_view`: Requiere configuración nativa manual adicional compleja; descartado.

### Decisión 3: Almacenamiento Seguro de Credenciales y Sesión
- **Elección**: `flutter_secure_storage` (para JWT y perfil de sesión) combinado con `shared_preferences` (para la URL base del backend).
- **Razón**: 
  - Cumple estrictamente con el Principio I de la Constitución (almacenamiento encriptado de tokens mediante Android Keystore / EncryptedSharedPreferences).
  - Nunca almacena tokens en texto plano.
  - `shared_preferences` se reserva únicamente para la URL base configurada (dato no sensible ni confidencial), permitiendo cambiar de IP sin perder el token si no se desea.
- **Alternativas consideradas**:
  - `shared_preferences` para todo: Descartado categóricamente por almacenar el token en XML plano accesible en dispositivos rooteados o volcados de memoria, violando la LPDP y las normas de seguridad.
  - `Hive` / `Isar` con clave de cifrado: Sobreingeniería innecesaria para guardar únicamente 2 pares clave-valor de sesión.

### Decisión 4: Gestión de Estado (State Management)
- **Elección**: `provider` con `ChangeNotifier` (o `ValueNotifier` / controladores de estado modularizados).
- **Razón**: 
  - Patrón oficial promovido por el equipo de Flutter, fácil de auditar y comprender por cualquier miembro del equipo estudiantil.
  - No añade curva de aprendizaje pronunciada ni exceso de clases abstractas (*boilerplate*).
  - Separa limpiamente la lógica de presentación (Widgets) de la lógica de negocio (AuthNotifier, CoursesNotifier, AttendanceNotifier).
- **Alternativas consideradas**:
  - `flutter_bloc`: Excelente para sistemas masivos empresariales, pero excesivamente verborrágico y complejo para un MVP de 5 pantallas en un proyecto académico de 2 semanas.
  - `GetX`: Introduce antipatrones de desacoplamiento de contexto y dependencias mágicas difíciles de mantener; descartado por gobernanza de calidad de código.

### Decisión 5: Manejo de Configuración de Entornos y URL Base
- **Elección**: Servicio de configuración `AppConfig` con valor inicial por defecto (`http://10.0.2.2:3000` para emulador Android) y modal de edición rápida en la pantalla de inicio de sesión persistido en `shared_preferences`.
- **Razón**: 
  - Resuelve la clarificación formal acordada en la especificación: permite probar el APK en el emulador de Android Studio (`10.0.2.2`), en teléfono físico conectado a la misma red Wi-Fi (`192.168.1.X:3000`) o contra un túnel Ngrok sin recompilar el código.
- **Alternativas consideradas**:
  - Constante estática quemada en el código: Rechazada porque obliga a recompilar la aplicación cada vez que cambia la red de pruebas.
  - Solo archivo `.env`: Útil en desarrollo, pero rígido si se genera un APK release o de demostración presencial.

---

## 2. Resumen de Dependencias del MVP (Flutter `pubspec.yaml`)

```yaml
dependencies:
  flutter:
    sdk: flutter
  cupertino_icons: ^1.0.8
  # Red y contratos REST
  http: ^1.2.2
  # Almacenamiento seguro de tokens y configuración
  flutter_secure_storage: ^9.2.2
  shared_preferences: ^2.3.2
  # Gestión de estado reactiva y desacoplada
  provider: ^6.1.2
  # Lector QR con soporte Android ML Kit
  mobile_scanner: ^6.0.4
```

---

## 3. Matriz de Estados de Interfaz Requeridos

Cada pantalla de consulta asíncrona implementa de manera unificada:

| Estado | Componente visual | Comportamiento |
|---|---|---|
| **Loading** | `CircularProgressIndicator` centrado o *Shimmer* | Bloquea interacciones repetitivas mientras espera respuesta del servidor. |
| **Content** | `ListView` / Tarjetas con información completa | Presenta los datos obtenidos con soporte para gesto *Pull-to-Refresh*. |
| **Empty** | Ilustración/Icono + Texto explicativo | Informa con cortesía ("No tienes capacitaciones activas", "No hay asistencias registradas"). |
| **Error** | Icono de advertencia + Mensaje amigable + Botón "Reintentar" | Atrapa fallos de red, timeouts o 500 sin crashear la aplicación. |
