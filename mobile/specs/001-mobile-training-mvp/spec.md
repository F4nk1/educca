# Feature Specification: MVP de Aplicación Móvil de Gestión de Capacitaciones

**Feature Branch**: `001-mobile-training-mvp`

**Created**: 2026-11-17

**Status**: Draft

**Input**: User description: "Desarrollar el MVP de la aplicación móvil de Gestión de Capacitaciones para la entrega 2 del proyecto de Ingeniería de Software I. Utilizar como referencia las especificaciones maestras disponibles en docs/, pero limitar estrictamente el alcance al cliente móvil. Definir historias de usuario y criterios de aceptación verificables para: (1) autenticación y cierre de sesión, (2) consulta de capacitaciones e inscripciones, (3) consulta de sesiones programadas, (4) escaneo de QR dinámico para registrar asistencia y presentar el resultado y (5) historial básico de asistencia. Considerar estados de carga, errores de conexión, QR inválidos, vencidos o previamente utilizados, y acceso no autorizado. La validación definitiva de asistencia corresponde al servidor. No generar funcionalidades administrativas web, backend, certificados, evaluaciones ni dashboards. Priorizar lo indispensable para demostrar los flujos de la entrega 2. Generar únicamente la especificación, sin implementar código."

## Clarifications

### Session 2026-11-17
- Q: ¿Cómo debe configurarse la URL base de la API backend en la aplicación móvil para facilitar las pruebas entre emuladores y dispositivos físicos durante la Entrega 2? → A: Diálogo o pantalla simple de ajustes de conexión accesible desde la pantalla de login para editar la IP/URL en caliente, con valor inicial por defecto (ej. `http://10.0.2.2:3000`).
- Q: ¿Desde qué punto de la navegación de la aplicación debe poder el estudiante iniciar el escaneo del código QR para marcar su asistencia? → A: Acceso dual: botón de escaneo rápido en la barra principal de navegación y botón contextual dentro del detalle de la sesión con asistencia abierta.
- Q: ¿Cómo debe gestionar la aplicación la persistencia local de los datos de capacitaciones e historial ante la pérdida de conexión a internet? → A: Enfoque en línea directo (*Online-first*): consultas directas a la API con manejo explícito de errores de red y botón de reintento, sin persistencia en caché local offline para el MVP E2.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Autenticación y Control de Sesión del Estudiante (Priority: P1)

Como estudiante registrado en el sistema, quiero iniciar sesión con mi correo institucional y contraseña, y poder cerrar mi sesión cuando lo decida, para acceder de forma segura a mi información académica y proteger la privacidad de mis registros.

**Why this priority**: Es la puerta de entrada indispensable a todas las funciones privadas de la aplicación. Sin autenticación y control de sesión, no es posible identificar al estudiante para consultar sus cursos ni validar su asistencia.

**Independent Test**: Puede probarse de manera aislada ingresando credenciales válidas para verificar el ingreso a la pantalla principal, comprobando el rechazo de credenciales incorrectas, y verificando el retorno a la pantalla de acceso tras cerrar sesión.

**Acceptance Scenarios**:

1. **Given** un estudiante no autenticado en la pantalla de inicio de sesión, **When** ingresa su correo electrónico válido y su contraseña correcta y pulsa "Iniciar Sesión", **Then** el sistema presenta un indicador de carga, valida las credenciales y le permite acceder a la vista principal de sus capacitaciones, conservando su sesión activa.
2. **Given** un estudiante en la pantalla de inicio de sesión, **When** ingresa un correo o contraseña incorrectos, **Then** el sistema muestra un mensaje claro de error indicando que las credenciales son inválidas, sin especificar si el correo existe o no, manteniendo los campos listos para un nuevo intento.
3. **Given** un estudiante en la pantalla de inicio de sesión, **When** intenta ingresar dejando el correo o la contraseña en blanco o con formato de correo inválido, **Then** el sistema señala visualmente los campos requeridos antes de procesar la solicitud.
4. **Given** un estudiante autenticado dentro de la aplicación, **When** selecciona la opción de "Cerrar Sesión", **Then** el sistema solicita confirmación, elimina las credenciales locales de la sesión activa y redirige inmediatamente a la pantalla de inicio de sesión, impidiendo regresar a las pantallas protegidas mediante la navegación hacia atrás.
5. **Given** un estudiante con una sesión previa cuyo token ha caducado o ha sido revocado en el servidor, **When** abre la aplicación o realiza una acción que requiere autorización, **Then** el sistema informa que la sesión ha expirado y lo redirige a la pantalla de inicio de sesión.
6. **Given** un evaluador o estudiante en la pantalla de inicio de sesión, **When** pulsa la opción de ajustes de conexión, **Then** puede visualizar y modificar la URL o dirección IP base del servidor backend y guardar los cambios para dirigir inmediatamente las peticiones a la nueva dirección.

