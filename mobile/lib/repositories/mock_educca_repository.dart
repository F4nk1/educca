import '../core/result.dart';
import '../models/attendance_models.dart';
import '../models/location_capture.dart';
import 'educca_repository.dart';

/// Repositorio simulado para pruebas locales e independientes en modo debug y demostración.
///
/// Principio: Cero persistencia real ni conexión externa; devuelve respuestas
/// deterministas para evaluar interfaces y casos extremos sin depender del backend.
/// Todos los registros se identifican explícitamente como "Datos de demostración".
class MockEduccaRepository implements EduccaRepository {
  final List<AttendanceRecord> _mockHistory = [];
  ScanOutcome? _forcedOutcome;

  MockEduccaRepository() {
    _initializeDefaultHistory();
  }

  void _initializeDefaultHistory() {
    _mockHistory.clear();
    _mockHistory.add(
      AttendanceRecord(
        id: 'mock-att-001',
        sessionId: 'mock-ses-101',
        sessionTitle: 'Taller: Segregación en la Fuente',
        courseTitle: 'Gestión Ambiental EDUCCA Cusco (Datos de demostración)',
        venueName: 'Local Comunal San Pedro - Cusco (Simulado)',
        markedAt: DateTime.now().subtract(const Duration(days: 2)),
        status: 'CONFIRMED',
      ),
    );
  }

  /// Restablece el historial simulado al estado inicial.
  void resetMockHistory() {
    _forcedOutcome = null;
    _initializeDefaultHistory();
  }

  /// Permite forzar un resultado específico para el Recorrido de Demostración.
  void forceOutcome(ScanOutcome? outcome) {
    _forcedOutcome = outcome;
  }

  @override
  Future<Result<dynamic>> login(String email, String password) async {
    await Future.delayed(const Duration(milliseconds: 600));

    if (password.length < 4) {
      return Result.failure(
        'Credenciales inválidas. Verifica tu correo y contraseña.',
        statusCode: 401,
      );
    }

    return Result.success({
      'token': 'mock_jwt_token_educca_demo_2026',
      'user': {
        'id': 'prom-demo-01',
        'fullName': 'María Quispe (Modo Demo)',
        'email': email.trim().toLowerCase(),
        'role': 'PROMOTOR',
        'promoterCategory': 'JUVENIL',
        'isAdult': true,
        'privacyConsentAccepted': true,
      },
    });
  }

  @override
  Future<Result<dynamic>> registerPromoter({
    required String fullName,
    required String email,
    required String password,
    required String promoterCategory,
    required bool isAdult,
    required bool privacyConsentAccepted,
  }) async {
    await Future.delayed(const Duration(milliseconds: 700));

    if (email.contains('existe@')) {
      return Result.failure(
        'El correo electrónico ya se encuentra registrado en el sistema.',
        statusCode: 409,
      );
    }

    return Result.success({
      'status': 'CREATED',
      'message': 'Promotor registrado correctamente (Simulación)',
      'user': {
        'id': 'prom-mock-${DateTime.now().millisecondsSinceEpoch}',
        'fullName': fullName,
        'email': email,
        'role': 'PROMOTOR',
        'promoterCategory': promoterCategory,
        'isAdult': isAdult,
        'privacyConsentAccepted': privacyConsentAccepted,
      },
    });
  }

