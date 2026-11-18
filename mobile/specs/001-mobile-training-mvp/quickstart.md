# Quickstart & Guía de Validación: MVP Móvil

**Feature**: `specs/001-mobile-training-mvp`  
**Objetivo**: Guía de verificación paso a paso para la sustentación y demostración de la Entrega 2 (E2).

---

## 1. Prerrequisitos de Ejecución

1. **Entorno Móvil**:
   - Flutter SDK (versión 3.x+) y Dart SDK (versión 3.x+).
   - Android Studio con al menos un emulador AVD configurado (ej. Pixel 6 API 34) o un dispositivo físico Android con depuración USB habilitada.
   - **Configuración de Cámara Virtual en Emulador (AVD)**:
     - Para probar el escaneo de QR en emulador sin webcam física: Abrir *AVD Manager* $\rightarrow$ Editar dispositivo virtual $\rightarrow$ *Show Advanced Settings* $\rightarrow$ En *Camera: Back* seleccionar **VirtualScene** (permite mover la cámara con `Alt + W/A/S/D` en un entorno 3D donde se proyectan imágenes) o **Webcam0** (si tienes cámara web en tu PC).
     - En compilaciones de depuración (`debug`), la app permite conexiones HTTP en texto claro a `10.0.2.2:3000` o la IP de tu red local sin afectar la seguridad en producción (`release`).
2. **Backend Compartido**:
   - Servicio API REST operativo provisto por el equipo (NestJS u homólogo con PostgreSQL).
   - Base de datos con datos de prueba iniciales (*seed*):
     - 1 Estudiante (`estudiante@ejemplo.edu.pe` / `Password123!`).
     - 1 Curso con el estudiante inscrito.
     - 1 Sesión en estado `OPEN` con QR proyectándose en la pantalla web del instructor.

---

## 2. Comandos de Preparación y Verificación Estática

Desde la raíz del repositorio (`sistema-capacitaciones`):

```powershell
# 1. Instalar dependencias del cliente Flutter
flutter pub get

# 2. Ejecutar análisis estático (Verificación de Cero Advertencias)
flutter analyze

# 3. Ejecutar pruebas unitarias y de widgets
flutter test
```

---

## 3. Escenarios de Demostración de Extremo a Extremo

### Escenario 1: Configuración de Conexión y Autenticación
1. Abrir la aplicación en el emulador Android o dispositivo.
2. En la pantalla de inicio de sesión:
   - Pulsar el icono de **Ajustes de Conexión** (esquina superior o pie de pantalla).
   - Verificar la URL base:
     - En emulador de Android Studio: `http://10.0.2.2:3000/api/v1`
     - En dispositivo físico: `http://<IP_LOCAL_DE_TU_MAQUINA>:3000/api/v1`
   - Guardar y regresar al formulario.
3. Probar caso negativo: Ingresar contraseña errónea $\rightarrow$ Verificar mensaje `"Credenciales inválidas"`.
4. Probar caso positivo: Ingresar `estudiante@ejemplo.edu.pe` y `Password123!` $\rightarrow$ Verificar transición exitosa al panel `"Mis Capacitaciones"`.

---

### Escenario 2: Navegación de Capacitaciones y Sesiones
1. En `"Mis Capacitaciones"`, observar la lista con el curso asignado (*Ingeniería de Software I*).
2. Probar gesto *pull-to-refresh* (deslizar hacia abajo) $\rightarrow$ La lista se refresca con indicador de carga.
3. Seleccionar el curso $\rightarrow$ Ingresar a la pantalla de detalle de sesiones.
4. Identificar las sesiones:
   - Sesión con estado `OPEN`: Resaltada con indicador visual de asistencia habilitada.
   - Sesión con estado `SCHEDULED` o `CLOSED`: Indicada adecuadamente.

---

### Escenario 3: Escaneo de Código QR y Marcado Exitoso
1. Pulsar la acción **"Escanear Asistencia"** (desde el botón rápido de la barra inferior o desde el botón de la sesión abierta).
2. Si es la primera ejecución, confirmar el diálogo contextual y conceder el permiso de cámara.
3. Apuntar la cámara al código QR dinámico proyectado por el instructor en la pantalla web.
4. **Resultado Esperado**:
   - El escaneo se congela inmediatamente sin lecturas redundantes.
   - Se muestra diálogo/pantalla de éxito con icono verde, confirmando la fecha y hora emitida por el servidor.

---

### Escenario 4: Pruebas de Rechazo e Idempotencia (Casos de Borde)
1. **Reintento Inmediato (Asistencia Duplicada)**:
   - Volver a escanear el mismo código QR o uno nuevo de la misma sesión.
   - **Resultado Esperado**: Mensaje informativo de advertencia: `"Tu asistencia ya fue registrada previamente para esta sesión"`.
2. **Código QR Expirado**:
   - Escanear una captura de pantalla vieja del QR que haya superado los 60 segundos de vigencia.
   - **Resultado Esperado**: Mensaje de error: `"El código QR ha expirado. Por favor, escanea el código actualizado en pantalla"`.
3. **Pérdida de Conexión**:
   - Poner el emulador en modo avión e intentar escanear.
   - **Resultado Esperado**: Diálogo con aviso `"Sin conexión con el servidor"` y botón para reintentar.

---

### Escenario 5: Consulta de Historial y Cierre de Sesión
1. Navegar a la pestaña o sección `"Mi Historial"`.
2. Verificar que aparezca listado el registro de asistencia recién marcado con su respectiva fecha y hora.
3. Pulsar la opción `"Cerrar Sesión"`.
4. Confirmar la acción.
5. **Resultado Esperado**:
   - Retorno automático a la pantalla de Login.
   - Pulsar el botón atrás de Android no debe permitir volver al historial ni a los cursos.