---

### User Story 2 - Consulta de Capacitaciones e Inscripciones Activas (Priority: P1)

Como estudiante autenticado, quiero ver la lista de capacitaciones en las que estoy formalmente inscrito para conocer mi oferta formativa vigente, detalles del curso y acceder a sus sesiones.

**Why this priority**: Es la vista central de navegación del estudiante. Permite seleccionar una capacitación para revisar su cronograma o verificar si está habilitado para marcar asistencia.

**Independent Test**: Puede probarse iniciando sesión con una cuenta de estudiante con inscripciones activas y verificando que se listen sus cursos con título, fechas e instructor asignado; así como con una cuenta sin inscripciones comprobando el estado vacío.

**Acceptance Scenarios**:

1. **Given** un estudiante autenticado con capacitaciones asignadas, **When** ingresa a la sección "Mis Capacitaciones", **Then** el sistema presenta un indicador de carga y posteriormente despliega la lista de cursos en los que está inscrito, mostrando para cada uno: nombre de la capacitación, nombre del instructor y periodo de vigencia.
2. **Given** un estudiante autenticado que no cuenta con inscripciones registradas, **When** ingresa a "Mis Capacitaciones", **Then** el sistema presenta un mensaje informativo de estado vacío indicando amigablemente que no tiene capacitaciones activas en este momento.
3. **Given** un estudiante en la lista de capacitaciones, **When** ocurre una falla de conexión o tiempo de espera agotado al consultar la información, **Then** el sistema muestra un mensaje de error de conexión con un botón visible para "Reintentar" la carga.
4. **Given** la lista de capacitaciones desplegada, **When** el estudiante realiza un gesto de actualización ("pull-to-refresh"), **Then** el sistema consulta y refresca la información actualizada de sus inscripciones.

---

### User Story 3 - Consulta de Sesiones y Cronograma de Capacitación (Priority: P2)

Como estudiante inscrito en una capacitación, quiero ver el detalle de las sesiones programadas (fecha, horario, ubicación/aula y estado de asistencia) para planificar mi asistencia y saber en qué sesión debo registrarme.

**Why this priority**: Proporciona el contexto temporal y logístico necesario antes de que el estudiante proceda al escaneo del código QR.

**Independent Test**: Puede probarse seleccionando un curso específico y verificando que se liste el cronograma de sesiones con fechas ordenadas cronológicamente, indicando si la sesión está abierta, programada o concluida.

**Acceptance Scenarios**:

1. **Given** un estudiante que visualiza el detalle de una capacitación, **When** consulta las sesiones programadas, **Then** el sistema muestra la lista de sesiones ordenadas cronológicamente con: título o tema de la sesión, fecha, hora de inicio y fin, ubicación o modalidad, y el estado de la sesión (ej. Programada, Asistencia Abierta, Concluida).
2. **Given** una sesión cuya asistencia ha sido abierta por el instructor, **When** el estudiante visualiza la sesión, **Then** el sistema destaca visualmente que la sesión se encuentra lista para el registro de asistencia mediante código QR.
3. **Given** una capacitación sin sesiones programadas aún, **When** el estudiante ingresa al detalle, **Then** el sistema presenta un mensaje informativo indicando que aún no se han programado sesiones para este curso.

---

### User Story 4 - Escaneo de Código QR y Registro de Asistencia (Priority: P1)

