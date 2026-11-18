# REST API Contracts: Asistencia y Escaneo QR

**Base URL**: `http://<HOST>:<PORT>/api/v1`  
**Headers comunes**:
- `Authorization: Bearer <token>`
- `Content-Type: application/json`
- `Accept: application/json`

---

## 1. Registrar Asistencia mediante Escaneo de Token QR

- **Método**: `POST`
- **Ruta**: `/student/attendance/scan`
- **Autenticación**: Obligatoria (`Bearer <token>`)

### Request Body
```json
{
  "qrToken": "qr_ephemeral_token_abc123xyz"
}
```

### Respuestas del Servidor

#### A. 200 / 201 Created — Asistencia Registrada Exitosamente
```json
{
  "status": "SUCCESS",
  "message": "Asistencia registrada correctamente",
  "attendance": {
    "id": "att-901",
    "sessionId": "ses-502",
    "sessionTitle": "Sesión 2: Arquitectura del MVP y Control de Asistencia",
    "courseTitle": "Ingeniería de Software I y Métodos Ágiles",
    "markedAt": "2026-11-17T08:15:32.120Z",
    "status": "CONFIRMED"
  }
}
```

#### B. 409 Conflict — Asistencia Duplicada (Ya registrada previamente)
```json
{
  "status": "DUPLICATE",
  "message": "Tu asistencia ya fue registrada previamente para esta sesión",
  "attendance": {
    "id": "att-901",
    "sessionId": "ses-502",
    "sessionTitle": "Sesión 2: Arquitectura del MVP y Control de Asistencia",
    "courseTitle": "Ingeniería de Software I y Métodos Ágiles",
    "markedAt": "2026-11-17T08:05:10.000Z",
    "status": "CONFIRMED"
  }
}
```

#### C. 410 Gone / 400 Bad Request — Código QR Expirado (Caducado)
```json
{
  "status": "EXPIRED",
  "message": "El código QR ha expirado. Por favor, escanea el código actualizado en pantalla"
}
```

#### D. 400 Bad Request — Sesión Cerrada
```json
{
  "status": "CLOSED",
  "message": "El periodo de registro para esta sesión ha concluido"
}
```

#### E. 403 Forbidden — Estudiante No Inscrito
```json
{
  "status": "UNAUTHORIZED",
  "message": "No te encuentras inscrito en la capacitación correspondiente a esta sesión"
}
```

#### F. 404 / 422 Unprocessable Entity — Token QR Inválido o Malformado
```json
{
  "status": "INVALID",
  "message": "El código QR escaneado no es válido para este sistema"
}
```

---

## 2. Consultar Historial de Asistencias del Estudiante

- **Método**: `GET`
- **Ruta**: `/student/attendance/history`
- **Autenticación**: Obligatoria (`Bearer <token>`)

### Response 200 OK
```json
[
  {
    "id": "att-901",
    "sessionId": "ses-502",
    "sessionTitle": "Sesión 2: Arquitectura del MVP y Control de Asistencia",
    "courseTitle": "Ingeniería de Software I y Métodos Ágiles",
    "markedAt": "2026-11-17T08:15:32.120Z",
    "status": "CONFIRMED"
  },
  {
    "id": "att-885",
    "sessionId": "ses-501",
    "sessionTitle": "Sesión 1: Introducción y Product Backlog",
    "courseTitle": "Ingeniería de Software I y Métodos Ágiles",
    "markedAt": "2026-11-15T08:10:05.450Z",
    "status": "CONFIRMED"
  }
]
```

### Response 200 OK (Sin asistencias previas - Estado Vacío)
```json
[]
```
