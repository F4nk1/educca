# REST API Contracts: Capacitaciones y Sesiones

**Base URL**: `http://<HOST>:<PORT>/api/v1`  
**Headers comunes**:
- `Authorization: Bearer <token>`
- `Accept: application/json`

---

## 1. Listar Capacitaciones del Estudiante ("Mis Cursos")

- **Método**: `GET`
- **Ruta**: `/student/courses`
- **Autenticación**: Obligatoria (`Bearer <token>`)

### Response 200 OK
```json
[
  {
    "id": "crs-101",
    "title": "Ingeniería de Software I y Métodos Ágiles",
    "description": "Capacitación práctica en desarrollo ágil con Scrum, Git y control de calidad.",
    "instructorName": "Ing. Marco Aurelio Quispe",
    "startDate": "2026-11-01T00:00:00.000Z",
    "endDate": "2026-12-15T23:59:59.000Z",
    "status": "ACTIVE"
  },
  {
    "id": "crs-102",
    "title": "Taller de Seguridad y Protección de Datos Personales",
    "description": "Normativa LPDP Ley 29733 aplicada a sistemas de información.",
    "instructorName": "Dra. Carmen Rosa Valdivia",
    "startDate": "2026-11-10T00:00:00.000Z",
    "endDate": "2026-11-30T23:59:59.000Z",
    "status": "ACTIVE"
  }
]
```

### Response 200 OK (Sin inscripciones - Estado Vacío)
```json
[]
```

### Response 401 Unauthorized
```json
{
  "statusCode": 401,
  "message": "Token de sesión no válido"
}
```

---

## 2. Listar Sesiones Programadas de un Curso

- **Método**: `GET`
- **Ruta**: `/student/courses/:courseId/sessions`
- **Autenticación**: Obligatoria (`Bearer <token>`)

### Path Parameters
- `courseId` (string, obligatorio): Identificador único del curso en el que está inscrito.

### Response 200 OK
```json
[
  {
    "id": "ses-501",
    "courseId": "crs-101",
    "title": "Sesión 1: Introducción y Product Backlog",
    "scheduledDate": "2026-11-15T00:00:00.000Z",
    "startTime": "08:00",
    "endTime": "10:00",
    "location": "Pabellón B - Aula 204",
    "attendanceStatus": "CLOSED"
  },
  {
    "id": "ses-502",
    "courseId": "crs-101",
    "title": "Sesión 2: Arquitectura del MVP y Control de Asistencia",
    "scheduledDate": "2026-11-17T00:00:00.000Z",
    "startTime": "08:00",
    "endTime": "10:00",
    "location": "Laboratorio de Cómputo 3",
    "attendanceStatus": "OPEN"
  },
  {
    "id": "ses-503",
    "courseId": "crs-101",
    "title": "Sesión 3: Pruebas y Sustentación de la Entrega 2",
    "scheduledDate": "2026-11-22T00:00:00.000Z",
    "startTime": "08:00",
    "endTime": "10:00",
    "location": "Auditorio Principal",
    "attendanceStatus": "SCHEDULED"
  }
]
```

### Response 403 Forbidden (No inscrito en este curso)
```json
{
  "statusCode": 403,
  "message": "El estudiante no tiene acceso al curso solicitado"
}
```
