# EDUCCA Cusco — Estado de Integración Móvil y Pendientes con Backend Go

**Fecha**: 2026-11-17  
**Responsable Móvil**: Antigravity / Flutter Android  
**Responsable Backend**: Dev 1 (Go + PostgreSQL)  
**Estado General**: Cliente móvil Flutter completado con soporte para API real y repositorio simulado (`MockEduccaRepository`) en debug.

---

## 1. Puntos Homologados en el Cliente Móvil

1. **Roles y Categorías de Promotores (HU-01 / RF-01):**
   * El cliente implementa el registro exclusivo de promotores (`PROMOTOR`) en categorías: `ESCOLAR`, `JUVENIL` y `COMUNITARIO`.
   * El cliente contiene preventivamente el autorregistro de escolares menores de edad (Opción A de aclaración), permitiendo el registro autónomo solo a mayores de edad con consentimiento informado explícito.
2. **Captura Puntual de Ubicación GPS (HU-04 / RF-06 / RNF-01):**
   * Se adquiere ubicación exclusivamente en el instante del escaneo del QR con un timeout de 10 segundos y un filtro de precisión de ≤ 50 metros.
   * La aplicación descarta las coordenadas de memoria inmediatamente tras el envío y no mantiene rastreo en background (`ACCESS_BACKGROUND_LOCATION` excluido de `AndroidManifest.xml`).
3. **Cálculo de Distancia de 80 m:**
   * La aplicación móvil delega el cálculo geodésico y el veredicto final al backend Go contra la sede registrada en PostgreSQL.
   * La app procesa las respuestas del servidor para éxito (`RECORDED`), fuera de radio (`OUT_OF_RANGE`), duplicado (`ALREADY_RECORDED`), sesión cerrada y QR expirado.
4. **Modo Demostración en Debug:**
   * Alternable en caliente desde el diálogo de ajustes de servidor en login.
   * Presenta permanentemente el distintivo visual `«MODO DEMOSTRACIÓN — DATOS SIMULADOS»` en la barra superior.

---

## 2. Pruebas de Integración Pendientes con Backend Go (Dev 1)

Las siguientes pruebas end-to-end están bloqueadas hasta que Dev 1 despliegue la API en el entorno local o de pruebas:

| Código | Prueba de Integración | Precondición Backend Go | Estado |
|---|---|---|:---:|
| **INT-01** | Registro de Promotor en PostgreSQL | Endpoint `POST /auth/register` operativo con inserción en tabla de promotores | Pendiente Dev 1 |
| **INT-02** | Login y emisión de JWT | Endpoint `POST /auth/login` validando hash de contraseña y emitiendo Bearer token | Pendiente Dev 1 |
| **INT-03** | Escaneo QR presencial dentro de 80 m | Endpoint `POST /attendance/scan` validando sesión abierta y cálculo de radio ≤ 80 m | Pendiente Dev 1 |
| **INT-04** | Rechazo por distancia > 80 m | Endpoint `POST /attendance/scan` calculando distancia a la sede y respondiendo `OUT_OF_RANGE` | Pendiente Dev 1 |
| **INT-05** | Idempotencia / Detección de duplicado | Base de datos rechazando segundo marcado para el mismo promotor y sesión | Pendiente Dev 1 |
| **INT-06** | Expiración de QR emitido por HU-03 | Capacitador proyectando QR dinámico con caducidad real | Pendiente Dev 1 |
