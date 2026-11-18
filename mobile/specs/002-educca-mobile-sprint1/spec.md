# Feature Specification: Adaptación Móvil EDUCCA Cusco — Sprint 1

**Feature Branch**: `002-educca-mobile-sprint1`  
**Created**: 2026-11-17  
**Status**: Ready for Planning  
**Target Platform**: Flutter / Android (API 26+ / Android 8.0+)  
**Repository Type**: Brownfield (Adaptación sobre código existente en `lib/`)  
**Input**: Adaptar incrementalmente el MVP móvil existente de capacitación al Sprint 1 del Programa Municipal EDUCCA (Gerencia de Medio Ambiente y Servicios Públicos de Cusco), gobernado por las historias de usuario de Jira HU-01, HU-04 y el requisito no funcional RNF-01, reconociendo dependencias externas con HU-02 y HU-03.

---

## Clarifications

### Session 2026-11-17
- Q: ¿Cómo debe gestionar el formulario de registro móvil la categoría «Escolar» para restringir el autorregistro de menores sin bloquear a los promotores escolares mayores de edad? → A: Confirmación de mayoría de edad condicional (Opción A): Si el usuario selecciona la categoría «Escolar», la interfaz despliega una casilla o selector para declarar si es mayor de 18 años. Si declara ser menor de edad (< 18 años), el formulario bloquea el botón de envío y presenta un mensaje pedagógico orientativo indicando que el registro de promotores escolares menores de edad es gestionado directamente por su institución educativa o el coordinador del programa, en resguardo de la LPDP y a la espera del protocolo oficial del Product Owner. Si declara ser mayor de edad (≥ 18 años), se habilita el envío normal con consentimiento informado.
- Q: ¿Qué política de tiempo de espera y umbral de precisión GPS debe aplicar la aplicación móvil durante la captura puntual antes de enviar la asistencia o solicitar un reintento? → A: Timeout de 10 segundos y filtro de 50 metros (Opción A): La aplicación otorga un tiempo de espera máximo de 10 segundos para fijar coordenadas satelitales. Si la lectura obtenida reporta un margen de imprecisión mayor a 50 metros (`accuracyMeters > 50 m`), la app no transmite datos degradados, presenta el estado «Precisión insuficiente» y solicita reintentar en un área despejada. Si la lectura es ≤ 50 metros dentro del tiempo límite, se remite de inmediato al backend Go para la validación definitiva del radio de 80 metros.

---

## 1. Contexto de Adaptación Brownfield

Esta especificación formaliza la adaptación del cliente móvil Flutter sin reconstruir la aplicación desde cero. Establece una correspondencia directa entre los requisitos vigentes del Sprint 1 y el código previamente implementado.

### 1.1 Matriz de Funcionalidades (Existente vs Por Modificar vs Nuevo)

