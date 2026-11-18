<!--
# Sync Impact Report
- Version change: 2.0.0 -> 3.0.0
- List of modified principles:
  * I. Contract-Driven API Consumption & Client-Side Security -> I. Contract-Driven API Consumption & Backend Authority
  * II. Privacy-Preserving QR Scanning & Attendance Flow -> II. Privacy-Preserving QR Scanning & Single-Point Geolocation Attendance
  * III. Compliance with Personal Data Protection (LPDP & Ethics) -> III. Compliance with Personal Data Protection (LPDP), Ethics & Informed Consent
  * IV. Pragmatic Mobile Architecture & Configurable Environments -> IV. Pragmatic Modular Flutter Architecture, Asset Reuse & EDUCCA Domain
  * V. Mobile Quality Gates, Static Analysis & Incremental Verification -> V. Mobile Quality Gates, Static Analysis & Incremental Verification
- Added sections:
  * EDUCCA Domain & User Role Governance (COORDINADOR, CAPACITADOR, PROMOTOR with escolar/juvenil/comunitario categories)
  * Single-Point Geolocation & Privacy Constraints (lifting absolute MVP GPS ban; allowing only instantaneous capture during scan; zero continuous tracking; zero local GPS persistence; 80 m geofence strictly server-side)
  * Minor Protection & Informed Consent Governance (school promoter legal policy pending PO confirmation)
- Removed sections:
  * Legacy E2 academic course-only assumptions and absolute prohibition of device location data.
- Follow-up TODOs:
  * TODO(PO_LEGAL_CONSENT): Confirm legal protocol and parental authorization requirement for minor/school promoter registration (D-04).
  * TODO(BACKEND_API_CONTRACT): Finalize and ratify official REST DTO schemas and endpoints with Go/PostgreSQL backend developer (D-01, D-02).
-->

# Programa Municipal EDUCCA Cusco — App Móvil Constitution

## Core Principles

### I. Contract-Driven API Consumption & Backend Authority
This repository is exclusively responsible for the Flutter/Dart Android mobile client for the Programa Municipal EDUCCA (Gerencia de Medio Ambiente y Servicios Públicos de Cusco). All persistent business logic, enrollment authority, user role access, workshop scheduling, and final attendance determination reside in an external backend developed in Go with PostgreSQL.
- The mobile app MUST interact with the backend strictly through mutually agreed REST API contracts; mobile developers MUST NOT invent definitive routes or assume unconfirmed endpoints from draft documentation.
- The external backend is the single source of truth: it MUST validate QR validity, session status, promoter enrollment, and geofence compliance. The mobile client MUST NEVER self-certify or fabricate successful attendance marks.
- The app MUST handle all standard HTTP responses (200 OK, 400 Bad Request, 401 Unauthorized, 403 Forbidden, 409 Conflict, 422 Unprocessable Entity, 500 Internal Error) gracefully.
- Authentication tokens (JWT) MUST be stored securely using platform-appropriate secure hardware storage (`flutter_secure_storage` with Android Keystore / EncryptedSharedPreferences) and NEVER in plaintext SharedPreferences, debug logs, or hardcoded strings.
- Upon user logout or receipt of an HTTP 401 (token expiration/revocation), the app MUST purge local session credentials and route the user to the login view immediately.
- **Rationale**: Decouples the client UI from the Go backend while maintaining zero-trust architecture and credential protection on user devices.

### II. Privacy-Preserving QR Scanning & Single-Point Geolocation Attendance
The mobile application facilitates attendance marking by capturing dynamic, ephemeral session QR tokens via the device camera coupled with a single-point location measurement.
- The camera scanner MUST capture only the ephemeral token emitted by the workshop session display; it MUST NEVER parse student/promoter PII (such as DNI, full name, or email) from QR payloads.
- **Single-Point Geolocation**: Location coordinates (`latitude`, `longitude`, `accuracyMeters`, and timestamp `capturedAt`) MAY ONLY be requested and captured at the exact instant the user confirms attendance marking.
- **Strict Anti-Tracking Rule**: Continuous location tracking, background location services, `watchPosition` listeners, geofence monitoring services, and local persistence of coordinate histories are STRICTLY PROHIBITED.
- **Backend Distance Calculation**: The 80-meter maximum tolerance from the registered venue MUST be calculated and verified exclusively by the backend using official venue coordinates stored in the database. The client MUST NOT calculate or decide distance compliance.
- In-memory scan states MUST throttle or lock repeat scans immediately upon detection to avoid redundant requests.
- **Rationale**: Satisfies EDUCCA Sprint 1 HU-04 (RF-06) requirements while guaranteeing user privacy and strictly preventing surveillance or battery drain.

### III. Compliance with Personal Data Protection (LPDP), Ethics & Informed Consent
The mobile application MUST operate in strict compliance with Peruvian Personal Data Protection Law N.° 29733, its regulation (D.S. N.° 016-2024-JUS), and municipal transparency standards.
- **Informed Consent**: The mobile registration and attendance flows MUST incorporate an explicit informed consent clause and privacy notice clearly detailing the single-point verification purpose before transmitting data.
- **Data Minimization**: Only essential promoter profile data, session context, and confirmed attendance summaries may reside on the client device. Coordinates captured for attendance MUST NOT be stored in local caches or databases.
- Sensitive user data, authentication headers, passwords, and raw GPS coordinates MUST NEVER be written to console outputs (`print`/`debugPrint` in production), persistent device log files, or unencrypted local caches.
- **Minor/School Promoter Protection**: Until the Product Owner and legal counsel confirm the formal parental authorization mechanism (`TODO(PO_LEGAL_CONSENT)`), the mobile app MUST NOT collect unverified consents from minors or bypass guardian verification.
- **Rationale**: Protects citizen rights, ensures ethical handling of environmental volunteer data, and satisfies RNF-01.