Como estudiante que asiste presencialmente a una sesión, quiero escanear con la cámara de mi dispositivo el código QR dinámico presentado por el instructor para registrar mi asistencia de forma inmediata y obtener una confirmación clara del resultado.

**Why this priority**: Es la funcionalidad nuclear de la Entrega 2. Integra el uso del hardware del dispositivo móvil con la validación de negocio en el servidor central.

**Independent Test**: Puede probarse abriendo el escáner de cámara, capturando un código QR temporal emitido para una sesión válida y verificando que el sistema muestre la confirmación de asistencia; y probando con códigos QR caducados o repetidos para comprobar los rechazos específicos.

**Acceptance Scenarios**:

1. **Given** un estudiante autenticado (ya sea desde la barra principal de navegación o dentro de una sesión con asistencia abierta), **When** pulsa la acción de escanear asistencia por primera vez, **Then** el sistema solicita permiso para acceder a la cámara explicando previamente el propósito educativo de la solicitud.
2. **Given** que el permiso de cámara ha sido concedido, **When** el visor de cámara enfoca y detecta un código QR dinámico válido emitido por el servidor para la sesión en curso, **Then** el sistema detiene lecturas adicionales, envía el token al servidor con la sesión autenticada y muestra un estado de procesamiento.
3. **Given** un envío de código QR exitosamente validado por el servidor, **When** se confirma el registro, **Then** el sistema presenta una pantalla o modal de éxito con icono afirmativo, nombre de la capacitación, tema de la sesión y fecha/hora registrada.
4. **Given** que el estudiante intenta escanear un código QR que ya expiró en el servidor (duración mayor a la vigencia establecida), **When** se procesa la validación, **Then** el sistema muestra un mensaje de advertencia indicando que el código QR ha caducado y solicita al estudiante escanear el nuevo código proyectado por el instructor.
5. **Given** un estudiante que ya registró exitosamente su asistencia en la sesión actual, **When** intenta escanear nuevamente el código QR (o un nuevo QR de la misma sesión), **Then** el sistema recibe la respuesta del servidor y muestra un aviso informativo de "Asistencia previamente registrada", evitando duplicados.
6. **Given** que el estudiante enfoca un código QR ajeno al sistema, malformado o correspondiente a una capacitación en la que no está inscrito, **When** el servidor rechaza el registro, **Then** el sistema informa que el código QR no es válido para su inscripción actual.
7. **Given** que el usuario rechaza el permiso de cámara del dispositivo, **When** intenta abrir la función de escaneo, **Then** el sistema presenta una pantalla instructiva explicando por qué se requiere la cámara y cómo habilitar el permiso en los ajustes del dispositivo.

---

### User Story 5 - Consulta de Historial de Asistencias Registradas (Priority: P2)

Como estudiante capacitado, quiero revisar mi historial de asistencias confirmadas para tener constancia y trazabilidad de las sesiones a las que he asistido.

**Why this priority**: Brinda transparencia y certeza al estudiante sobre su participación acumulada en las distintas capacitaciones.

**Independent Test**: Puede probarse accediendo a la sección de historial de asistencias y verificando que se listen exclusivamente las asistencias confirmadas del usuario autenticado, con indicación de curso, sesión y fecha/hora de registro.

**Acceptance Scenarios**:

1. **Given** un estudiante autenticado con asistencias previamente registradas, **When** accede a la sección "Mi Historial de Asistencia", **Then** el sistema presenta la lista de todas sus asistencias registradas ordenadas de la más reciente a la más antigua, mostrando curso, sesión, fecha y hora de marcado.
2. **Given** un estudiante que aún no ha registrado ninguna asistencia, **When** consulta su historial, **Then** el sistema muestra un mensaje informativo de estado vacío indicando que aún no cuenta con asistencias registradas.
3. **Given** el historial de asistencias en pantalla, **When** el estudiante realiza un gesto de actualización o pulsa "Actualizar", **Then** la lista se sincroniza con el servidor para reflejar nuevos registros.

---

### Edge Cases