| Componente / Funcionalidad | Estado Brownfield | Trazabilidad Jira / EDUCCA | Acción Requerida |
|---|---|---|---|
| Cliente HTTP centralizado (`ApiClient`) y manejo de errores (`Result<T>`) | **Existente (Reutilizable)** | Base técnica transversal | Conservar. Añadir cabeceras y soporte a los contratos acordados con el backend en Go. |
| Almacenamiento seguro (`SessionStorage` / Keystore) | **Existente (Reutilizable)** | RNF-01 | Conservar. Mantiene almacenamiento encriptado de tokens JWT. |
| Configuración de host en caliente (`AppConfig`, `ServerConfigDialog`) | **Existente (Reutilizable)** | Base técnica transversal | Conservar exclusivo para entornos debug/pruebas locales en LAN/emulador. |
| Estados de vista asíncronos (`LoadingView`, `EmptyStateView`, `ErrorRetryView`) | **Existente (Reutilizable)** | Principio V Constitución | Conservar para todas las cargas remotas. |
| Formulario de Inicio de Sesión (`LoginScreen`, `AuthProvider`) | **Por Modificar** | HU-01 (RF-01) | Conservar campos y validaciones de login; agregar enlace de navegación hacia «Crear cuenta». |
| Modelo de Usuario (`StudentUser`) | **Por Modificar** | HU-01 (RF-01) | Adaptar a `PromoterUser` con rol `PROMOTOR` y categorías `escolar`, `juvenil`, `comunitario`, preservando compatibilidad retroactiva. |
| Formulario de Registro de Promotor Ambiental | **NUEVO** | HU-01 (RF-01) / RNF-01 | Crear interfaz de registro con nombre completo, correo, contraseña, confirmación, categoría de promotor y control condicional para escolares. |
| Consentimiento Informado y Aviso de Privacidad | **NUEVO** | RNF-01 / HU-01 | Diálogo/cláusula modal interactiva con aceptación obligatoria antes del registro o marcado. |
| Visor de Cámara QR (`QrScannerScreen`, `MobileScanner`) | **Por Modificar** | HU-04 (RF-06) | Conservar lógica de cámara y filtro anti-ráfagas; vincular la captura de geolocalización puntual al confirmar escaneo. |
| Captura Puntual de Geolocalización (GPS) | **NUEVO** | HU-04 (RF-06) / RNF-01 | Obtener coordenadas instantáneas (`latitude`, `longitude`, `accuracyMeters`, `capturedAt`) con timeout de 10 s y filtro de 50 m. |
| Proveedor de Asistencia (`AttendanceProvider`, `attendance_models.dart`) | **Por Modificar** | HU-04 (RF-06) | Extender payload para incluir ubicación puntual y token QR hacia el backend Go. |
| Retroalimentación Modal (`ScanResultDialog`) | **Por Modificar** | HU-04 (RF-06) | Añadir estados visuales para fuera de radio (`OUT_OF_RANGE` > 80 m), GPS inactivo, permiso denegado y precisión insuficiente (`LOCATION_INACCURATE` > 50 m). |
| Consulta de Talleres/Sesiones (`CoursesScreen`, `SessionDetailScreen`) | **Existente (Conservado)** | HU-02 (Dependencia) | Conservar como contexto visual del promotor. Reetiquetar términos académicos a talleres ambientales EDUCCA. |
| Historial de Asistencias (`AttendanceHistoryScreen`) | **Existente (Conservado)** | HU-06 (Backlog futuro) | Conservar como vista complementaria; no marcar como concluida en Sprint 1. |

---

## 2. User Scenarios & Testing *(mandatory)*

### User Story 1 — HU-01 (RF-01): Registro y Autenticación del Promotor Ambiental (Priority: P1)

Como promotor ambiental de Cusco (escolar, juvenil o comunitario), quiero registrar mi cuenta en la aplicación móvil con mis datos y consentimiento informado, e iniciar sesión de forma segura, para participar en los talleres y registrar mi asistencia a las actividades del programa EDUCCA.

**Why this priority**: Es la puerta de entrada obligatoria al sistema. Sin una identidad digital autenticada con token JWT seguro, el promotor no puede remitir asistencias válidas ni acceder a las sesiones.

**Independent Test**: Puede probarse de manera aislada completando el formulario de registro con datos válidos y aceptación de consentimiento para verificar la creación exitosa; validando que credenciales incorrectas o incompletas muestren advertencias específicas sin filtrar si el usuario existe; y comprobando que al iniciar sesión se guarde el JWT de forma encriptada y se navegue a la pantalla principal.

**Acceptance Scenarios**:

1. **AC-01-1 (Registro Exitoso de Promotor Adulto):**  
   **Given** un promotor comunitario o juvenil no registrado en la pantalla de registro,  
   **When** ingresa nombre completo, correo electrónico válido, contraseña que coincide con su confirmación, selecciona su categoría (`juvenil` o `comunitario`) y marca la casilla de aceptación obligatoria del aviso de privacidad y consentimiento informado,  
   **Then** la aplicación envía los datos al servidor, informa el éxito del registro y permite iniciar sesión inmediatamente con las credenciales creadas.

2. **AC-01-2 (Intento de Registro sin Consentimiento):**  
   **Given** un promotor llenando el formulario de registro con campos válidos,  
   **When** intenta enviar el formulario sin haber aceptado el aviso de privacidad y consentimiento informado,  
   **Then** la aplicación bloquea el envío, resalta el requisito de consentimiento y no transmite ninguna petición a la red.

3. **AC-01-3 (Validación de Formulario de Registro):**  
   **Given** un usuario en el formulario de registro,  
   **When** deja campos vacíos, ingresa un correo con formato inválido o escribe contraseñas que no coinciden,  
   **Then** la interfaz muestra mensajes de error contextuales debajo de cada campo antes de intentar cualquier llamada HTTP.

