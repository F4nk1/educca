import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:sistema_capacitaciones/config/app_config.dart';
import 'package:sistema_capacitaciones/core/api_client.dart';
import 'package:sistema_capacitaciones/core/session_storage.dart';
import 'package:sistema_capacitaciones/models/attendance_models.dart';
import 'package:sistema_capacitaciones/models/location_capture.dart';
import 'package:sistema_capacitaciones/providers/attendance_provider.dart';
import 'package:sistema_capacitaciones/providers/auth_provider.dart';
import 'package:sistema_capacitaciones/providers/courses_provider.dart';
import 'package:sistema_capacitaciones/repositories/mock_educca_repository.dart';
import 'package:sistema_capacitaciones/screens/attendance_result_screen.dart';
import 'package:sistema_capacitaciones/screens/location_consent_screen.dart';
import 'package:sistema_capacitaciones/screens/qr_scanner_screen.dart';
import 'package:sistema_capacitaciones/screens/verification_screen.dart';

void main() {
  late AppConfig appConfig;
  late MockEduccaRepository mockRepo;
  late SessionStorage sessionStorage;
  late ApiClient apiClient;
  late AuthProvider authProvider;
  late CoursesProvider coursesProvider;
  late AttendanceProvider attendanceProvider;

  setUp(() {
    appConfig = AppConfig(initialDemoMode: true);
    mockRepo = MockEduccaRepository();
    sessionStorage = SessionStorage();
    apiClient = ApiClient(config: appConfig, sessionStorage: sessionStorage);
    authProvider = AuthProvider(
      apiClient: apiClient,
      sessionStorage: sessionStorage,
      repository: mockRepo,
    );
    coursesProvider = CoursesProvider(
      apiClient: apiClient,
      repository: mockRepo,
    );
    attendanceProvider = AttendanceProvider(
      apiClient: apiClient,
      repository: mockRepo,
    );
  });

  Widget createTestWidget(Widget child) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AppConfig>.value(value: appConfig),
        ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
        ChangeNotifierProvider<CoursesProvider>.value(value: coursesProvider),
        ChangeNotifierProvider<AttendanceProvider>.value(value: attendanceProvider),
      ],
      child: MaterialApp(
        home: child,
      ),
    );
  }

  group('M04: QrScannerScreen Tests', () {
    testWidgets('renders Andean header, title and simulate scan button in demo mode', (tester) async {
      await tester.pumpWidget(createTestWidget(const QrScannerScreen()));
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('REGISTRO DE ASISTENCIA'), findsOneWidget);
      expect(find.text('Escanear código QR'), findsOneWidget);
      expect(find.byKey(const Key('simulateScanButton')), findsOneWidget);
      expect(find.text('Volver'), findsOneWidget);
    });
  });

  group('M05: LocationConsentScreen Tests', () {
    testWidgets('renders GPS privacy explanation, 80m disclosure and action buttons', (tester) async {
      await tester.pumpWidget(createTestWidget(const LocationConsentScreen(
        qrToken: 'EDUCCA-SES-301-DEMO',
      )));
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('PRIVACIDAD Y UBICACIÓN'), findsOneWidget);
      expect(find.text('Permitir ubicación'), findsOneWidget);
      expect(find.textContaining('80 metros'), findsOneWidget);
      expect(find.textContaining('No realizamos seguimiento continuo'), findsOneWidget);
      expect(find.byKey(const Key('allowLocationButton')), findsOneWidget);
      expect(find.byKey(const Key('denyLocationButton')), findsOneWidget);
    });
  });

  group('M06: VerificationScreen Tests', () {
    testWidgets('renders verification phases and activity indicator', (tester) async {
      await tester.pumpWidget(createTestWidget(const VerificationScreen(
        qrToken: 'EDUCCA-SES-301-DEMO',
        autoStart: false,
      )));
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.text('VERIFICACIÓN DE ASISTENCIA'), findsOneWidget);
      expect(find.text('Verificando registro'), findsOneWidget);
      expect(find.text('Validando asistencia'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.textContaining('Código QR'), findsOneWidget);
    });
  });

  group('M07: AttendanceResultScreen (Confirmed Success) Tests', () {
    testWidgets('renders confirmation card, workshop details and return buttons', (tester) async {
      final successResult = AttendanceScanResult(
        outcome: ScanOutcome.success,
        message: '¡Asistencia registrada y validada presencialmente en sede!',
        record: AttendanceRecord(
          id: 'test-att-01',
          sessionId: 'ses-educca-301',
          sessionTitle: 'Segregación en la fuente',
          courseTitle: 'Educación Ambiental EDUCCA Cusco (Datos de demostración)',
          venueName: 'Centro Cultural Cusco (Radio ≤ 80 m)',
          markedAt: DateTime.now(),
          status: 'CONFIRMED',
        ),
      );

      await tester.pumpWidget(createTestWidget(AttendanceResultScreen(
        result: successResult,
      )));
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('RESULTADO DE ASISTENCIA'), findsOneWidget);
      expect(find.text('Asistencia registrada'), findsOneWidget);
      expect(find.text('Registro confirmado'), findsOneWidget);
      expect(find.byKey(const Key('backToHomeButton')), findsOneWidget);
      expect(find.byKey(const Key('viewAttendancesButton')), findsOneWidget);
    });
  });

  group('M08: AttendanceResultScreen (Rejection Variants) Tests', () {
    testWidgets('renders E01 outOfRange (> 80 m) with retry button', (tester) async {
      const outOfRangeResult = AttendanceScanResult(
        outcome: ScanOutcome.outOfRange,
        message: 'No estás dentro del área de asistencia autorizada para esta sede (distancia > 80 m).',
      );

      await tester.pumpWidget(createTestWidget(const AttendanceResultScreen(
        result: outOfRangeResult,
      )));
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('VALIDACIÓN DE ASISTENCIA · E01'), findsOneWidget);
      expect(find.text('Estás fuera del área de asistencia'), findsOneWidget);
      expect(find.text('Distancia no permitida'), findsOneWidget);
      expect(find.byKey(const Key('retryActionButton')), findsOneWidget);
    });

    testWidgets('renders E02 expired QR with retry button', (tester) async {
      const expiredResult = AttendanceScanResult(
        outcome: ScanOutcome.expired,
        message: 'El código QR ha expirado.',
      );

      await tester.pumpWidget(createTestWidget(const AttendanceResultScreen(
        result: expiredResult,
      )));
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('VALIDACIÓN DE ASISTENCIA · E02'), findsOneWidget);
      expect(find.text('El código QR venció'), findsOneWidget);
      expect(find.byKey(const Key('retryActionButton')), findsOneWidget);
    });

    testWidgets('renders E03 duplicate attendance with view history button', (tester) async {
      const duplicateResult = AttendanceScanResult(
        outcome: ScanOutcome.duplicate,
        message: 'Tu asistencia ya fue registrada previamente para esta sesión.',
      );

      await tester.pumpWidget(createTestWidget(const AttendanceResultScreen(
        result: duplicateResult,
      )));
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('VALIDACIÓN DE ASISTENCIA · E03'), findsOneWidget);
      expect(find.text('Asistencia ya registrada'), findsOneWidget);
      expect(find.text('Ver mis asistencias'), findsOneWidget);
    });

    testWidgets('renders E05 sensor or GPS denied', (tester) async {
      const gpsErrorResult = AttendanceScanResult(
        outcome: ScanOutcome.permissionDenied,
        message: 'Permiso denegado',
      );

      await tester.pumpWidget(createTestWidget(const AttendanceResultScreen(
        result: gpsErrorResult,
      )));
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('VALIDACIÓN DE ASISTENCIA · E05'), findsOneWidget);
      expect(find.text('Ubicación no disponible'), findsOneWidget);
    });

    testWidgets('renders E06 network error', (tester) async {
      const netErrorResult = AttendanceScanResult(
        outcome: ScanOutcome.networkError,
        message: 'Sin conexión',
      );

      await tester.pumpWidget(createTestWidget(const AttendanceResultScreen(
        result: netErrorResult,
      )));
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('VALIDACIÓN DE ASISTENCIA · E06'), findsOneWidget);
      expect(find.text('No hay conexión'), findsOneWidget);
    });

    testWidgets('renders E07 inaccurate location (> 50 m)', (tester) async {
      const inaccurateResult = AttendanceScanResult(
        outcome: ScanOutcome.locationInaccurate,
        message: 'Precisión insuficiente',
      );

      await tester.pumpWidget(createTestWidget(const AttendanceResultScreen(
        result: inaccurateResult,
      )));
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('VALIDACIÓN DE ASISTENCIA · E07'), findsOneWidget);
      expect(find.text('Precisión GPS insuficiente'), findsOneWidget);
    });
  });

  group('MockEduccaRepository Session Consistency Tests', () {
    test('first scan registers attendance; second scan produces duplicate', () async {
      final repo = MockEduccaRepository();
      repo.resetMockHistory();

      final firstScan = await repo.scanAttendance(
        qrToken: 'EDUCCA-SES-301-DEMO',
        location: LocationCapture(
          latitude: -13.52,
          longitude: -71.97,
          accuracyMeters: 10,
          capturedAt: DateTime.now(),
        ),
      );

      expect(firstScan.outcome, ScanOutcome.success);
      expect(firstScan.record, isNotNull);
      expect(firstScan.record!.sessionId, 'ses-educca-301');

      // Segundo intento sobre la misma sesión
      final secondScan = await repo.scanAttendance(
        qrToken: 'EDUCCA-SES-301-DEMO',
        location: LocationCapture(
          latitude: -13.52,
          longitude: -71.97,
          accuracyMeters: 10,
          capturedAt: DateTime.now(),
        ),
      );

      expect(secondScan.outcome, ScanOutcome.duplicate);
      expect(secondScan.message, contains('ya fue registrada previamente'));
    });
  });
}
