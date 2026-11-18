# Especificación de adaptación — EDUCCA Cusco / Sprint 1 / Flutter Android

**Estado:** propuesta técnica derivada del documento del Product Owner, pendiente de validación.  
**Tipo de cambio:** brownfield; modificar aplicación móvil ya implementada, **sin reiniciarla**.  
**Fuente primaria:** informe de equipo `IS1_2026_II_Colque_Magaña_Mendoza_Montalvo_Proyecto_Seguimiento_Capacitaciones.pdf`, pp. 4–9; Jira Sprint 1 (captura compartida).  
**Repositorio destino:** actual proyecto Flutter `sistema-capacitaciones/`.  
**Versión anterior de requisitos:** `specs/001-mobile-training-mvp/` y `ESPECIFICACIONES_MAESTRAS_E1_E2_CAPACITACIONES.md` (históricas; NO prevalecen sobre PO/Jira).

## A. Objetivo de esta especificación

Adecuar la app Flutter del MVP genérico a una app móvil para **promotores ambientales del Programa Municipal EDUCCA** que permita registrarse/iniciar sesión y marcar asistencia presencial escaneando un QR de sesión y capturando **la ubicación únicamente en ese instante**. El servidor valida sesión, QR, inscripción y pertenencia al radio máximo de **80 m** de la sede, y responde si la asistencia fue aceptada o rechazada.

### A.1 Límites de autoridad de requisitos

**Obligatorio por fuente del equipo:** rol/categorías de promotores, registro e inicio, QR de sesión, validación GPS con tolerancia de 80 m, consentimiento informado, geolocalización solo en el marcado, Android 8.0+, diseño comprensible.  
**Propuestas para implementación:** diseño de pantallas, nombres de propiedades JSON, manejo de estados, tolerancia a precisión GPS, JWT, expiración de token QR y mock de pruebas. Deben confirmarse con backend/PO; **no presentar como exigencias del PDF**.

### A.2 Product Backlog del Sprint 1 (sin alterar IDs ni puntos)

| Jira | RF | Historia original resumida | SP | Responsabilidad móvil |
|---|---|---|---:|---|
| HU-01 | RF-01 | Como usuario, quiero registrarme e iniciar sesión según mi rol | 3 | Crear cuenta de promotor, login y sesión; roles de coordinador/capacitador administrados según backend |
| HU-02 | RF-02 | Como coordinador, quiero registrar sedes y programar talleres ambientales | 5 | Consumir sede, horario y sesión; no añadir mantenimiento administrativo al móvil |
| HU-03 | RF-05 | Como capacitador, quiero generar QR al iniciar sesión presencial | 5 | Leer y transmitir token compatible con QR de backend; no generar el QR |
| HU-04 | RF-06 | Como promotor, quiero escanear QR validando ubicación GPS | 8 | Escaneo, ubicación puntual, envío autenticado y resultado |
| RNF-01 | RNF-01 | Protección de credenciales, consentimiento y GPS solo al escanear | 5 | Consentimiento, protección de tokens, permisos contextuales, sin tracking |

**Cuidado con los números:** el PO denomina `HU-04` a **QR + GPS**, mientras el MVP previo usaba otros IDs para otras funciones. Mantener una **matriz de correspondencias**, no renumerar Jira.

## B. Usuarios, vocabulario y contexto EDUCCA

- **Coordinador de gerencia:** gestiona sedes y programación **web**, no usuario objetivo de pantallas móviles en Sprint 1.
- **Capacitador ambiental:** imparte talleres y presenta QR **web**, no un panel móvil de creación de QR en Sprint 1.
- **Promotor ambiental:** usuario principal de Flutter; categoría `escolar`, `juvenil` o `comunitario`; se registra o inicia sesión y marca asistencia.
- **Sede:** institución educativa, mercado, local comunal u otro punto de intervención en Cusco.
- **Taller:** actividad de educación ambiental; temáticas mencionadas por PO: segregación en la fuente, compostaje, biohuertos urbanos, ecoeficiencia, prevención de incendios forestales.
- **Sesión:** encuentro específico de un taller en una sede y horario.
- **Asistencia:** un marcado confirmado por servidor para usuario y sesión.

## C. Diferencias sobre el Flutter existente