4. **AC-01-4 (Gestión Condicional de Promotor Escolar por Mayoría de Edad):**  
   **Given** un postulante que selecciona la categoría `escolar` en el registro,  
   **When** el formulario despliega la consulta de mayoría de edad:
     * Si el usuario marca que es menor de edad (< 18 años), **Then** el formulario bloquea el botón de envío y despliega un mensaje orientativo informando que el registro de escolares menores de edad se realiza directamente a través de su colegio o coordinador educativo.
     * Si el usuario declara ser mayor de edad (≥ 18 años) y acepta el consentimiento informado, **Then** se habilita el botón de envío y se procesa el registro normalmente hacia el backend.

5. **AC-01-5 (Inicio de Sesión Válido):**  
   **Given** un promotor registrado con credenciales vigentes en la pantalla de login,  
   **When** ingresa su correo y contraseña y pulsa «Iniciar Sesión»,  
   **Then** la aplicación valida la respuesta del servidor, persiste el token JWT en almacenamiento seguro (Keystore/EncryptedSharedPreferences), actualiza el perfil en memoria y redirige a la vista principal.

6. **AC-01-6 (Credenciales Incorrectas):**  
   **Given** un usuario en la pantalla de login,  
   **When** ingresa una contraseña incorrecta o un correo no registrado,  
   **Then** la aplicación presenta un mensaje neutral de «Credenciales inválidas. Verifica tu correo y contraseña» sin revelar si la cuenta existe o no.

7. **AC-01-7 (Cierre de Sesión Seguro):**  
   **Given** un promotor con sesión activa,  
   **When** pulsa la acción de «Cerrar Sesión» y confirma en el diálogo modal,  
   **Then** la aplicación purga el token JWT y datos de sesión del almacenamiento seguro y redirige al inicio de sesión impidiendo retroceder a pantallas privadas.

8. **AC-01-8 (Expiración de Sesión — HTTP 401):**  
   **Given** una sesión local cuyo token ha caducado en el backend,  
   **When** la app recibe una respuesta HTTP 401 en cualquier petición protegida,  
   **Then** se eliminan las credenciales locales de inmediato y se devuelve al usuario al login con un mensaje explicativo de sesión expirada.

---

### User Story 2 — HU-04 (RF-06): Escaneo de QR con Validación Geográfica en Sede (Priority: P1)

Como promotor ambiental presencial en una sede comunal o educativa de Cusco, quiero escanear con la cámara del teléfono el código QR proyectado por el capacitador capturando mi ubicación geográfica en ese único instante, para certificar mi asistencia presencial dentro de la tolerancia de 80 metros establecida por el programa EDUCCA.

**Why this priority**: Es el núcleo operativo del programa EDUCCA para asegurar que las asistencias correspondan a actividades efectivas en el territorio y prevenir registros remotos o fraudulentos.

**Independent Test**: Puede probarse accediendo al escáner de cámara, enfocando un QR de sesión activo simulando coordenadas dentro de los 80 m de la sede oficial para verificar la confirmación de asistencia; y probando con coordenadas a más de 80 m para comprobar el rechazo por distancia excedida, verificando que la coordenada no quede persistida en disco.

**Acceptance Scenarios**:

1. **AC-04-1 (Marcado Exitoso Dentro del Radio de 80 m):**  
   **Given** un promotor autenticado presente en la sede de la sesión,  
   **When** enfoca el código QR de sesión válido, la aplicación obtiene una lectura GPS con precisión ≤ 50 m en menos de 10 segundos y el backend comprueba que la distancia horizontal a la sede oficial es ≤ 80 metros y el usuario está habilitado,  
   **Then** la aplicación presenta el diálogo de confirmación con distintivo afirmativo («¡Asistencia Registrada!»), indicando el título del taller, sede y hora de registro.

2. **AC-04-2 (Rechazo por Distancia Excedida > 80 m):**  
   **Given** un promotor autenticado que escanea un QR válido con GPS de buena precisión pero cuya posición calculada por el backend supera los 80 metros de la sede registrada,  
   **When** el backend rechaza la solicitud por fuera de geocerca (`OUT_OF_RANGE`),  
   **Then** la aplicación presenta una advertencia clara («Fuera del área de asistencia»), indicando que debe encontrarse en la sede autorizada para registrar su participación, permitiendo reintentar.

