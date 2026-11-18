import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:sistema_capacitaciones/config/app_config.dart';
import 'package:sistema_capacitaciones/core/api_client.dart';
import 'package:sistema_capacitaciones/core/session_storage.dart';
import 'package:sistema_capacitaciones/main.dart';
import 'package:sistema_capacitaciones/providers/attendance_provider.dart';
import 'package:sistema_capacitaciones/providers/auth_provider.dart';
import 'package:sistema_capacitaciones/providers/courses_provider.dart';

class MockSessionStorage extends SessionStorage {
  @override
  Future<String?> getToken() async => null;
  @override
  Future<String?> getUserJson() async => null;
  @override
  Future<void> saveToken(String token) async {}
  @override
  Future<void> saveUserJson(String userJson) async {}
  @override
  Future<void> clearSession() async {}
}

void main() {
  testWidgets('App renders login screen by default when not authenticated', (tester) async {
    final config = AppConfig();
    final storage = MockSessionStorage();
    final apiClient = ApiClient(config: config, sessionStorage: storage);
    final authProvider = AuthProvider(apiClient: apiClient, sessionStorage: storage);
    final coursesProvider = CoursesProvider(apiClient: apiClient);
    final attendanceProvider = AttendanceProvider(apiClient: apiClient);

    await authProvider.checkAuthStatus();

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<AppConfig>.value(value: config),
          ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
          ChangeNotifierProvider<CoursesProvider>.value(value: coursesProvider),
          ChangeNotifierProvider<AttendanceProvider>.value(value: attendanceProvider),
        ],
        child: const SistemaCapacitacionesApp(),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('EDUCCA Cusco'), findsOneWidget);
    expect(find.text('Portal del Promotor Ambiental'), findsOneWidget);
    expect(find.byKey(const Key('emailField')), findsOneWidget);
    expect(find.byKey(const Key('passwordField')), findsOneWidget);
  });
}
