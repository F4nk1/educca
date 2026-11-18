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

    return Course(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? 'Capacitación sin título',
      description: json['description'] as String?,
      instructorName: json['instructorName'] as String? ??
          json['instructor'] as String? ??
          'Docente asignado',
      startDate: parseDate(json['startDate']),
      endDate: parseDate(json['endDate']),
      status: json['status'] as String? ?? 'ACTIVE',
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
