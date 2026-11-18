import 'package:flutter_test/flutter_test.dart';
import 'package:sistema_capacitaciones/models/student_user.dart';

void main() {
  group('StudentUser Model Tests', () {
    test('StudentUser parses valid JSON with fullName correctly', () {
      final json = {
        'id': 'usr-100',
        'fullName': 'Ana Quispe',
        'email': 'ana@universidad.edu.pe',
        'role': 'STUDENT',
      };

      final user = StudentUser.fromJson(json);
      expect(user.id, 'usr-100');
      expect(user.fullName, 'Ana Quispe');
      expect(user.email, 'ana@universidad.edu.pe');
      expect(user.role, 'STUDENT');
    });

    test('StudentUser falls back to "name" key if "fullName" is missing', () {
      final json = {
        'id': 'usr-101',
        'name': 'Carlos Mendoza',
        'email': 'carlos@universidad.edu.pe',
      };

      final user = StudentUser.fromJson(json);
      expect(user.fullName, 'Carlos Mendoza');
      expect(user.role, 'STUDENT');
    });

    test('StudentUser toJson produces consistent map', () {
      const user = StudentUser(
        id: 'usr-102',
        fullName: 'Lucía Torres',
        email: 'lucia@universidad.edu.pe',
        role: 'STUDENT',
      );

      final map = user.toJson();
      expect(map['id'], 'usr-102');
      expect(map['fullName'], 'Lucía Torres');
      expect(map['email'], 'lucia@universidad.edu.pe');
    });
  });
}
