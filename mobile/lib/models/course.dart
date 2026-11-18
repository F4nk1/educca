/// Modelo de una capacitación o curso en el que está inscrito el estudiante.
class Course {
  final String id;
  final String title;
  final String? description;
  final String instructorName;
  final DateTime startDate;
  final DateTime endDate;
  final String status;

  const Course({
    required this.id,
    required this.title,
    this.description,
    required this.instructorName,
    required this.startDate,
    required this.endDate,
    required this.status,
  });

  factory Course.fromJson(Map<String, dynamic> json) {
    DateTime parseDate(dynamic value) {
      if (value == null) return DateTime.now();
      return DateTime.tryParse(value.toString()) ?? DateTime.now();
    }

    final rawId = json['id'] ?? json['sesion_id'];
    final idStr = rawId != null ? rawId.toString() : '';

    final title = json['title'] as String? ??
        json['titulo'] as String? ??
        'Capacitación sin título';

    final description = json['description'] as String? ??
        json['eje_tematico'] as String? ??
        json['modalidad'] as String?;

    final instructor = json['instructorName'] as String? ??
        json['instructor'] as String? ??
        (json['responsable_id'] != null ? 'Capacitador #${json['responsable_id']}' : 'Docente asignado');

    final start = parseDate(json['startDate'] ?? json['fecha_inicio']);

    DateTime end;
    if (json['endDate'] != null) {
      end = parseDate(json['endDate']);
    } else if (json['duracion_minutos'] != null) {
      final mins = int.tryParse(json['duracion_minutos'].toString()) ?? 120;
      end = start.add(Duration(minutes: mins));
    } else {
      end = start.add(const Duration(hours: 2));
    }

    final status = json['status'] as String? ??
        json['estado'] as String? ??
        json['estado_sesion'] as String? ??
        'ACTIVE';

    return Course(
      id: idStr,
      title: title,
      description: description,
      instructorName: instructor,
      startDate: start,
      endDate: end,
      status: status,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'description': description,
    'instructorName': instructorName,
    'startDate': startDate.toIso8601String(),
    'endDate': endDate.toIso8601String(),
    'status': status,
  };
}
