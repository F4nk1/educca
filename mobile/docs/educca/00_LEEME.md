# EDUCCA Cusco — Paquete de adaptación móvil con Spec Kit

**Versión de trabajo:** 1.0 · **Fecha:** 2026-11-17  
**Producto:** app Android Flutter/Dart para promotores ambientales del Programa Municipal EDUCCA de la Gerencia de Medio Ambiente y Servicios Públicos de Cusco.  
**Naturaleza:** insumo de planificación y desarrollo; **no** equivale a backlog aprobado, implementación completa ni evidencias de cumplimiento.

## Autoridad de fuentes

1. **Product Backlog del Product Owner / Jira y el PDF académico del equipo:** fuente de verdad de alcance, prioridad y puntos (HU-01 a HU-12 y RNF-01). No sustituir ni renumerar.
2. **Archivo `01_ESPECIFICACION_CAMBIO_SPRINT1.md`:** traducción de los compromisos del Sprint 1 a comportamientos móviles y pruebas verificables. Los detalles no definidos por el documento están marcados como **PROPUESTA / PENDIENTE DE PO**.
3. **Archivo `02_CONTRATO_API_PENDIENTE.md`:** propuesta de integración con el backend, **no** contrato acordado ni endpoints ya disponibles.
4. **Código Flutter existente y `specs/001-mobile-training-mvp/`:** referencia técnica sobre lo ya construido. Conservar, auditar y reutilizar; no tratar la especificación previa como autoridad funcional si contradice EDUCCA.
5. **Figma:** referencia visual; no cambia una historia de usuario ni sus criterios de aceptación.

## Alcance Sprint 1 (Jira)

| Item Jira | Puntos | Dueño primario | Impacto en Flutter |
|---|---:|---|---|
| HU-01 · RF-01: registro e inicio de sesión | 3 | móvil + backend | **Directo:** registro, login, perfil promotor, consentimiento y errores |
| HU-02 · RF-02: gestión de sedes y talleres | 5 | web + backend | **Indirecto:** consumir sede, sesión, coordenadas y horario cuando se provean |
| HU-03 · RF-05: generar QR por sesión | 5 | web + backend | **Indirecto:** lector compatible con el token emitido, no generar QR desde móvil |
| HU-04 · RF-06: escaneo QR + GPS ≤80 m | 8 | móvil + backend | **Directo:** cámara, permisos puntuales, envío de ubicación, resultados |
| RNF-01: seguridad, LPDP y geolocalización puntual | 5 | transversal | **Directo:** UX de consentimiento, almacenamiento seguro, sin rastreo continuo |
| **Total Sprint 1** | **26** | equipo | **No equivale a 26 SP de trabajo móvil** |

El PDF del equipo fija tres sprints proyectados: 1 (semanas 1–3), 2 (semanas 4–6) y 3 (semanas 7–9). El entregable del curso en semana 6 exige al menos 50 % de funcionamiento con autenticación, gestión de cursos/usuarios y QR móvil. El Sprint 1 no es lo mismo que toda la entrega 2.

## Qué conservar del MVP móvil existente

- Flutter, pantallas existentes, organización `lib/config`, `lib/core`, `lib/models`, `lib/providers`, `lib/screens`.
- Cliente HTTP con token, manejo de 401, almacenamiento seguro, manejo de loading/vacío/error.
- Escaneo `mobile_scanner`, protección antirráfaga, configuración de URL del backend solo para desarrollo.
- UI y pruebas existentes que sigan siendo pertinentes.

## Qué cambiar ahora

1. De alumno genérico a **promotor ambiental** con categoría `escolar / juvenil / comunitario` definida por backend.
2. Añadir **registro** y consentimiento (HU-01), sin inventar políticas legales definitivas para menores.
3. Pasar de **QR sin GPS** a **QR + lectura GPS puntual**; servidor decide radio de 80 m y si registra.
4. Adaptar textos de dominio: sede/punto de intervención, taller ambiental, sesión, promotor, capacitador.
5. Integrar contratos reales del equipo cuando estén listos, o habilitar **mock de demostración solo en debug claramente identificado**.

## Qué posponer

- HU-06: catálogo abierto, autoinscripción y consulta de calificaciones (Sprint 2 o posterior, según PO). Conservar pantallas previas sin declararlas terminadas.
- HU-05 materiales, HU-07 evaluaciones, HU-08 certificados, HU-09 verificación, HU-10 tablero, HU-11 recordatorios, HU-12 alertas.
- Implementación del panel web, generador QR, servidor y BD en este repositorio móvil.

## Secuencia recomendada

1. Copiar `01_ESPECIFICACION_CAMBIO_SPRINT1.md` y `02_CONTRATO_API_PENDIENTE.md` dentro de `docs/educca/` de tu repositorio.
2. Leer y ejecutar `03_GUIA_SPEC_KIT_ANTIGRAVITY.md` **en orden**; no reinitializar Spec Kit.
3. Verificar pruebas con `04_CHECKLIST_QA_EVIDENCIAS.md`.
4. Usar `05_PROMPT_FIGMA_MCP.md` con otra IA conectada al MCP de Figma para diseñar y revisar las interfaces.

**Importante:** si el Product Owner modifica un item en Jira, primero registrar la decisión y actualizar la fuente del cambio. No modificar las historias del PO para acomodarlas al código existente.