  @override
  Future<AttendanceScanResult> scanAttendance({
    required String qrToken,
    required LocationCapture location,
  }) async {
    await Future.delayed(const Duration(milliseconds: 800));

    // Si hay un escenario forzado para demostración, aplicarlo
    final outcome = _forcedOutcome;
    _forcedOutcome = null; // un solo disparo

    if (outcome != null) {
      switch (outcome) {
        case ScanOutcome.outOfRange:
          return const AttendanceScanResult(
            outcome: ScanOutcome.outOfRange,
            message: 'No estás dentro del área de asistencia autorizada para esta sede (distancia > 80 m).',
          );
        case ScanOutcome.expired:
          return const AttendanceScanResult(
            outcome: ScanOutcome.expired,
            message: 'El código QR ha expirado. Solicita al capacitador que proyecte el código actualizado.',
          );
        case ScanOutcome.duplicate:
          return AttendanceScanResult(
            outcome: ScanOutcome.duplicate,
            message: 'Tu asistencia ya fue registrada previamente para esta sesión (Datos de demostración).',
            record: _mockHistory.isNotEmpty ? _mockHistory.first : null,
          );
        case ScanOutcome.sessionClosed:
          return const AttendanceScanResult(
            outcome: ScanOutcome.sessionClosed,
            message: 'El periodo de asistencia para esta sesión ambiental ha concluido.',
          );
        case ScanOutcome.unauthorized:
          return const AttendanceScanResult(
            outcome: ScanOutcome.unauthorized,
            message: 'No te encuentras inscrito en el taller ambiental correspondiente a esta sede.',
          );
        case ScanOutcome.networkError:
          return const AttendanceScanResult(
            outcome: ScanOutcome.networkError,
            message: 'Sin conexión con el servidor. Verifica tu señal o IP.',
          );
        case ScanOutcome.permissionDenied:
          return const AttendanceScanResult(
            outcome: ScanOutcome.permissionDenied,
            message: 'Se denegó el permiso de ubicación en el dispositivo.',
          );
        case ScanOutcome.locationInaccurate:
          return const AttendanceScanResult(
            outcome: ScanOutcome.locationInaccurate,
            message: 'La precisión GPS actual es insuficiente (> 50 m). Acércate a un espacio despejado.',
          );
        default:
          break;
      }
    }

    final upper = qrToken.toUpperCase();

    // Palabras clave de simulación por token
    if (upper.contains('FAR') || upper.contains('OUT') || upper.contains('DISTANCIA')) {
      return const AttendanceScanResult(
        outcome: ScanOutcome.outOfRange,
        message: 'No estás dentro del área de asistencia autorizada para esta sede (distancia > 80 m).',
      );
    }

    if (upper.contains('EXP') || upper.contains('VENCID')) {
      return const AttendanceScanResult(
        outcome: ScanOutcome.expired,
        message: 'El código QR ha expirado. Solicita al capacitador que proyecte el código actualizado.',
      );
    }

    if (upper.contains('DUP') || upper.contains('YA')) {
      return AttendanceScanResult(
        outcome: ScanOutcome.duplicate,
        message: 'Tu asistencia ya fue registrada previamente para esta sesión (Datos de demostración).',
        record: _mockHistory.isNotEmpty ? _mockHistory.first : null,
      );
    }

    if (upper.contains('CLOSED') || upper.contains('CERRAD')) {
      return const AttendanceScanResult(
        outcome: ScanOutcome.sessionClosed,
        message: 'El periodo de asistencia para esta sesión ambiental ha concluido.',
      );
    }

    if (upper.contains('UNAUTH') || upper.contains('NO_INSCRITO')) {
      return const AttendanceScanResult(
        outcome: ScanOutcome.unauthorized,
        message: 'No te encuentras inscrito en el taller ambiental correspondiente a esta sede.',
      );
    }

    if (upper.contains('ERROR') || upper.contains('NET')) {
      return const AttendanceScanResult(
        outcome: ScanOutcome.networkError,
        message: 'Sin conexión con el servidor. Verifica tu señal o IP.',
      );
    }

    // Identificador de la sesión objetivo de la demostración
    const demoSessionId = 'ses-educca-301';

    // REGLA CLAVE DE DEMOSTRACIÓN CONSISTENTE:
    // Si la sesión ya fue registrada en el historial durante esta ejecución,
    // devolver ScanOutcome.duplicate determinista.
    final alreadyRegistered = _mockHistory.any((r) => r.sessionId == demoSessionId);
    if (alreadyRegistered) {
      final existingRecord = _mockHistory.firstWhere((r) => r.sessionId == demoSessionId);
      return AttendanceScanResult(
        outcome: ScanOutcome.duplicate,
        message: 'Tu asistencia ya fue registrada previamente para esta sesión (Datos de demostración).',
        record: existingRecord,
      );
    }

    // Primer escaneo exitoso: crear constancia simulada
    final newRecord = AttendanceRecord(
      id: 'mock-att-${DateTime.now().millisecondsSinceEpoch}',
      sessionId: demoSessionId,
      sessionTitle: 'Taller: Segregación en la fuente',
      courseTitle: 'Educación Ambiental EDUCCA Cusco (Datos de demostración)',
      venueName: 'Centro Cultural Cusco (Simulación ≤ 80 m)',
      markedAt: DateTime.now(),
      status: 'CONFIRMED',
    );

    _mockHistory.insert(0, newRecord);

    return AttendanceScanResult(
      outcome: ScanOutcome.success,
      message: '¡Asistencia registrada y validada presencialmente en sede! (Datos de demostración)',
      record: newRecord,
    );
  }

  @override
  Future<Result<dynamic>> getPromoterSessions() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return Result.success([
      {
        'id': 'taller-01',
        'title': 'Segregación en la fuente',
        'description': 'Manejo adecuado y separación de residuos sólidos urbanos en Cusco.',
        'instructorName': 'Capacitador Ambiental EDUCCA',
        'venueName': 'Centro Cultural Cusco',
        'startDate': DateTime.now().toIso8601String(),
        'endDate': DateTime.now().add(const Duration(days: 30)).toIso8601String(),
        'status': 'ACTIVE',
      },
      {
        'id': 'taller-02',
        'title': 'Compostaje comunitario y biohuertos',
        'description': 'Técnicas de valorización de residuos orgánicos en San Pedro.',
        'instructorName': 'Especialista en Agroecología',
        'venueName': 'Local Comunal San Pedro',
        'startDate': DateTime.now().toIso8601String(),
        'endDate': DateTime.now().add(const Duration(days: 45)).toIso8601String(),
        'status': 'ACTIVE',
      },
    ]);
  }

  @override
  Future<Result<dynamic>> getAttendanceHistory() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return Result.success(_mockHistory.map((r) => r.toJson()).toList());
  }
}
