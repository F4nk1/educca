# Quickstart & Verification Guide: EDUCCA Móvil Sprint 1

**Feature**: `002-educca-mobile-sprint1`  
**Date**: 2026-11-17  
**Status**: Ready

Esta guía permite al equipo y evaluadores compilar, ejecutar y validar los flujos del Sprint 1 (HU-01, HU-04, RNF-01) tanto en modo de integración real con el backend en Go como en modo de simulación local (*Mock Demo*).

---

## 1. Requisitos Previos y Entorno

* **SDK Flutter**: ^3.14.0 (Dart SDK ^3.14.0).
* **Emulador Android**: Android 8.0+ (API Level 26 o superior). Recomendado: AVD con Google Play Services para pruebas de sensor GPS.
* **Dispositivo Físico**: Habilitar *Depuración por USB* y *Ubicaciones de prueba* si se desea simular GPS.
* **Dependencias nuevas en `pubspec.yaml`**: `geolocator: ^13.0.2`.

---

## 2. Comandos de Preparación y Verificación Estática

Ejecutar en la raíz del proyecto `sistema-capacitaciones/`:

```bash
# 1. Obtener dependencias actualizadas
flutter pub get

# 2. Análisis estático (Calidad de Código - Cero errores tolerados)
flutter analyze

# 3. Ejecutar suite de pruebas automatizadas
flutter test
```

---

## 3. Escenarios de Prueba Manual y Verificación

### Escenario A: Modo Demostración Local (Sin Backend Go)
Ideal para verificar UI, animaciones y respuestas cuando Dev 1 no ha desplegado el backend.
1. Al iniciar la app en debug, pulsar el botón de configuración de servidor en el login.
2. Activar la casilla **«Modo Demostración (Simulado)»**.
3. Verificar la presencia del banner visual **«MODO DEMOSTRACIÓN — DATOS SIMULADOS»** en la parte superior.
4. **Prueba de HU-01 (Registro):**
   * Ir a «Crear cuenta».
   * Completar datos, seleccionar «Comunitario» y marcar consentimiento → Registro exitoso.
   * Seleccionar «Escolar» e indicar menor de edad → Verificar botón bloqueado y mensaje orientativo.
5. **Prueba de HU-04 (Escaneo y GPS):**
   * Abrir escáner y usar el botón de *Ingreso Manual de Token* (para emuladores).
   * Ingresar token de prueba `DEMO_OK` → Retorna asistencia confirmada (≤ 80 m).
   * Ingresar token `DEMO_FAR` → Retorna advertencia modal *«Fuera del área de asistencia»* (> 80 m).

---

### Escenario B: Integración Real con Backend Go + PostgreSQL
1. En el emulador Android, la URL base del backend que corre en la máquina anfitriona es `http://10.0.2.2:8080/api/v1` (o puerto configurado por Dev 1).
2. Para dispositivo físico en la misma red Wi-Fi: `http://192.168.X.X:8080/api/v1`.
3. Configurar la URL en el diálogo de ajustes de la pantalla de Login y pulsar *Guardar*.
4. **Simulación de Coordenadas GPS en Android Studio:**
   * Abrir los controles extendidos del emulador (`...` en la barra lateral del AVD).
   * Ir a **Location**.
   * Caso Dentro de 80 m: Ingresar coordenadas coincidentes con la sede registrada en BD (ej. Plaza Mayor Cusco: `-13.5168`, `-71.9788`).
   * Caso Fuera de 80 m: Ingresar coordenadas distantes (ej. `-13.5350`, `-71.9500`).
   * Escanear el QR proyectado por el capacitador web y contrastar las respuestas con los criterios de aceptación.

---

## 4. Matriz de Cobertura de Pruebas Automatizadas

| Archivo de Prueba | Tipo | Cobertura / Criterio Verificado |
|---|---|---|
| `test/unit/core_test.dart` | Unitaria | `ApiClient`, inyección de token JWT, manejo de timeout y 401. |
| `test/unit/promoter_user_test.dart` | Unitaria | Deserialización tolerante de roles EDUCCA, categorías y consentimiento. |
| `test/unit/attendance_models_test.dart` | Unitaria | Mapeo de `ScanOutcome` (`outOfRange`, `locationInaccurate`, etc.). |
| `test/widget/login_screen_test.dart` | Widget | Renderizado de inputs, validación de correo y navegación a registro. |
| `test/widget/register_screen_test.dart` | Widget | Formulario de promotor, bloqueo de escolares menores y consentimiento. |
| `test/widget/scan_result_dialog_test.dart` | Widget | Estados visuales para fuera de radio (> 80 m) y precisión insuficiente. |
