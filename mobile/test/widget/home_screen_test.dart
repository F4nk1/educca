import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:provider/provider.dart';
import 'package:sistema_capacitaciones/config/app_config.dart';
import 'package:sistema_capacitaciones/core/api_client.dart';
import 'package:sistema_capacitaciones/core/session_storage.dart';
import 'package:sistema_capacitaciones/providers/attendance_provider.dart';
import 'package:sistema_capacitaciones/providers/auth_provider.dart';
import 'package:sistema_capacitaciones/providers/courses_provider.dart';
import 'package:sistema_capacitaciones/screens/home_screen.dart';

class MockSessionStorage extends SessionStorage {
  @override
  Future<String?> getToken() async => 'mock_token_123';

  @override
  Future<String?> getUserJson() async => jsonEncode({
        'id': 'prom-01',
        'fullName': 'María Quispe',
        'email': 'maria@cusco.gob.pe',
        'role': 'PROMOTOR',
        'promoterCategory': 'JUVENIL',
        'isAdult': true,
        'privacyConsentAccepted': true,
      });

  @override
  Future<void> saveToken(String token) async {}

  @override
  Future<void> saveUserJson(String userJson) async {}

  @override
  Future<void> clearSession() async {}
}

void main() {
  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  Widget createHomeScreen(AuthProvider authProvider, CoursesProvider coursesProvider, AttendanceProvider attendanceProvider) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AppConfig>.value(value: AppConfig()),
        ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
        ChangeNotifierProvider<CoursesProvider>.value(value: coursesProvider),
        ChangeNotifierProvider<AttendanceProvider>.value(value: attendanceProvider),
      ],
      child: const MaterialApp(
        home: HomeScreen(),
      ),
    );
  }

  testWidgets('HomeScreen M03 renders Andean elements, promoter greeting and quick scan button', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    final mockHttp = MockClient((request) async {
      return http.Response(jsonEncode([]), 200);
    });

    final storage = MockSessionStorage();
    final client = ApiClient(config: AppConfig(), sessionStorage: storage, httpClient: mockHttp);
    final auth = AuthProvider(apiClient: client, sessionStorage: storage);
    final courses = CoursesProvider(apiClient: client);
    final attendance = AttendanceProvider(apiClient: client);

    await auth.checkAuthStatus();

    await tester.pumpWidget(createHomeScreen(auth, courses, attendance));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // Verification of M03 Andean design elements
    expect(find.text('EDUCCA Cusco'), findsOneWidget);
    expect(find.text('Allin hamuy,'), findsOneWidget);
    expect(find.text('María'), findsOneWidget);
    expect(find.textContaining('PROMOTOR'), findsOneWidget);
    expect(find.text('Tu próxima actividad ambiental'), findsOneWidget);
    expect(find.text('PRÓXIMA ACTIVIDAD'), findsOneWidget);
    expect(find.byKey(const Key('quickScanButton')), findsOneWidget);
    expect(find.text('ACCESOS RÁPIDOS'), findsOneWidget);
    expect(find.text('Mis talleres'), findsWidgets);
    expect(find.text('Mis asistencias'), findsWidgets);

    // Verify 4 tabs of bottom navigation
    expect(find.text('Inicio'), findsOneWidget);
    expect(find.text('Talleres'), findsOneWidget);
    expect(find.text('Asistencias'), findsOneWidget);
    expect(find.text('Perfil'), findsOneWidget);

    // Tap on 'Perfil' tab
    await tester.tap(find.text('Perfil'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('Cerrar Sesión'), findsOneWidget);

    // Tap back to 'Inicio' tab
    await tester.tap(find.text('Inicio'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.byKey(const Key('quickScanButton')), findsOneWidget);
  });
}
