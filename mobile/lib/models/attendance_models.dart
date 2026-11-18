/// Resultado categorizado del intento de escaneo de QR y registro de asistencia presencial.
enum ScanOutcome {
  success,             // 200/201: Asistencia confirmada en radio <= 80 m
  duplicate,           // 409/ALREADY_RECORDED: Asistencia ya registrada previamente
  outOfRange,          // 400/OUT_OF_RANGE: Distancia desde la sede > 80 m
  expired,             // 410/QR_EXPIRED: Token QR caducado
  invalid,             // 404/422/QR_INVALID: Token corrupto o irreconocible
  sessionClosed,       // 400/SESSION_CLOSED: Sesión cerrada
  unauthorized,        // 403/NOT_ENROLLED: Promotor no inscrito en la actividad
  permissionDenied,    // Error local: Permiso de ubicación denegado en el dispositivo
  gpsDisabled,         // Error local: Sensor GPS apagado en el teléfono
  locationInaccurate,  // Error local: Imprecisión GPS > 50 m
  gpsTimeout,          // Error local: Timeout de 10 s al adquirir coordenadas
  networkError,        // Fallo de red / timeout de comunicación
}

/// Constancia de una asistencia validada por el servidor.
class AttendanceRecord {
  final String id;
  final String sessionId;
  final String sessionTitle;
  final String courseTitle;
  final String venueName;
  final DateTime markedAt;
  final String status;

  const AttendanceRecord({
    required this.id,
    required this.sessionId,
    required this.sessionTitle,
    required this.courseTitle,
    this.venueName = 'Sede EDUCCA Cusco',
    required this.markedAt,
    required this.status,
  });

  factory AttendanceRecord.fromJson(Map<String, dynamic> json) {
    DateTime parseDate(dynamic value) {
      if (value == null) return DateTime.now();
      return DateTime.tryParse(value.toString()) ?? DateTime.now();
    }

    final sessionMap = json['session'] is Map ? json['session'] as Map<String, dynamic> : null;

    final rawSesionId = json['sessionId'] ?? json['sesion_id'] ?? sessionMap?['id'];
    final sesIdStr = rawSesionId != null ? rawSesionId.toString() : '';

    final idStr = json['id'] as String? ??
        json['attendanceId'] as String? ??
        (sesIdStr.isNotEmpty ? 'att-$sesIdStr' : '');

    final title = json['sessionTitle'] as String? ??
        json['titulo'] as String? ??
        sessionMap?['title'] as String? ??
        'Sesión formativa';

    final course = json['courseTitle'] as String? ??
        (json['eje_tematico'] != null ? 'Eje: ${json['eje_tematico']}' : null) ??
        sessionMap?['title'] as String? ??
        'Taller Ambiental EDUCCA';

    String venue = json['venueName'] as String? ?? sessionMap?['venueName'] as String? ?? '';
    if (venue.isEmpty) {
      if (json['distancia_metros'] != null) {
        final mod = json['modalidad']?.toString() ?? 'PRESENCIAL';
        venue = 'Sede $mod (${json['distancia_metros']} m)';
      } else {
        venue = 'Sede EDUCCA Cusco';
      }
    }

    final statusStr = json['status'] as String? ??
        json['participacion'] as String? ??
        'CONFIRMED';

    return AttendanceRecord(
      id: idStr,
      sessionId: sesIdStr,
      sessionTitle: title,
      courseTitle: course,
      venueName: venue,
      markedAt: parseDate(json['markedAt'] ?? json['recordedAt'] ?? json['registrado_at']),
      status: statusStr,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'sessionId': sessionId,
    'sessionTitle': sessionTitle,
    'courseTitle': courseTitle,
    'venueName': venueName,
    'markedAt': markedAt.toIso8601String(),
    'status': status,
  };
}

/// DTO con la respuesta devuelta por el servidor tras escanear un QR.
class AttendanceScanResult {
  final ScanOutcome outcome;
  final String message;
  final AttendanceRecord? record;

  const AttendanceScanResult({
    required this.outcome,
    required this.message,
    this.record,
  });

  bool get isSuccess => outcome == ScanOutcome.success;
  bool get isDuplicate => outcome == ScanOutcome.duplicate;
  bool get isOutOfRange => outcome == ScanOutcome.outOfRange;
  bool get isExpired => outcome == ScanOutcome.expired;
}