3. **AC-04-3 (Solicitud Explicativa Previa de Permisos GPS):**  
   **Given** un promotor que pulsa la acción de escanear por primera vez,  
   **When** se requiere el acceso al sensor GPS del dispositivo,  
   **Then** la app despliega un mensaje explicativo contextual indicando que la ubicación se usará únicamente en ese instante para constatar su presencia en la sede y no se realizará rastreo continuo, antes de invocar el diálogo del sistema operativo.

4. **AC-04-4 (Permiso GPS Denegado):**  
   **Given** que el usuario rechaza los permisos de ubicación en el diálogo del sistema,  
   **When** intenta escanear o registrar asistencia,  
   **Then** la aplicación no inventa coordenadas ficticias, detiene el proceso y muestra una vista explicativa orientando a habilitar la ubicación en ajustes para poder registrar asistencia.

5. **AC-04-5 (Sensor GPS Desactivado en el Dispositivo):**  
   **Given** que los servicios de ubicación del teléfono se encuentran apagados,  
   **When** se procede al marcado,  
   **Then** la aplicación notifica al usuario que debe encender el GPS de su dispositivo para poder calcular su posición antes de reintentar.

6. **AC-04-6 (Precisión Insuficiente o Timeout de Adquisición GPS):**  
   **Given** una captura de ubicación en curso:
     * Si transcurren 10 segundos sin fijar satélites o la lectura obtenida reporta un margen de error mayor a 50 metros (`accuracyMeters > 50 m`),  
     **When** se detecta la condición,  
     **Then** la aplicación interrumpe el envío, muestra el aviso «Precisión de ubicación insuficiente» y sugiere al usuario acercarse a una zona despejada para reintentar el escaneo.

7. **AC-04-7 (Código QR Vencido o Rotado):**  
   **Given** un promotor que enfoca un código QR cuya vigencia temporal ha concluido en el backend (emitido por HU-03),  
   **When** se procesa la validación,  
   **Then** la aplicación muestra un aviso específico de «Código QR expirado» e invita a solicitar al capacitador el código actualizado en pantalla.

8. **AC-04-8 (Asistencia Ya Registrada Previamente — Idempotencia):**  
   **Given** un promotor que ya tiene una asistencia confirmada para la sesión actual,  
   **When** escanea nuevamente el código QR (por error o reintento),  
   **Then** el servidor identifica la duplicidad y la app muestra el aviso «Asistencia ya registrada», conservando el registro inicial sin duplicaciones.

9. **AC-04-9 (Sesión Concluida o No Inscrito):**  
   **Given** un código QR perteneciente a una sesión cerrada o a un taller donde el promotor no se encuentra registrado en el backend,  
   **When** se remite la solicitud,  
   **Then** la app presenta la causa específica informada por el servidor («Sesión concluida» o «No estás inscrito en esta actividad»).

---

### User Story 3 — RNF-01: Protección de Datos, Privacidad y Geolocalización Efímera (Priority: P1)

Como promotor ambiental y ciudadano de Cusco, quiero que la aplicación móvil proteja mis datos personales y coordenadas geográficas, de modo que nunca se rastree mi ubicación en segundo plano ni se almacenen registros innecesarios de mis trayectos en el dispositivo.

**Why this priority**: Cumplimiento ético y legal estricto de la Ley de Protección de Datos Personales N.° 29733 (Perú), evitando cualquier invasión de la privacidad ciudadana en una iniciativa municipal de voluntariado ambiental.

**Independent Test**: Puede probarse auditando el ciclo de vida de la aplicación para certificar que ningún servicio de localización permanezca activo al salir del visor de marcado; verificando que la base de datos o almacenamiento local no guarde coordenadas; y comprobando que los logs de consola de la app no impriman contraseñas, tokens JWT ni coordenadas geográficas.

**Acceptance Scenarios**:

1. **AC-RNF-1 (Geolocalización Únicamente en el Instante del Marcado):**  
   **Given** un usuario navegando por la lista de talleres, el login o su historial,  
   **When** utiliza la aplicación fuera del momento del escaneo,  
   **Then** el icono de GPS del sistema operativo permanece inactivo y no se ejecuta ningún listener pasivo (`watchPosition` o servicios en background).

