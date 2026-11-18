# EDUCCA — Contrato móvil ↔ backend por acordar

**Estado: BORRADOR DE INTEGRACIÓN.** No son rutas oficiales ni confirmación de que los endpoints existan. Deben revisarlo Product Owner, responsable del backend y responsable Flutter **antes de integrar**.

## 1. Principios

- Flutter **no** crea QR de capacitadores, ni genera inscripciones ficticias, ni declara una asistencia válida sin respuesta del servidor.
- Todo inicio de sesión, alta de promotor, consulta de sesiones y marcado de asistencia se acuerda a nivel DTO + semántica de errores.
- La asistencia se valida server-side usando QR, estado de sesión, usuario, inscripción y geocerca de **80 m**. Distancia calculada desde la **sede almacenada por el backend**, no desde una coordenada aportada por el QR ni por Flutter.
- Evitar PII en QR, logs, analytics y mensajes de error. La aplicación envía posición únicamente para el marcado presencial.
- HTTPS en redes externas/producción. En Android debug se permite HTTP local según manifiesto debug existente.

## 2. Tabla de operaciones para acordar

| Operación | Ruta ilustrativa | Cliente Flutter | Propietario que debe confirmar |
|---|---|---|---|
| Registrar promotor | `POST /auth/register` | formulario HU-01 | backend + PO |
| Autenticarse | `POST /auth/login` | login HU-01 | backend |
| Obtener perfil | `GET /auth/me` | inicio/perfil | backend |
| Consultar mis sesiones | `GET /promoter/sessions` | contexto para QR (si existe) | backend |
| Validar asistencia QR+GPS | `POST /attendance/scan` | HU-04 | backend + capacitador web |
| Consultar asistencia | `GET /promoter/attendances` | complementario, no DoD Sprint 1 | backend |

**Importante:** el MVP previo podría usar `/student/attendance/scan` y otros nombres. **No reemplazar a ciegas**: mantener adaptador central e introducir una configuración acordada o migración controlada.

## 3. DTOs ilustrativos (NO congelados)

### 3.1 Registro

```http
POST /auth/register
Content-Type: application/json
```

```json
{
  "fullName": "María Quispe",
  "email": "promotora.demo@example.org",
  "password": "<secreto_no_real>",
  "promoterCategory": "JUVENIL",
  "privacyNoticeVersion": "POR_DEFINIR",
  "privacyConsentAccepted": true
}
```

**Preguntas pendientes:** ¿categoría es un campo o subrol? ¿se exige DNI/entidad? ¿es permitido el registro escolar sin autorización de tutor? ¿se envía o registra evidencia de consentimiento? ¿quién crea coordinadores/capacitadores? No inventar respuestas.

### 3.2 Login

```http
POST /auth/login
Content-Type: application/json
```

```json
{ "email": "promotora.demo@example.org", "password": "<secreto_no_real>" }
```

Ejemplo de respuesta ilustrativa:

```json
{
  "accessToken": "<token_demo>",
  "user": {
    "id": "promoter-demo-01",
    "fullName": "María Quispe",
    "role": "PROMOTOR",
    "promoterCategory": "JUVENIL"
  }
}
```

**Pendiente:** JWT/refresh token, formato de caducidad, expiración, error 401 y nombre real de roles.

### 3.3 Asistencia QR + GPS (contrato crítico)

```http
POST /attendance/scan
Authorization: Bearer <token>
Content-Type: application/json
```

```json
{
  "qrToken": "<token_opaco_recibido_del_qr>",
  "location": {
    "latitude": -13.52,
    "longitude": -71.97,
    "accuracyMeters": 15.3,
    "capturedAt": "2026-11-17T16:00:00Z"
  }
}
```

Coordenadas **sintéticas para documentación**, no reflejan una sede exacta ni usuario. No guardarlas en un mock como registros personales. `capturedAt` proviene del dispositivo como dato indicativo; el servidor usa su propia hora para reglas de validez.

