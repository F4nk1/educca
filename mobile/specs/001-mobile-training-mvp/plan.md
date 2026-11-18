# Implementation Plan: MVP de Aplicación Móvil de Gestión de Capacitaciones

**Branch**: `001-mobile-training-mvp` | **Date**: 2026-11-17 | **Spec**: [specs/001-mobile-training-mvp/spec.md](file:///C:/Users/Fidel/Desktop/sistema-capacitaciones/specs/001-mobile-training-mvp/spec.md)

**Input**: Feature specification from `/specs/001-mobile-training-mvp/spec.md`

## Summary

Desarrollo incremental del cliente móvil Flutter/Dart para la Entrega 2 (E2) del Sistema de Gestión de Capacitaciones. La aplicación provee al estudiante una experiencia móvil ligera, segura y reactiva para autenticarse, consultar capacitaciones inscritas y sesiones programadas, escanear códigos QR dinámicos para registrar su asistencia única e inspeccionar su historial personal, consumiendo un servicio backend externo mediante contratos REST JSON estandarizados.

## Technical Context

**Language/Version**: Dart 3.x / Flutter SDK 3.x+  
**Primary Dependencies**: `http` (^1.2.2), `flutter_secure_storage` (^9.2.2), `shared_preferences` (^2.3.2), `provider` (^6.1.2), `mobile_scanner` (^6.0.4), `cupertino_icons` (^1.0.8)  
**Storage**: `flutter_secure_storage` (token JWT y perfil autenticado encriptado en Android Keystore), `shared_preferences` (URL base del backend configurable)  
**Testing**: `flutter_test` (pruebas unitarias para DTOs, modelos y token storage; pruebas de widgets para estados asíncronos)  
**Target Platform**: Android (mínimo Android SDK 21+, probado en emulador de Android Studio y dispositivo físico)  
**Project Type**: Mobile Application (`mobile-app`)  
**Performance Goals**: Escaneo y procesamiento de QR en < 3 s; carga de vistas y login en < 10 s bajo conexión estable  
**Constraints**: Modelo estrictamente en línea (*online-first*); sin almacenamiento redundante de bases de datos offline; sin PII en payloads de QR; cero advertencias en `flutter analyze`  
**Scale/Scope**: Rol Estudiante para Entrega 2 (5 pantallas principales: Login, Mis Cursos, Detalle de Sesión, Escáner QR, Historial de Asistencia)  

## Constitution Check

*GATE: Evaluado conforme a la Constitución del Proyecto v2.0.0*

- **Gate 1: Contract-Driven API Consumption & Client-Side Security**  
  *Estado*: **PASS**  
  *Evaluación*: Todos los endpoints (`/auth`, `/student/courses`, `/student/attendance`) están formalizados bajo contratos REST en `contracts/`. Los tokens JWT se almacenan únicamente en `flutter_secure_storage` y se purgan al cerrar sesión o recibir HTTP 401.
- **Gate 2: Privacy-Preserving QR Scanning & Attendance Flow**  
  *Estado*: **PASS**  
  *Evaluación*: El escáner solo lee el token efímero del QR proyectado por el instructor, sin extraer datos personales. Se congela el escaneo tras la primera detección para prevenir ráfagas concurrentes. Las respuestas del servidor (éxito, duplicado, vencido) se presentan con retroalimentación clara.
- **Gate 3: Compliance with Personal Data Protection (LPDP & Ethics)**  
  *Estado*: **PASS**  
  *Evaluación*: Se aplica minimización de datos estricta. No se solicita geolocalización (GPS) para el MVP E2. El permiso de cámara incluye solicitud contextual transparente.
- **Gate 4: Pragmatic Mobile Architecture & Configurable Environments**  
  *Estado*: **PASS**  
  *Evaluación*: Se implementa una arquitectura modular estándar en `lib/` sin capas complejas ni sobreingeniería. La URL base es editable desde la pantalla de login persistida en `shared_preferences`.
- **Gate 5: Mobile Quality Gates, Static Analysis & Incremental Verification**  
  *Estado*: **PASS**  
  *Evaluación*: Todas las pantallas implementan los 4 estados asíncronos (*Loading*, *Content*, *Empty*, *Error*). Se exige `flutter analyze` con cero errores/advertencias.

## Project Structure

### Documentation (this feature)

```text
specs/001-mobile-training-mvp/
├── plan.md              # Plan de implementación y arquitectura (/speckit-plan)
├── research.md          # Decisiones tecnológicas y análisis de paquetes (/speckit-plan)
├── data-model.md        # Modelos Dart, DTOs y enumeradores (/speckit-plan)
├── quickstart.md        # Guía de validación y escenarios de prueba (/speckit-plan)
├── contracts/           # Contratos REST JSON con el backend (/speckit-plan)
│   ├── auth.contract.md
│   ├── courses.contract.md
│   └── attendance.contract.md
├── checklists/
│   └── requirements.md  # Validación de calidad de la especificación
└── spec.md              # Especificación funcional de requisitos
```

### Source Code (repository root)

```text
lib/
├── config/
│   ├── app_config.dart          # Gestión de URL base y constantes globales
│   └── app_theme.dart           # Colores institucionales y estilos Material 3
├── core/
│   ├── api_client.dart          # Cliente HTTP unificado, inyección Bearer y mapeo de errores
│   ├── session_storage.dart     # Wrapper de flutter_secure_storage para tokens JWT
│   └── result.dart              # Patrón Result/Either para manejo robusto de respuestas
├── models/
│   ├── student_user.dart        # DTO del estudiante
│   ├── course.dart              # DTO de capacitaciones
│   ├── course_session.dart      # DTO de sesiones programadas
│   ├── attendance_record.dart   # DTO de constancia de asistencia
│   └── scan_result.dart         # DTO de respuesta del escaneo QR
├── providers/
│   ├── auth_provider.dart       # Estado de sesión, login, logout y auto-redirección
│   ├── courses_provider.dart    # Estado de lista de cursos y sesiones
│   └── attendance_provider.dart # Estado de escaneo de QR e historial
└── screens/
    ├── login_screen.dart        # Formulario de acceso y diálogo de ajustes de IP
    ├── home_screen.dart         # Navegación principal (tabs: Cursos, Historial) y botón QR
    ├── courses_screen.dart      # Lista "Mis Capacitaciones" (Pull-to-Refresh)
    ├── session_detail_screen.dart # Cronograma de sesiones y botón contextual de escaneo
    ├── qr_scanner_screen.dart   # Visor de cámara con mobile_scanner y control de throttle
    └── attendance_history_screen.dart # Historial de asistencias confirmadas
test/
├── unit/
│   ├── api_client_test.dart
│   ├── models_test.dart
│   └── session_storage_test.dart
└── widget/
    ├── login_screen_test.dart
    └── courses_screen_test.dart
```

**Structure Decision**: Arquitectura modular estándar de Flutter, separando configuración (`config/`), infraestructura de red y almacenamiento (`core/`), entidades (`models/`), estado reactivo (`providers/`) y vistas (`screens/`).

## Complexity Tracking

> **Sin violaciones a la Constitución detectadas.** Todas las compuertas de gobernanza pasaron en estado **PASS**.

| Violation | Why Needed | Simpler Alternative Rejected Because |
|---|---|---|
| Ninguna | N/A | N/A |
