# REST API Contract: Asistencia Presencial QR + GPS (Borrador Crítico)

**Estado**: Borrador adaptable para homologación con backend Go + PostgreSQL (Dev 1).  
**Headers Comunes**:
* `Authorization: Bearer <token_jwt>`
* `Content-Type: application/json`
* `Accept: application/json`

---

## 1. Validar Asistencia QR + GPS (HU-04 / RF-06 / RNF-01)

- **Método**: `POST`
- **Ruta preliminar**: `/attendance/scan` (o `/api/v1/attendance/scan`)
- **Autenticación**: Obligatoria (`Bearer <token>`)

### Request Body
```json
{
  "qrToken": "qr_ephemeral_token_xyz987",
  "location": {
    "latitude": -13.52554,
    "longitude": -71.97232,
    "accuracyMeters": 18.5,
    "capturedAt": "2026-11-17T15:30:00.000Z"
  }
}
```

*Validaciones esperadas en el Backend en Go:*
1. **Identidad:** Extraída del JWT autenticado en cabecera.
2. **Token QR (HU-03):** Verifica que el token corresponda a una sesión abierta y no haya expirado en servidor.
3. **Inscripción (HU-02):** Verifica que el promotor esté formalmente asignado/inscrito a la sesión.
4. **Idempotencia:** Verifica si ya existe asistencia previa para evitar duplicados.
5. **Geocerca de 80 m (HU-02 / E-RN-01):** Consulta las coordenadas oficiales de la sede vinculada a la sesión y calcula la distancia geodésica horizontal contra `location.latitude` y `location.longitude`. Si `distancia > 80.0 m` → Rechaza con código `OUT_OF_RANGE`.

---

### Respuestas del Servidor

#### A. 200 / 201 Created — Asistencia Registrada y Validada (≤ 80 m)
```json
{
  "status": "RECORDED",
  "message": "Asistencia registrada correctamente",
  "attendance": {
    "id": "att-educca-501",
    "sessionId": "ses-301",
    "sessionTitle": "Taller: Segregación de Residuos en la Fuente",
    "venueName": "Local Comunal San Pedro",
    "markedAt": "2026-11-17T15:30:01.210Z",
    "status": "CONFIRMED"
  }
}
```

#### B. 400 Bad Request — Fuera de Radio (> 80 m de la sede)
```json
{
  "code": "OUT_OF_RANGE",
  "message": "Estás fuera del área permitida de asistencia para esta sede (radio máximo 80 m)",
  "calculatedDistanceMeters": 142.3,
  "retryable": true
}
```

#### C. 409 Conflict — Asistencia Duplicada
```json
{
  "code": "ALREADY_RECORDED",
  "message": "Tu asistencia ya se encuentra registrada para esta sesión",
  "attendance": {
    "id": "att-educca-501",
    "sessionId": "ses-301",
    "sessionTitle": "Taller: Segregación de Residuos en la Fuente",
    "venueName": "Local Comunal San Pedro",
    "markedAt": "2026-11-17T15:05:00.000Z",
    "status": "CONFIRMED"
  }
}
```

#### D. 410 Gone / 400 Bad Request — Token QR Vencido (HU-03)
```json
{
  "code": "QR_EXPIRED",
  "message": "El código QR ha expirado. Solicita al capacitador que proyecte el código actualizado"
}
```

#### E. 403 Forbidden — Promotor No Inscrito
```json
{
  "code": "NOT_ENROLLED",
  "message": "No figuras formalmente inscrito en este taller ambiental"
}
```

#### F. 400 Bad Request — Sesión Cerrada
```json
{
  "code": "SESSION_CLOSED",
  "message": "El periodo para marcar asistencia en esta sesión ha concluido"
}
```