Respuesta ilustrativa aceptada:

```json
{
  "status": "RECORDED",
  "attendanceId": "attendance-demo-01",
  "session": {
    "id": "session-demo-01",
    "title": "Segregación en la fuente",
    "venueName": "Local comunal de demostración"
  },
  "recordedAt": "2026-11-17T16:00:01Z"
}
```

Error semántico ilustrativo:

```json
{
  "code": "OUT_OF_RANGE",
  "message": "No estás dentro del área permitida de asistencia.",
  "retryable": true
}
```

### 3.4 Códigos de resultados a consensuar

| Código sugerido | Semántica | Respuesta móvil |
|---|---|---|
| `RECORDED` | Asistencia confirmada por servidor | «Asistencia registrada» |
| `ALREADY_RECORDED` | Duplicado / idempotencia | «Asistencia ya registrada» |
| `OUT_OF_RANGE` | Distancia desde sede **>80 m** | «Estás fuera del área de asistencia» |
| `QR_EXPIRED` | QR vencido | «Solicita un nuevo QR» |
| `QR_INVALID` | QR inválido o alterado | «Código no válido» |
| `SESSION_CLOSED` | La sesión no está abierta | «La sesión no recibe asistencias» |
| `NOT_ENROLLED` | Usuario no está inscrito | «No figuras inscrito en esta sesión» |
| `LOCATION_REQUIRED` | Sin ubicación | «Activa tu ubicación e inténtalo» |
| `LOCATION_INACCURATE` | Precisión insuficiente | «Acércate a un área abierta y vuelve a intentar» |
| `UNAUTHORIZED` | Token sesión inválido/expirado | Limpiar sesión, mostrar login |
| `NETWORK_ERROR` | Sin red / timeout (cliente) | «Sin conexión. Reintentar» |

HTTP status y cuerpo exacto **pendientes**. No asociar mecánicamente una condición de negocio a HTTP 200 sin acordarlo.

## 4. Acuerdos mínimos del backend para validar en conjunto

- [ ] Forma de QR del capacitador y cómo Flutter obtiene `qrToken`.
- [ ] Vigencia y posible rotación de token QR.
- [ ] Registro y roles: cuáles se crean por app y cuáles exclusivamente por coordinador.
- [ ] Autenticación: rutas, formato de sesión/tokens, logout, respuesta 401.
- [ ] Contrato exacto de ubicación: lat/lon, `accuracyMeters`, política si precisión deficiente.
- [ ] Coordenadas de sede persistidas en servidor y criterio de **80 m** (distancia horizontal; inclusión de límite = 80 m).
- [ ] Inscripción previa para asistir: carga inicial por coordinador vs autoinscripción HU-06 posterior.
- [ ] Idempotencia por promotor + sesión, restricciones de BD y mensaje de duplicado.
- [ ] Manejo de QR expirada y sesión cerrada.
- [ ] Datos de prueba acordados: cuenta demo, sesión abierta, sede, QR válido/vencido, duplicado y caso fuera de radio.
- [ ] URL de backend alcanzable por emulador (`10.0.2.2` si corre en host) y por teléfono físico (IP LAN + firewall + misma red).
- [ ] HTTPS en despliegue y política de retención/acceso a coordenadas conforme al tratamiento declarado.

## 5. Modo de demostración (opcional; no confundir con integración real)

Si aún no hay API funcional, la app puede habilitar `MockEduccaRepository` bajo **debug** con un distintivo visible **«MODO DEMOSTRACIÓN — DATOS SIMULADOS»**. Debe devolver casos predeterminados para pruebas visuales; jamás escribir asistencia real, persistir GPS innecesariamente ni activarse en release. El scanner y permisos deben poder probarse por separado. Una API real debe reemplazar el mock sin modificar pantallas, gracias a un único adaptador/provider.

**Criterio de no aceptación:** una prueba con mock no acredita la historia HU-04 completa ni la integración con la generación real de QR (HU-03).