| Elemento del código actual (según informe de Antigravity, verificar repositorio) | Acción | Justificación / riesgo |
|---|---|---|
| `lib/core/api_client.dart`, `session_storage.dart`, `result.dart` | **Reutilizar**; actualizar contratos cuando se acuerden | HTTP, token y fallos ya resueltos |
| `lib/providers/auth_provider.dart`, `login_screen.dart` | **Modificar** y agregar registro | HU-01 incluye registro, no solo login |
| `lib/models/student_user.dart` | **Adaptar sin romper serialización existente** | Promotor y categoría; compatibilidad con API pendiente |
| `courses_screen.dart`, `course.dart`, `course_session.dart` | **Reetiquetar** y adaptar datos de taller/sede | El Sprint 1 no obliga autoinscripción ni catálogo abierto |
| `lib/screens/qr_scanner_screen.dart` | **Extender** para ubicación puntual | HU-04: QR + GPS real |
| `lib/providers/attendance_provider.dart`, `attendance_models.dart` | **Modificar** payload, estado y resultados | Backend valida ubicación y sesión |
| `server_config_dialog.dart`, `app_config.dart` | **Conservar** en debug | Útil para IP de compañero/emulador; no exponer producción |
| `attendance_history_screen.dart` | **Conservar, etiquetar como complementaria** | Parte de HU-06 en backlog, no declarar terminada |
| Tests unitarios y de widgets actuales | **Conservar y extender** | Evitar regresiones |

### C.1 Exclusiones claras

No crear React, NestJS, base de datos ni APIs de servidor en este repo; no agregar pantallas administrativas ni QR para capacitador; no crear integración blockchain/certificados ni encuestas en Sprint 1; no inventar persistencia de asistencia local como sustituto del servidor.

## D. Requisitos móviles verificables

### M-01 — Registro de promotor (HU-01 / RF-01 / RNF-01)

1. La pantalla de login ofrece «Crear cuenta».
2. El formulario registra los campos que **apruebe el backend**. Como propuesta UX: nombre completo, correo, contraseña, confirmación y categoría de promotor (escolar, juvenil, comunitario).
3. Valida localmente campos obligatorios, formato de correo, coincidencia de contraseñas; los detalles de política de contraseña dependen del contrato de backend.
4. Antes del envío, muestra aviso de privacidad y consentimiento informado con aceptación explícita, texto legal **por validar con PO**.
5. No dar por válido el consentimiento de un menor solo con un checkbox; definir tratamiento de menores con el PO/asesoría legal. Puede bloquearse el registro escolar hasta definir el flujo necesario.
6. Distingue registro exitoso, correo existente, validación rechazada, red caída y error inesperado.
7. No fija administradores ni capacitadores como roles elegibles libremente en el registro público.

**Aceptación:** registro de promotor autorizado por backend, sin permitir elevación de privilegios desde el cliente.

### M-02 — Login y sesión (HU-01 / RF-01)

1. Correo y contraseña; validación local sin revelar si existe una cuenta antes de la respuesta del backend.
2. Guarda credenciales/tokens **solo** en almacenamiento seguro apropiado; no registrar passwords ni tokens en logs.
3. Ante 401/expiración, purga credenciales locales y devuelve al login.
4. Cierre de sesión elimina credenciales guardadas; confirma retorno a acceso.
5. Si backend identifica perfil no habilitado para la experiencia móvil, informar sin exponer funcionalidades ajenas.
6. Ajuste de URL base solo habilitado para pruebas/debug; HTTPS para despliegue externo.

### M-03 — Inicio y contexto de la sesión (HU-02 / HU-03 como dependencias)

1. Identifica en cabecera «EDUCCA Cusco» y muestra nombre/categoría del promotor **solo si backend provee esos datos**.
2. Botón principal «Escanear QR de asistencia»; si existe un curso o sesión disponible, puede ofrecer botón contextual.
3. Muestra información de sesión/sede disponible por API; si no hay datos no inventa sedes o sesiones reales.
4. Catálogo abierto y autoinscripción no son condición para Sprint 1 (HU-06 de prioridad media).

### M-04 — Escaneo QR y permisos (HU-04 / RNF-01)

