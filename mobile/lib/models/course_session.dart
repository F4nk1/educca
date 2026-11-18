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
          return SessionAttendanceStatus.open;
        case 'CLOSED':
          return SessionAttendanceStatus.closed;
        default:
          return SessionAttendanceStatus.scheduled;
      }
    }

    DateTime parseDate(dynamic value) {
      if (value == null) return DateTime.now();
      return DateTime.tryParse(value.toString()) ?? DateTime.now();
    }

    return CourseSession(
      id: json['id'] as String? ?? '',
      courseId: json['courseId'] as String? ?? '',
      title: json['title'] as String? ?? 'Sesión formativa',
      scheduledDate: parseDate(json['scheduledDate']),
      startTime: json['startTime'] as String? ?? '',
      endTime: json['endTime'] as String? ?? '',
      location: json['location'] as String? ?? 'Modalidad Presencial',
      attendanceStatus: parseStatus(json['attendanceStatus']),
    );
  }
}