- **Pérdida de conectividad durante el envío del escaneo**: Si el dispositivo pierde conexión tras leer el QR y antes de recibir respuesta del servidor, el sistema debe mostrar un aviso de "Sin conexión a internet" con opción de reintentar sin necesidad de reiniciar la aplicación ni generar estados inconsistentes.
- **Sesión cerrada por el instructor mientras el estudiante escaneaba**: Si entre la lectura del QR y el procesamiento en servidor la sesión pasa a estado `CLOSED`, el servidor rechazará la solicitud y la aplicación debe mostrar el mensaje correspondiente: "El periodo de registro para esta sesión ha concluido".
- **Intento de escaneo múltiple ultrarrápido**: Si el usuario mantiene la cámara fija sobre el código QR, la aplicación debe bloquear de inmediato el analizador de imagen tras la primera captura para evitar enviar ráfagas de peticiones concurrentes al servidor.
- **Acceso con cuenta de rol no autorizado**: Si un usuario con rol administrativo o docente intenta usar la aplicación estudiantil, el sistema debe permitir el inicio de sesión y presentar claramente un mensaje de rol incompatible si no tiene perfil de estudiante.
- **Dispositivo sin hardware de cámara**: La aplicación debe detectar la ausencia de hardware de cámara y mostrar un mensaje preventivo sin cerrarse inesperadamente.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: La aplicación DEBE proporcionar una interfaz de autenticación que permita ingresar correo electrónico y contraseña.
- **FR-002**: La aplicación DEBE validar localmente el formato del correo y la presencia de contraseña antes de enviar la solicitud al servidor.
- **FR-003**: La aplicación DEBE almacenar de forma segura y encriptada el token de sesión devuelto por el servidor, asegurando que persista entre reinicios de la aplicación mientras sea válido.
- **FR-004**: La aplicación DEBE incluir una opción accesible para cerrar sesión, la cual DEBE purgar las credenciales locales de inmediato y bloquear el acceso a pantallas protegidas.
- **FR-005**: La aplicación DEBE detectar respuestas de sesión no autorizada o token expirado (HTTP 401) en cualquier consulta y redirigir automáticamente al usuario al inicio de sesión.
- **FR-006**: La aplicación DEBE consultar y listar las capacitaciones en las que el estudiante autenticado está formalmente inscrito.
- **FR-007**: La aplicación DEBE permitir visualizar el detalle de una capacitación seleccionada, incluyendo sus sesiones programadas con fecha, hora, ubicación y estado.
- **FR-008**: La aplicación DEBE gestionar de manera transparente los permisos del sistema para el uso de la cámara fotográfica, solicitando la autorización al usuario con una explicación previa y manejando educadamente la denegación del permiso.
- **FR-009**: La aplicación DEBE incorporar un lector de códigos QR accesible tanto desde la navegación principal (botón de escaneo rápido) como desde la vista de detalle de una sesión abierta, capaz de capturar el token efímero proyectado en pantalla.
- **FR-010**: La aplicación DEBE congelar el escaneo tras la primera lectura detectada para evitar lecturas consecutivas no deseadas.
- **FR-011**: La aplicación DEBE transmitir el token escaneado junto con la identificación de sesión autenticada al endpoint correspondiente del servidor central para su validación definitiva.
- **FR-012**: La aplicación DEBE presentar una respuesta visual diferenciada y comprensible para cada uno de los siguientes resultados de validación devueltos por el servidor:
  - Registro de asistencia confirmado exitosamente.
  - Asistencia ya registrada previamente para la misma sesión (duplicado).
  - Código QR caducado o vencido temporalmente.
  - Código QR inválido o no reconocido.
  - Sesión cerrada o fuera de horario permitido.
  - Estudiante no inscrito en la capacitación correspondiente.
