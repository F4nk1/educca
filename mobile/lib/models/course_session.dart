/// Estado de asistencia de una sesión programada.
enum SessionAttendanceStatus {
  scheduled, // Programada, asistencia no habilitada
  open,      // Asistencia abierta y QR proyectándose
  closed,    // Asistencia concluida
}

/// Modelo de una sesión programada dentro de una capacitación.
class CourseSession {
  final String id;
  final String courseId;
  final String title;
  final DateTime scheduledDate;
  final String startTime;
  final String endTime;
  final String location;
  final SessionAttendanceStatus attendanceStatus;

  const CourseSession({
    required this.id,
    required this.courseId,
    required this.title,
    required this.scheduledDate,
    required this.startTime,
    required this.endTime,
    required this.location,
    required this.attendanceStatus,
  });

  bool get isAttendanceOpen => attendanceStatus == SessionAttendanceStatus.open;

  factory CourseSession.fromJson(Map<String, dynamic> json) {
    SessionAttendanceStatus parseStatus(dynamic raw) {
      final str = raw?.toString().toUpperCase();
      switch (str) {
        case 'OPEN':
        case 'EN_CURSO':
          return SessionAttendanceStatus.open;
        case 'CLOSED':
        case 'CONCLUIDA':
        case 'VALIDADA':
        case 'CANCELADA':
          return SessionAttendanceStatus.closed;
        default:
          return SessionAttendanceStatus.scheduled;
      }
    }

    DateTime parseDate(dynamic value) {
      if (value == null) return DateTime.now();
      return DateTime.tryParse(value.toString()) ?? DateTime.now();
    }

    final rawId = json['id'] ?? json['sesion_id'];
    final idStr = rawId != null ? rawId.toString() : '';

    final rawCourseId = json['courseId'] ?? json['meta_anual_id'] ?? idStr;
    final courseIdStr = rawCourseId.toString();

    final title = json['title'] as String? ?? json['titulo'] as String? ?? 'Sesión formativa';
    final date = parseDate(json['scheduledDate'] ?? json['fecha_inicio']);

    String startStr = json['startTime'] as String? ?? '';
    if (startStr.isEmpty) {
      startStr = '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    }

    String endStr = json['endTime'] as String? ?? '';
    if (endStr.isEmpty && json['duracion_minutos'] != null) {
      final mins = int.tryParse(json['duracion_minutos'].toString()) ?? 120;
      final endDate = date.add(Duration(minutes: mins));
      endStr = '${endDate.hour.toString().padLeft(2, '0')}:${endDate.minute.toString().padLeft(2, '0')}';
    }

    final locationStr = json['location'] as String? ??
        (json['modalidad'] != null ? 'Modalidad ${json['modalidad']}' : 'Sede Presencial');

    final rawStatus = json['attendanceStatus'] ?? json['estado'] ?? json['estado_sesion'];

    return CourseSession(
      id: idStr,
      courseId: courseIdStr,
      title: title,
      scheduledDate: date,
      startTime: startStr,
      endTime: endStr,
      location: locationStr,
      attendanceStatus: parseStatus(rawStatus),
    );
  }
}