2. **AC-RNF-2 (Cero Persistencia Local de Coordenadas):**  
   **Given** que se completó un intento de marcado presencial (exitoso o fallido),  
   **When** finaliza la comunicación con el servidor,  
   **Then** los valores de `latitude`, `longitude` y `accuracyMeters` se descartan de la memoria de trabajo y no se graban en `SharedPreferences`, `flutter_secure_storage` ni archivos locales.

3. **AC-RNF-3 (Minimización y Cero Fuga en Logs):**  
   **Given** la ejecución de la aplicación en cualquier escenario de red o error,  
   **When** se generan salidas de diagnóstico,  
   **Then** nunca se imprimen contraseñas en texto plano, tokens JWT completos ni coordenadas de ubicación en consolas o registros de depuración accesibles.

---

### Edge Cases

- **Pérdida de conectividad durante el envío del escaneo:** Si el dispositivo pierde señal tras capturar el QR y GPS, la aplicación informa «Sin conexión al servidor. Verifica tu acceso a internet» y ofrece un botón de reintento sin almacenar una asistencia simulada como si fuese real.
- **Entorno de pruebas o emulador sin hardware GPS/Cámara (Modo Demostración):** Para facilitar pruebas del equipo sin conexión satelital real, la aplicación incorpora un repositorio simulado bajo debug claramente identificado con la etiqueta visual **«MODO DEMOSTRACIÓN — DATOS SIMULADOS»**, que devuelve respuestas de prueba sin contactar al servidor ni guardar datos personales reales.
- **Doble escaneo instantáneo (pantalla mantenida frente al QR):** La aplicación congela inmediatamente el flujo de escaneo tras la primera detección válida hasta que el usuario cierre el diálogo de respuesta, impidiendo el envío concurrente de peticiones.
- **Intento de elevación de privilegios desde el registro:** El formulario de registro móvil solo permite el alta con rol de Promotor; cualquier intento de inyectar roles administrativos (`COORDINADOR`, `CAPACITADOR`) es ignorado localmente y rechazado por el backend Go.

---

## 3. Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: La aplicación DEBE ofrecer una interfaz de registro que solicite nombre completo, correo electrónico, contraseña, confirmación de contraseña y selección de categoría de promotor (`escolar`, `juvenil`, `comunitario`).
- **FR-002**: La aplicación DEBE validar localmente que las contraseñas coincidan, cumplan requisitos mínimos de presencia y que el correo tenga formato sintáctico válido antes del envío.
- **FR-003**: La aplicación DEBE desplegar una cláusula obligatoria de consentimiento informado y aviso de privacidad, requiriendo aceptación activa antes de transmitir la solicitud de registro.
- **FR-004**: Si el usuario selecciona la categoría `escolar`, la aplicación DEBE solicitar una declaración explícita de mayoría de edad (≥ 18 años). Si el usuario declara ser menor de edad (< 18 años), la aplicación DEBE bloquear el envío y mostrar un mensaje orientativo indicando que su registro debe gestionarse a través de su institución educativa o coordinador del programa.
- **FR-005**: La aplicación DEBE permitir el inicio de sesión con correo y contraseña, persistiendo el token JWT devuelto por el backend exclusivamente en almacenamiento seguro encriptado de Android (Keystore / EncryptedSharedPreferences).
- **FR-006**: La aplicación DEBE purgar de forma inmediata los tokens y datos de usuario locales al pulsar «Cerrar Sesión» o al recibir una respuesta HTTP 401 (sesión no autorizada o expirada).
- **FR-007**: La aplicación DEBE incorporar un lector de códigos QR mediante cámara que capture el token efímero de la sesión proyectada por el capacitador.
- **FR-008**: La aplicación DEBE solicitar el permiso de geolocalización al sistema operativo únicamente tras enfocar el código QR o al momento de confirmar el marcado, precedido por un diálogo pedagógico que explique su uso para validar la presencia en sede.
- **FR-009**: La aplicación DEBE capturar la posición puntual con un límite de tiempo de espera de 10 segundos, recopilando `latitude`, `longitude`, `accuracyMeters` y `capturedAt`. Si la precisión obtenida es deficiente (`accuracyMeters > 50 m`), DEBE suspender el envío e indicar al usuario que reintente en una zona despejada.
- **FR-010**: Si la lectura GPS cumple con la precisión requerida (≤ 50 m), la aplicación DEBE transmitir el token del QR y los datos de ubicación puntual en una única petición autenticada hacia el endpoint acordado con el backend en Go.
- **FR-011**: La aplicación NO DEBE calcular internamente la distancia ni dictaminar la validez de la asistencia, delegando en su totalidad la verificación de la geocerca de 80 metros, la vigencia del QR y la inscripción al backend.
- **FR-012**: La aplicación DEBE presentar una interfaz modal diferenciada para cada uno de los siguientes resultados de validación:
  - Asistencia confirmada exitosamente.
  - Asistencia previamente registrada (idempotente).
  - Rechazo por distancia excedida (> 80 metros de la sede oficial).
  - Código QR caducado o vencido.
  - Código QR no reconocido o malformado.
  - Sesión no disponible o cerrada.
  - Promotor no registrado/inscrito en la actividad.
  - Permiso de ubicación denegado por el usuario.
  - Servicios de ubicación (GPS) desactivados en el teléfono.
  - Precisión de ubicación insuficiente (> 50 m) o timeout de adquisición (> 10 s).
  - Error de comunicación o falla de red.