1. Solicitar cámara únicamente al entrar al escáner y ubicación cuando el usuario confirma el marcado después de leer QR (o en el momento del escaneo, sin captura previa ni tracking continuo).
2. Mostrar explicación de uso de GPS: verificar asistencia por sede y distancia, sin rastreo en segundo plano.
3. Leer token o URL autorizada por contrato; no confiar en `session_id` arbitrario del QR; no exponer PII en QR ni logs.
4. Prevenir múltiples envíos simultáneos de la misma lectura; permitir nuevo intento únicamente después de resultado.
5. Obtener `latitude`, `longitude`, `accuracyMeters` y `capturedAt` cuando el sistema operativo los ofrece; **no guardar historial local de coordenadas**.
6. Enviar QR + posición autenticados al servidor. El cliente nunca decide por sí solo asistencia válida ni distancia final.
7. Resolver los estados: permiso denegado/permanente; GPS apagado; precisión insuficiente; QR inválido, vencido o duplicado; fuera de 80 m; sesión cerrada; sin inscripción; conexión fallida; aceptado.
8. Si no hay GPS o servidor, no registrar una asistencia ficticia como real. Modo mock exclusivo debug (si se usa) debe mostrar claramente «Datos de demostración».
9. La entrada manual de token existente es herramienta de prueba/debug, no alternativa para eludir verificación geográfica.
10. La información GPS se recoge solo al intento de asistencia; prohibido iniciar `watchPosition`, background tracking o servicios periódicos.

### M-05 — Resultado y experiencia móvil (HU-04 / RNF-03)

1. Mensajes breves y legibles; éxito solo tras confirmación de servidor.
2. Permitir regresar al inicio y consultar asistencias (historial opcional, HU-06 posterior).
3. Indicar claramente cuando el rechazo proviene del servidor y cómo reintentar una comprobación de ubicación.
4. Flujo principal de asistencia en máximo 3 acciones deliberadas, conforme al RNF-03 del PO, sin contar permisos del SO ni pantalla de espera.

## E. Reglas de negocio y privacidad

| ID | Regla | Origen |
|---|---|---|
| E-RN-01 | Radio máximo/tolerancia para asistencia presencial: **80 m de la sede** | PDF del PO |
| E-RN-02 | GPS solo en momento de lectura/marcado QR; **no tracking en background** | PDF del PO |
| E-RN-03 | Registro e inicio de sesión por roles; promotores escolar/juvenil/comunitario | PDF del PO |
| E-RN-04 | Cláusula de consentimiento explícito en registro | PDF del PO |
| E-RN-05 | Contraseñas protegidas: el backend utiliza hash de contraseña con sal y algoritmo adecuado, **no cifrado reversible**; la app no las persiste | Aclaración técnica de seguridad, validar con backend |
| E-RN-06 | Veredicto de QR + distancia + inscripción lo determina el backend | Propuesta de seguridad (recomendada) |
| E-RN-07 | QR sin PII; duración exacta del token todavía **pendiente de confirmar** | Propuesta + especificación previa |
| E-RN-08 | Una sola asistencia por promotor/sesión (idempotencia), su implementación corresponde al servidor | Propuesta + especificación previa |
| E-RN-09 | Si precisión del GPS es demasiado baja, mostrar reintento; **umbral exacto no definido por PO** | Propuesta por acordar |
| E-RN-10 | Fechas/horarios emitidos por API, presentados en zona horaria del usuario | Propuesta por acordar |

La ubicación enviada para el marcado es dato personal potencialmente sensible. Minimizar uso, limitar destinatarios, aplicar HTTPS cuando corresponda, no enviarla a telemetría innecesaria y definir retención en el backend con el equipo.

## F. Escenarios de aceptación (Given / When / Then)

**AC-01 · Registro exitoso:** Dado un promotor adulto con datos válidos y consentimiento aceptado, cuando envía el formulario y el backend aprueba, entonces la app confirma la creación de cuenta y permite iniciar sesión o accede según contrato.

**AC-02 · Registro sin consentimiento:** Dado un registro incompleto sin aceptación de términos, cuando intenta enviarlo, entonces no se envía la solicitud y aparece una explicación clara.

**AC-03 · Login:** Dadas credenciales válidas de promotor, cuando ingresa, entonces la app conserva la sesión de forma segura y muestra acceso a marcado QR.

**AC-04 · QR válido dentro de radio:** Dado un promotor autenticado, inscrito en la sesión abierta, con QR válido y coordenadas cuya distancia a sede es **≤80 m**, cuando marca asistencia, entonces el backend la confirma y la app muestra «Asistencia registrada».

