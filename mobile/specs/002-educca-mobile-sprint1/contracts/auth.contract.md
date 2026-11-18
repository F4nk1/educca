# REST API Contract: Autenticación y Registro EDUCCA (Borrador de Integración)

**Estado**: Borrador adaptable para homologación con backend Go + PostgreSQL (Dev 1).  
**Headers Comunes**:
* `Content-Type: application/json`
* `Accept: application/json`

---

## 1. Registro de Promotor Ambiental (HU-01 / RF-01 / RNF-01)

- **Método**: `POST`
- **Ruta preliminar**: `/auth/register` (o `/api/v1/auth/register`)
- **Autenticación**: Pública

### Request Body
```json
{
  "fullName": "Juan Carlos Pérez",
  "email": "promotor.cusco@example.org",
  "password": "<secreto_usuario>",
  "promoterCategory": "JUVENIL",
  "isAdult": true,
  "privacyConsentAccepted": true
}
```

*Validaciones esperadas en servidor:*
* `email`: formato válido, unicidad en tabla `promoters/users`.
* `password`: longitud mínima según política de backend (ej. ≥ 6 u 8 caracteres).
* `promoterCategory`: enum `ESCOLAR`, `JUVENIL`, `COMUNITARIO`.
* `privacyConsentAccepted`: obligatorio en `true`.
* Si `promoterCategory == "ESCOLAR"` y `isAdult == false`, el cliente bloquea localmente; si llegara al servidor, debe rechazarlo con código `MINOR_NOT_ALLOWED`.

### Respuestas del Servidor
#### 201 Created — Registro Exitoso
```json
{
  "status": "CREATED",
  "message": "Promotor registrado correctamente",
  "user": {
    "id": "prom-100",
    "fullName": "Juan Carlos Pérez",
    "email": "promotor.cusco@example.org",
    "role": "PROMOTOR",
    "promoterCategory": "JUVENIL"
  }
}
```

#### 409 Conflict — Correo Ya Registrado
```json
{
  "code": "EMAIL_ALREADY_EXISTS",
  "message": "El correo electrónico ya se encuentra registrado en el sistema"
}
```

---

## 2. Inicio de Sesión (Login HU-01 / RF-01)

- **Método**: `POST`
- **Ruta preliminar**: `/auth/login` (o `/api/v1/auth/login`)
- **Autenticación**: Pública

### Request Body
```json
{
  "email": "promotor.cusco@example.org",
  "password": "<secreto_usuario>"
}
```

### Respuestas del Servidor
#### 200 OK — Inicio Exitoso
```json
{
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "user": {
    "id": "prom-100",
    "fullName": "Juan Carlos Pérez",
    "email": "promotor.cusco@example.org",
    "role": "PROMOTOR",
    "promoterCategory": "JUVENIL"
  }
}
```

#### 401 Unauthorized — Credenciales Incorrectas
```json
{
  "code": "INVALID_CREDENTIALS",
  "message": "Credenciales inválidas. Verifica tu correo y contraseña"
}
```