- **FR-013**: La aplicación DEBE mantener un diálogo de configuración de URL base accesible en modo depuración (debug) para enlazar emuladores (`10.0.2.2`) o dispositivos móviles en red LAN local con el servidor en Go.
- **FR-014**: La aplicación DEBE conservar las vistas existentes de consulta de talleres/sesiones e historial de asistencia como contexto informativo del promotor, sin asumir que la funcionalidad HU-06 de autoinscripción esté concluida.

### Non-Functional Requirements (RNF-01 y Técnicos)

- **NFR-001 (Protección de Credenciales)**: Los tokens JWT y credenciales de usuario DEBEN residir exclusivamente en almacenamiento seguro encriptado (`flutter_secure_storage`), prohibiendo su guardado en `SharedPreferences` estándar en texto claro.
- **NFR-002 (Geolocalización Puntual Sin Seguimiento)**: Queda TERMINANTEMENTE PROHIBIDO activar listeners continuos (`watchPosition`), servicios de ubicación en segundo plano (background) o rutinas periódicas de geolocalización. La captura debe ser un disparo único (*single-shot*) por intento de asistencia.
- **NFR-003 (Cero Persistencia de Coordenadas)**: Los datos de latitud, longitud y precisión DEBEN manejarse como variables volátiles en memoria y descartarse inmediatamente tras el envío, sin registrarse en SQLite, archivos locales ni logs de sistema.
- **NFR-004 (Minimización y Privacidad en Logs)**: Las contraseñas, tokens completos y coordenadas geográficas NUNCA DEBEN ser emitidos mediante `print` o `debugPrint` en compilaciones de producción.
- **NFR-005 (Tolerancia a Conectividad)**: Ante caídas de red o demoras del servidor, la aplicación DEBE informar la falla sin colapsar ni asumir asistencias ficticias en modo local.

---

## 4. Key Entities

- **Promotor Ambiental (Usuario)**: Ciudadano registrado en el programa EDUCCA. Atributos: identificador único, nombre completo, correo electrónico, rol (`PROMOTOR`), categoría (`ESCOLAR`, `JUVENIL`, `COMUNITARIO`), confirmación de mayoría de edad (`isAdult`), estado del consentimiento informado (`true`/`false`).
- **Sede EDUCCA**: Lugar físico autorizado en Cusco (colegio, plaza, mercado, local comunal) donde se realiza una capacitación. Atributos: nombre de la sede, coordenadas oficiales de referencia (latitud y longitud persistidas en el backend Go).
- **Taller Ambiental**: Programa temático de educación ambiental (ej. segregación en la fuente, compostaje, biohuertos, prevención de incendios).
- **Sesión de Taller**: Encuentro específico programado para un taller en una sede y horario determinados. Atributos: identificador de sesión, título, fecha, hora de inicio/fin, sede asignada y estado de asistencia (`PROGRAMADA`, `ABIERTA`, `CONCLUIDA`).
- **Token QR de Sesión**: Identificador temporal y dinámico proyectado por el capacitador en pantalla web (HU-03). Es efímero, no contiene datos personales (PII) y rota periódicamente.
- **Lectura Puntual de Ubicación**: Medición efímera capturada por el teléfono al escanear el QR. Atributos: latitud, longitud, precisión en metros (`accuracyMeters` ≤ 50 m) y fecha/hora de captura (`capturedAt`).
- **Registro de Asistencia**: Constancia generada y certificada por el servidor backend cuando el promotor escaneó un QR válido dentro de los 80 metros de la sede. Atributos: identificador de asistencia, identificador de promotor, identificador de sesión y fecha/hora de certificación emitida por el servidor.

