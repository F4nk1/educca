# Estado de la Aplicación Móvil EDUCCA Cusco — Cierre Sprint 1 (Entrega 2)

**Fecha de corte:** 18 de noviembre de 2026  
**Proyecto:** EDUCCA Cusco (Programa Municipal de Educación, Cultura y Ciudadanía Ambiental)  
**Módulo:** Aplicación Móvil Android (Flutter / Dart)  
**Versión evaluada:** Sprint 1 — Entrega 2  

---

## 1. Resumen Ejecutivo

La aplicación móvil de EDUCCA Cusco ha completado satisfactoriamente el desarrollo y la verificación visual y funcional correspondiente al **Sprint 1 (Entrega 2)**. 

El sistema cuenta con un flujo integral de demostración autónomo (**Modo Demostración**), diseñado con arquitectura desacoplada para garantizar una exhibición fluida y determinista sin requerir la presencia en vivo del backend en Go. Al mismo tiempo, la capa cliente real (`ApiEduccaRepository`, `ApiClient`, inyección de encabezados `Authorization: Bearer <token>`, manejo de `401 Unauthorized`) está completamente implementada y a la espera de la disponibilidad de los endpoints correspondientes en el servidor.

---

## 2. Pantallas Implementadas y Verificadas (Figma vs. Flutter)