**AC-05 · Distancia excedida:** Dado GPS válido y distancia **>80 m**, cuando se intenta marcar, entonces el servidor rechaza el registro y la app indica «Fuera del área de asistencia».

**AC-06 · GPS denegado:** Dado permiso denegado, cuando intenta marcar, entonces no se confirma asistencia; la app explica cómo habilitar ubicación y permite reintentar.

**AC-07 · Precisión insuficiente:** Dada una lectura de baja precisión según umbral acordado, cuando intenta marcar, entonces se solicita nueva medición o se muestra decisión del backend, sin registrar éxito ficticio.

**AC-08 · QR caducado:** Dado QR vencido, cuando se envía, entonces no hay registro y se invita a solicitar otro QR.

**AC-09 · Duplicado:** Dada asistencia previamente confirmada, cuando vuelve a enviar un QR, entonces el servidor conserva un único registro e informa «Asistencia ya registrada».

**AC-10 · Sesión inválida/cerrada:** Dado QR de sesión cerrada o no autorizada, cuando se envía, entonces se rechaza con mensaje diferenciado.

**AC-11 · Backend caído:** Dada pérdida de conexión, cuando el usuario intenta enviar, entonces se muestra error de red y ninguna confirmación local de asistencia real.

**AC-12 · Privacidad:** Durante login, navegación y consulta de cursos no se accede a GPS; después de intentar marcar, no continúa ningún seguimiento en segundo plano.

**AC-13 · Compatibilidad:** Se prueba en un dispositivo o AVD representativo de Android 8.0+; permisos, login y scanner son utilizables. Probar versiones/SDK reales disponibles antes de declarar cumplimiento universal.

**AC-14 · Regresión:** El cliente HTTP, la URL base de debug, logout, protección de 401 y estados comunes previos siguen funcionando.

## G. Dependencias y decisiones abiertas (NO inventar)

1. **D-01 [BLOQUEANTE INTEGRACIÓN]** Backend del equipo: URL, endpoints, JSON, DTOs, nombres exactos de rol/categoría, política de autenticación.
2. **D-02 [BLOQUEANTE INTEGRACIÓN]** QR emitido por HU-03: formato, validez, vigencia y autenticidad.
3. **D-03 [BLOQUEANTE INTEGRACIÓN]** Sedes HU-02: latitud/longitud autorizadas en servidor; cálculo de distancia de 80 m y precisión GPS aceptable.
4. **D-04 [REQUIERE PO]** Registro de promotores escolares/menores y consentimiento/representante; no improvisar texto legal ni permitir tratamiento no definido.
5. **D-05 [REQUIERE PO]** ¿El alta de capacitadores/coordinadores es exclusivamente administrativa? Recomendación: sí.
6. **D-06 [REQUIERE EQUIPO]** ¿La inscripción es prerequisito de asistencia en Sprint 1? La HU-06 de autoinscripción se planifica después; Sprint 1 puede usar inscripciones precargadas por backend, **sin simular que el usuario se autoinscribió**.
7. **D-07 [PROPUESTA]** Respuestas específicas de GPS impreciso y umbral; no son cifras oficiales.
8. **D-08 [PROPUESTA]** Política de mock para demostración si backend no está listo; separar de producción y evidenciar limitaciones.

## H. Definition of Done por porción móvil

- [ ] Función implementada contra contrato aprobado **o** marcada como demo/mock.
- [ ] Criterios de aceptación verificados, con casos positivos y negativos relevantes.
- [ ] `flutter analyze` sin incidencias; `flutter test` pasa; no rompe pruebas anteriores.
- [ ] Probado en emulador/dispositivo Android para permisos y GPS con ubicación simulada controlada.
- [ ] No se imprime token, password o GPS en logs de aplicación.
- [ ] No se inicia geolocalización continua ni se habilita acceso en segundo plano.
- [ ] Flujos con conectividad intermitente no confirman asistencia falsamente.
- [ ] Revisado código y documentada dependencia real de backend.
- [ ] Si se usa modo demo, visible y desactivado en release.
- [ ] Estado de cada HU de Jira actualizado por responsables; no marcar HU-02 o HU-03 Done por terminar código móvil.

## I. Referencias visuales

Usar `05_PROMPT_FIGMA_MCP.md` como brief UI. El diseño es referencia consultiva. Una decisión de Figma no modifica el backlog del PO.
