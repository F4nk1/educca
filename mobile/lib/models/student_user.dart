/// Modelo del estudiante autenticado en la aplicación móvil.
class StudentUser {
  final String id;
  final String fullName;
  final String email;
  final String role;

  const StudentUser({
    required this.id,
    required this.fullName,
    required this.email,
    required this.role,
  });

  factory StudentUser.fromJson(Map<String, dynamic> json) {
    return StudentUser(
      id: json['id'] as String? ?? '',
      fullName: json['fullName'] as String? ?? json['name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      role: json['role'] as String? ?? 'STUDENT',
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'fullName': fullName,
    'email': email,
    'role': role,
  };
}