---

## 5. Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Un promotor puede completar su formulario de registro con aceptación de consentimiento en menos de 2 minutos en una conexión estándar.
- **SC-002**: El flujo completo de marcado de asistencia (apertura de cámara, lectura de QR, captura puntual de GPS y recepción de respuesta del servidor) se completa en un máximo de 3 toques deliberados desde la pantalla principal, cumpliendo el criterio de usabilidad RNF-03.
- **SC-003**: El 100% de las peticiones de asistencia fuera del radio de 80 metros son rechazadas por el backend e interpretadas adecuadamente por la aplicación con el mensaje de geocerca excedida, sin fallos de interfaz.
- **SC-004**: En el 100% de los casos de salida de pantalla o cierre de la app tras un escaneo, el sensor GPS queda completamente inactivo en el sistema operativo Android sin procesos remanentes en background.
- **SC-005**: La aplicación pasa limpiamente el análisis estático (`flutter analyze` con cero errores) y mantiene el 100% de aprobación de las pruebas de regresión existentes.

---

## 6. Assumptions & External Dependencies

### Suposiciones Provisionales Seguras y Reversibles (Decisiones No Bloqueantes)
1. **Contratos REST y DTOs Adaptables:** Dado que el desarrollador del backend (Dev 1) no ha congelado aún las rutas ni nombres exactos de campos JSON, el cliente móvil implementará un adaptador/repositorio desacoplado con DTOs internos adaptables, preparados para conectarse a endpoints tentativos (`/auth/register`, `/auth/login`, `/attendance/scan`) sin atar la lógica de presentación a una estructura inmutable.
2. **Modo Demostración Desacoplado:** Para permitir la verificación funcional y visual del móvil antes de la disponibilidad final del backend en Go, se proveerá una implementación simulada (`MockEduccaRepository`) activable únicamente en debug con distintivo visual explícito, garantizando que el flujo no bloquee las pruebas de interfaz.
3. **Persistencia Retrocompatible de Usuario:** Para evitar romper sesiones existentes durante pruebas, el modelo de usuario deserializará tanto formatos previos (`StudentUser`) como los nuevos atributos de promotor (`PromoterUser`).

### Dependencias Externas (Fuera del Alcance Móvil)
- **HU-02 (Coordinador Web / Backend Go)**: El backend y la plataforma web son los únicos responsables de crear las sedes, capturar sus coordenadas oficiales de referencia en Cusco y programar los talleres. La app móvil consume estos datos como lectura.
- **HU-03 (Capacitador Web / Backend Go)**: El capacitador genera y proyecta el código QR dinámico desde la aplicación web. El móvil solo actúa como sensor de lectura.
- **Desarrollo del Backend Go + PostgreSQL**: El backend es implementado por otro miembro del equipo. Los contratos de API detallados en `docs/educca/02_CONTRATO_API_PENDIENTE.md` son una guía de trabajo preliminar sujeta a homologación mutua entre desarrolladores.

### Decisiones Abiertas / Pendientes (Seguimiento con Product Owner)
- **D-01 (Política Legal de Menores)**: El Product Owner debe definir en una etapa posterior si se habilitará un flujo digital con firma/consentimiento de tutor legal para promotores escolares menores de edad, manteniendo entretanto la restricción de autorregistro escolar para menores establecida en la aclaración de la sesión actual.
- **D-03 (Formato Definitivo del QR)**: Confirmar con el capacitador/backend si el QR transmitirá una cadena simple opaca o un token JWT firmado.