### IV. Pragmatic Modular Flutter Architecture, Asset Reuse & EDUCCA Domain
The codebase MUST maintain a clear, lightweight, and incremental modular structure without overengineering or unnecessary abstractions.
- **EDUCCA Domain Alignment**: The mobile application is primarily tailored for the **Promotor Ambiental** role (categories: `escolar`, `juvenil`, `comunitario`). Roles of **Coordinador** (venue registration and scheduling) and **Capacitador** (workshop management and QR generation) are administered via web interfaces and MUST NOT introduce administrative overhead into the mobile codebase.
- **Code Reuse**: Architectural changes MUST prioritize adapting existing functional modules (`ApiClient`, `SessionStorage`, `Result<T>`, `AppConfig`, `ScanResultDialog`, `state_views.dart`) rather than introducing redundant frameworks or rewriting tested components.
- External dependencies MUST be kept minimal and justified; adding dependencies (e.g., location plugins) requires strict necessity evaluation.
- The backend API base URL MUST remain configurable (via compile-time flags, environment settings, and runtime debug dialog) so developers can easily target local Go backend instances (`10.0.2.2`, LAN IP) or remote staging servers without recompilation.
- **Rationale**: Accelerates Sprint 1 delivery, avoids technical debt, and preserves battle-tested components already validated in the repository.

### V. Mobile Quality Gates, Static Analysis & Incremental Verification
Code quality and runtime reliability MUST be verified prior to integrating changes into main branches.
- The codebase MUST pass `flutter analyze` with ZERO errors and ZERO fatal warnings before any PR is merged.
- Critical domain logic—including DTO serialization/deserialization, authentication transitions, GPS permission states, and error-handling mappings—SHOULD be covered by automated unit/widget tests.
- UI views MUST explicitly handle four fundamental asynchronous states: Loading (spinner/skeleton), Content (data ready), Empty (no sessions or no attendance records), and Error (network offline, server error with retry option).
- Verification MUST be validated on an Android emulator (API level 26+ / Android 8.0+) or physical device before marking a user story as "Done".
- **Rationale**: Ensures the mobile app remains stable, responsive, and resilient during agile iterations.

## Mobile Security, Privacy & GPS Governance Constraints

The mobile client enforces the following device and transport constraints:
- **Transport Security**: All communication with the external Go backend SHOULD use HTTPS in production and staging environments. Local HTTP loopback exceptions MUST be restricted to debug builds.
- **Ephemeral Coordinate Lifecycle**: Location readings are transient in-memory objects passed directly to the attendance endpoint payload and immediately discarded; they MUST NEVER be cached in SQLite, Hive, SharedPreferences, or file logs.
- **Hardware Access**: Camera hardware is accessed solely during active scanning flows; location hardware is accessed solely at the moment of scan submission. Explicit fallback guidance MUST be provided when permissions are denied.
- **Zero Local Secrets**: API private keys, administrative credentials, or database secrets MUST NEVER be embedded in the Flutter application bundle.

## EDUCCA Domain & User Role Governance

The mobile client respects the following boundary rules for Sprint 1:
- **Promotor Ambiental (Mobile Primary)**: Allowed to register, log in, view scheduled workshops/sessions, scan session QR with single-point GPS verification, and view personal attendance history.
- **Capacitador Ambiental (Web Primary)**: Generates and projects the ephemeral QR for active sessions. The mobile client reads this token (HU-03 dependency) but DOES NOT generate or manage session QR codes.
- **Coordinador (Web Primary)**: Registers municipal venues and schedules environmental workshops. The mobile client consumes session schedules and venue metadata (HU-02 dependency) but DOES NOT provide administrative CRUD views.

## Governance

This Constitution governs all mobile engineering activities within this repository.
- **Supremacy**: Architectural, security, and quality guidelines outlined herein take precedence over ad-hoc conventions.
- **Amendment Procedure**: Amendments require discussion and consensus among the mobile developer, Go backend developer, and Product Owner, updating this file via a documented Pull Request.
- **Versioning Policy**:
  - **MAJOR** version bumps (e.g., 2.0.0 -> 3.0.0) indicate fundamental scope redefinitions (such as repository decoupling, major domain transitions, or principle removals/redefinitions).
  - **MINOR** version bumps (e.g., 3.1.0) indicate new principles, added capabilities, or expanded standards.
  - **PATCH** version bumps (e.g., 3.0.1) indicate wording refinements, typo corrections, or non-semantic clarifications.
- **Compliance Review**: Every Spec Kit specification, implementation plan, and PR MUST explicitly verify compliance with this Constitution.

**Version**: 3.0.0 | **Ratified**: 2026-11-17 | **Last Amended**: 2026-11-17