- **FR-013**: La aplicación DEBE listar el historial de asistencias confirmadas del estudiante autenticado, con datos de curso, sesión y fecha/hora registrada.
- **FR-014**: Todas las pantallas con carga de datos remotos DEBEN implementar explícitamente cuatro estados de interfaz: Carga (*Loading* con indicador visual), Contenido (*Content* con datos correctos), Vacío (*Empty* con mensaje amigable) y Error (*Error* con mensaje comprensible y botón de reintento).
- **FR-015**: La aplicación DEBE permitir la configuración de la dirección URL base del backend mediante un diálogo o pantalla accesible desde la vista de inicio de sesión, manteniendo un valor inicial por defecto (ej. http://10.0.2.2:3000 para emulador Android) y persistiendo la selección localmente para evitar recompilaciones durante pruebas en redes locales o dispositivos físicos.

### Key Entities *(include if feature involves data)*

- **Estudiante (Usuario)**: Representa al usuario autenticado. Atributos clave visibles: identificador único, nombre completo, correo electrónico institucional y rol (`STUDENT`).
- **Capacitación (Curso)**: Representa el programa o curso formativo en el que está inscrito el estudiante. Atributos clave: identificador, título del curso, descripción resumida, nombre del instructor asignado, fecha de inicio y fecha de finalización.
- **Sesión**: Representa un evento formativo programado dentro de una capacitación. Atributos clave: identificador de sesión, título/tema de la sesión, fecha programada, hora de inicio, hora de finalización, ubicación/sala física, y estado del registro de asistencia (`SCHEDULED`, `OPEN`, `CLOSED`).
- **Registro de Asistencia**: Representa la constancia verificada de presencia de un estudiante en una sesión. Atributos clave: identificador de registro, identificador de sesión, identificador de estudiante, fecha/hora exacta de validación emitida por el servidor y estado (`CONFIRMED`).
- **Token de Asistencia QR**: Cadena de texto o identificador criptográfico temporal emitido exclusivamente por el backend con un tiempo de vida corto, asociado a una sesión activa. No contiene datos personales del estudiante.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Un estudiante puede completar el flujo de inicio de sesión e ingresar a su panel de capacitaciones en menos de 10 segundos en condiciones normales de red.
- **SC-002**: El escaneo y procesamiento del código QR dinámico desde que la cámara enfoca el código hasta la presentación del resultado en pantalla toma menos de 3 segundos bajo conexión estable.
- **SC-003**: El 100 % de los escenarios de respuesta del servidor (éxito, código vencido, asistencia duplicada, sesión cerrada y error de red) se presentan con retroalimentación visual clara sin bloqueos de la aplicación ni pantallas en blanco.
- **SC-004**: La tasa de fallos o cierres inesperados de la aplicación durante la navegación por los flujos de la Entrega 2 es del 0 % en el entorno de pruebas en emulador y dispositivo Android.
- **SC-005**: El 100 % de los intentos de marcar asistencia en sesiones donde el estudiante ya tiene un registro previo son informados como "asistencia ya registrada", sin duplicar datos en la base del servidor.
- **SC-006**: Ninguna pantalla privada o dato de asistencia es accesible tras accionar el cierre de sesión ("Cerrar Sesión").

## Assumptions

- **Backend externo disponible**: Existe un servicio backend REST operativo y compartido por el equipo que implementa las reglas de negocio, la generación del token QR y la persistencia en PostgreSQL conforme a las especificaciones maestras.
- **Validación server-side autoritativa**: La aplicación móvil no calcula ni valida por sí misma la vigencia del token QR ni la unicidad de la asistencia; confía plenamente en la respuesta del servidor.
- **Dispositivos objetivo**: La aplicación está orientada principalmente al sistema operativo Android (ejecución demostrable en emulador de Android Studio y/o dispositivo físico Android con cámara funcional).
- **Alcance móvil restringido**: Las operaciones de creación de cursos, programación de sesiones, generación y proyección del código QR en pantalla grande corresponden al panel web administrativo/instructor y están fuera del alcance de este repositorio.
- **Conectividad a la red y modelo online-first**: El estudiante cuenta con acceso a internet para comunicarse con la API durante la navegación y registro de asistencia. La aplicación opera con un modelo estrictamente en línea (*online-first*) para el MVP E2; el almacenamiento persistente local se reserva para el token de sesión y la configuración de URL, gestionando caídas de red mediante mensajes de error y opciones de reintento en pantalla sin persistir bases de datos locales offline.