Todas las pantallas cumplen estrictamente con el sistema de diseño andino institucional extraído mediante Figma MCP:
- **Paleta cromática:** Primario (#1B5E20 / #153B2F), Acento Dorado Andino (#D4AF37), Fondo Crema (#F8F6F0 / #FDFBF7), Card Container (#FFFFFF / #DED0B3).
- **Tipografía:** Poppins (títulos y acentos) e Inter / Roboto (lectura y campos de formulario).
- **Componentes comunes:** `AndeanHeader` (con soporte para vista completa y modo compacto), `AndeanCard`, `AndeanButton` (primario y secundario), `AndeanDemoBanner`, e iconografía SVG andina vectorial.

| Pantalla | Código Figma | Archivo Flutter | Estado | Descripción Funcional |
| :--- | :--- | :--- | :--- | :--- |
| **M01 — Login** | `node-id=2:2` | [login_screen.dart](file:///C:/Users/Fidel/Desktop/sistema-capacitaciones/lib/screens/login_screen.dart) | **Verificada** | Acceso de promotores con correo y contraseña. Acceso discreto a configuración de servidor / modo demo. |
| **M02 — Registro** | `node-id=2:24` | [register_screen.dart](file:///C:/Users/Fidel/Desktop/sistema-capacitaciones/lib/screens/register_screen.dart) | **Verificada** | Registro con selección de categoría (Escolar, Juvenil, Comunitario), validación de mayoría de edad (bloqueo a menores en escolar) y consentimiento LPDP N.° 29733. |
| **M03 — Inicio Promotor** | `node-id=2:58` | [home_screen.dart](file:///C:/Users/Fidel/Desktop/sistema-capacitaciones/lib/screens/home_screen.dart) | **Verificada** | Dashboard del promotor: saludo dinámico, tarjeta de próxima actividad, botón central «Escanear QR de asistencia», accesos rápidos y navegación inferior (Inicio, Talleres, Asistencias, Perfil con Demo Tour). |
| **M04 — Escáner QR** | `node-id=2:94` | [qr_scanner_screen.dart](file:///C:/Users/Fidel/Desktop/sistema-capacitaciones/lib/screens/qr_scanner_screen.dart) | **Verificada** | Visor de cámara con `MobileScanner`, encuadre andino (#153B2F), linterna, candado anti-doble lectura, ingreso manual de token y botón «Simular lectura QR» en modo demo. |
| **M05 — Ubicación y Privacidad** | `node-id=2:110` | [location_consent_screen.dart](file:///C:/Users/Fidel/Desktop/sistema-capacitaciones/lib/screens/location_consent_screen.dart) | **Verificada** | Tarjeta de divulgación y consentimiento previo. Explica la geocerca de 80 m a la sede y garantiza que el GPS opera únicamente de forma puntual durante el escaneo, sin rastreo de fondo. |
| **M06 — Verificación** | `node-id=2:127` | [verification_screen.dart](file:///C:/Users/Fidel/Desktop/sistema-capacitaciones/lib/screens/verification_screen.dart) | **Verificada** | Pantalla de transición animada con checklist de tres etapas: Lectura de código QR → Verificación de proximidad GPS → Registro seguro en servidor. |
| **M07 — Confirmación** | `node-id=2:141` | [attendance_result_screen.dart](file:///C:/Users/Fidel/Desktop/sistema-capacitaciones/lib/screens/attendance_result_screen.dart) | **Verificada** | Confirmación de asistencia exitosa. Despliega comprobante con nombre de la capacitación, hora registrada, sede y botones para volver al inicio o consultar historial. |
| **M08 — Estados de Rechazo** | `node-id=2:221` a `2:311` | [attendance_result_screen.dart](file:///C:/Users/Fidel/Desktop/sistema-capacitaciones/lib/screens/attendance_result_screen.dart) | **Verificada** | Soporte integral para las 7 variantes de error con iconografía de alerta, tarjetas de diagnóstico y acciones de reintento/retorno: **E01** (Fuera de geocerca > 80 m), **E02** (QR expirado en proyector), **E03** (Asistencia ya registrada / duplicado), **E04** (Sesión cerrada / no autorizado), **E05** (GPS no disponible / sensor apagado), **E06** (Sin conexión al servidor), **E07** (Imprecisión GPS > 50 m). |

---

## 3. Estado de Historias de Usuario (Sprint 1)

| HU | Nombre | Estado Móvil | Estado General | Observaciones |
| :--- | :--- | :--- | :--- | :--- |
| **HU-01** | Autenticación y Perfil del Promotor | **Completada** en cliente | Lista para backend | M01 y M02 verificados con validación, almacenamiento seguro de sesión (`SessionStorage`) y manejo de tokens. |
| **HU-02** | Visualización de Actividades Ambientales | **Completada** en cliente | Lista para backend | M03 y pestaña «Talleres» cargan las sesiones dinámicamente desde `CoursesProvider` inyectando `EduccaRepository`. |
| **HU-03** | Consulta de Historial de Asistencias | **Completada** en cliente | Lista para backend | Pestaña «Asistencias» lista los registros en sede con fecha, taller y estado. |
| **HU-04** | Registro de Asistencia mediante QR + GPS | **Implementada** en móvil | **En Curso (Pendiente backend)** | Flujo M04 → M05 → M06 → M07/M08 completado y operable. **No se declara terminada en Jira** hasta que los endpoints del backend Go validen y persistan en base de datos PostgreSQL real. |
| **RNF-01** | Transparencia de Privacidad (LPDP N.° 29733) | **Completada** | Cumplida | M05 y M02 informan el uso de datos personales y geolocalización puntual. |

---

## 4. Funcionalidades Reales vs. Funcionalidades Mock

### A. Funcionalidades Reales ya Operativas
- **Cámara y Escaneo QR físico:** La cámara del dispositivo móvil se activa mediante `mobile_scanner`, lee códigos QR reales en tiempo real y extrae el token dinámico de la sesión.
- **Sensor GPS / Geolocalización de alta precisión:** Obtención de coordenadas reales (`latitude`, `longitude`, `accuracy`) mediante `geolocator` con validación previa de servicios de ubicación encendidos y permisos en tiempo de ejecución.
- **Detección de conectividad de red:** Comprobación real de conexión antes de procesar solicitudes.
- **Almacenamiento seguro local:** Manejo de credenciales y tokens mediante `flutter_secure_storage` y `shared_preferences`.
- **Validación de formularios y contratos de datos:** Verificación de formato de correo, fortaleza de contraseña, categorías oficiales y validación estricta de mayor de edad.
- **Conmutador de entorno caliente:** La aplicación puede alternar instantáneamente entre la API real (`http://10.0.2.2:8080/api/v1`) y el modo demostración sin reiniciar el proceso.

### B. Funcionalidades en Modo Demostración (Mock)
- **Persistencia local simulada:** Las asistencias registradas en modo demo se conservan en memoria durante la ejecución de la app y alimentan la pestaña «Asistencias».
- **Consistencia determinista de duplicados:** La primera lectura del token `EDUCCA-SES-301-DEMO` genera un registro confirmado (M07); una segunda lectura consecutiva del mismo token genera inmediatamente el rechazo E03 (*Asistencia ya registrada*), permitiendo demostrar el comportamiento de protección de duplicados.
- **Simulador de escaneo:** Botón «Simular lectura QR» en M04 para pruebas en emuladores de escritorio donde la cámara física no enfoca un proyector web.
- **Recorrido de Demostración:** Selector modal en la pestaña Perfil para disparar de forma directa cualquiera de los escenarios M07 o M08 (E01 a E07).

---

## 5. Pendientes para Conexión con Backend Go

Para completar la integración de **HU-04** en el backend compartido:

1. **Endpoint `POST /api/v1/attendance/validate`:**
   - Recibir payload JSON:
     ```json
     {
       "session_token": "EDUCCA-SES-301-DEMO",
       "latitude": -13.517088,
       "longitude": -71.978535,
       "accuracy_meters": 12.5,
       "device_time": "2026-11-18T18:30:00Z"
     }
     ```
   - Calcular la distancia Haversine a la sede del taller ambiental.
   - Retornar `200 OK` si distancia $\le 80\text{ m}$ con comprobante.
   - Retornar códigos de error con el campo `"code"` correspondiente (`OUT_OF_RANGE`, `EXPIRED_TOKEN`, `ALREADY_REGISTERED`, `SESSION_CLOSED`, `INACCURATE_GPS`) para que la app mapee automáticamente la pantalla M08 respectiva.
2. **Endpoint `GET /api/v1/promoters/me/attendances`:**
   - Retornar lista de registros del promotor autenticado para el historial de M03.
3. **Endpoint `GET /api/v1/courses/active`:**
   - Listar sesiones de capacitación abiertas para la tarjeta de próxima actividad.

---

## 6. Evidencia de Pruebas Automatizadas

- **Análisis estático:** `flutter analyze` ejecutado con **0 incidencias** (`No issues found!`).
- **Suite de pruebas:** `flutter test` ejecutado con **35/35 pruebas aprobadas al 100%**:
  - `test/unit/attendance_models_test.dart`: Modelos de asistencia, DTOs y mapeo de errores del backend Go.
  - `test/unit/promoter_user_test.dart`: Parseo y serialización de promotor, categorías y consentimientos.
  - `test/unit/core_test.dart`: Pruebas de cliente HTTP, interceptor 401 y contenedor `Result<T>`.
  - `test/widget/attendance_flow_test.dart`: 11 pruebas de widgets que cubren M04, M05, M06, M07 y las variantes de error E01, E02, E03, E05, E06, E07.
  - `test/widget/home_screen_test.dart`: Tarjeta de próxima actividad y accesos rápidos de M03.
  - `test/widget/login_screen_test.dart`: Validación de entradas de M01.
  - `test/widget/register_screen_test.dart`: Validación de campos y consentimiento de M02.

---

## 7. Instrucciones para la Exposición del Sprint 1

Para demostrar la aplicación ante el equipo evaluador:

1. Iniciar la aplicación en el emulador o dispositivo Android.
2. Iniciar sesión con cualquier correo válido (o registrar un nuevo promotor). La app iniciará automáticamente en **Modo Demostración**.
3. **Demostración del Flujo Principal Exitoso:**
   - En **Inicio (M03)**, presionar el botón verde **«Escanear QR de asistencia»**.
   - En **M04**, pulsar **«Simular lectura QR»** (o escanear un QR real).
   - En **M05**, revisar la transparencia de privacidad de la geocerca de 80 m y presionar **«Continuar y permitir ubicación»**.
   - Observar la transición animada de 3 etapas en **M06**.
   - Visualizar el comprobante en **M07** (*Registro confirmado*).
   - Presionar **«Ver mis asistencias»** para comprobar cómo la nueva asistencia aparece reflejada en la pestaña del historial.
4. **Demostración de Rechazos (M08) y Escenarios Alternativos:**
   - Ir a la pestaña **Perfil** (último icono inferior).
   - Presionar **«Recorrido de Demostración (Sprint 1)»**.
   - Seleccionar cualquier variante para exhibición inmediata (por ejemplo: *E01 Fuera del área de asistencia*, *E02 QR vencido*, *E03 Asistencia duplicada*).

---

## 8. Recomendaciones para el Repositorio Compartido

- La carpeta `sistema-capacitaciones` debe ubicarse en la raíz del repositorio (`/mobile` o `/app-mobile`), manteniendo desacoplado el ciclo de CI/CD móvil del backend Go (`/backend` o `/server`).
- No versionar archivos `.env` ni credenciales locales.
- El archivo `pubspec.yaml` ya incluye los assets SVG vectoriales en `assets/images/`. No mover ni renombrar estos recursos.
