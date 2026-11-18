# REST API Contracts: Autenticación y Sesión

**Base URL**: `http://<HOST>:<PORT>/api/v1`  
**Headers comunes**:
- `Content-Type: application/json`
- `Accept: application/json`

---

## 1. Iniciar Sesión

- **Método**: `POST`
- **Ruta**: `/auth/login`
- **Autenticación**: Pública

### Request Body
```json
{
  "email": "estudiante@ejemplo.edu.pe",
  "password": "Password123!"
}
```

### Response 200 OK (Éxito)
```json
{
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "user": {
    "id": "usr-est-001",
    "fullName": "Juan Carlos Pérez",
    "email": "estudiante@ejemplo.edu.pe",
    "role": "STUDENT"
  }
}
```

### Response 401 Unauthorized (Credenciales incorrectas)
```json
{
  "statusCode": 401,
  "message": "Credenciales inválidas"
}
```

### Response 403 Forbidden (Usuario inactivo o rol sin acceso)
```json
{
  "statusCode": 403,
  "message": "Usuario inactivo o no autorizado"
}
```

---

## 2. Obtener Perfil Autenticado

- **Método**: `GET`
- **Ruta**: `/auth/me`
- **Autenticación**: `Authorization: Bearer <token>`

### Response 200 OK
```json
{
  "id": "usr-est-001",
  "fullName": "Juan Carlos Pérez",
  "email": "estudiante@ejemplo.edu.pe",
  "role": "STUDENT"
}
```

### Response 401 Unauthorized (Token expirado o revocado)
```json
{
  "statusCode": 401,
  "message": "Token de sesión expirado o inválido"
}
```

---

## 3. Cerrar Sesión

- **Método**: `POST`
- **Ruta**: `/auth/logout`
- **Autenticación**: `Authorization: Bearer <token>`

### Response 200 OK
```json
{
  "message": "Sesión cerrada satisfactoriamente"
}
```
*(Nota: El cliente móvil purga el token de su almacenamiento seguro local sin importar si la petición de red llega al servidor o falla).*
