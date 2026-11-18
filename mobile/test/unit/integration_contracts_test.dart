import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:sistema_capacitaciones/config/app_config.dart';
import 'package:sistema_capacitaciones/core/api_client.dart';
import 'package:sistema_capacitaciones/core/session_storage.dart';
import 'package:sistema_capacitaciones/models/attendance_models.dart';
import 'package:sistema_capacitaciones/models/course.dart';
import 'package:sistema_capacitaciones/models/course_session.dart';
import 'package:sistema_capacitaciones/models/location_capture.dart';
import 'package:sistema_capacitaciones/models/promoter_user.dart';
import 'package:sistema_capacitaciones/repositories/api_educca_repository.dart';

class FakeIntegrationStorage extends SessionStorage {
  String? _token = 'jwt_test_token';
  String? _refreshToken = 'jwt_test_refresh';
  String? _userJson;

  @override
  Future<void> saveToken(String token) async => _token = token;

  @override
  Future<String?> getToken() async => _token;

  @override
  Future<void> saveRefreshToken(String refreshToken) async => _refreshToken = refreshToken;

  @override
  Future<String?> getRefreshToken() async => _refreshToken;

  @override
  Future<void> saveUserJson(String userJson) async => _userJson = userJson;

  @override
  Future<String?> getUserJson() async => _userJson;

  @override
  Future<void> clearSession() async {
    _token = null;
    _refreshToken = null;
    _userJson = null;
  }

  @override
  Future<bool> hasToken() async => _token != null && _token!.isNotEmpty;
}

void main() {
  group('Backend Go Integration Contracts Unit Tests', () {
    test('1. Parses Go Persona from GET /api/v1/me correctly', () {
      final goMeJson = {
        'persona': {
          'id': 10,
          'dni': '72345678',
          'nombres': 'Sayri',
          'apellidos': 'Tupac Yupanqui',
          'sexo': 'M',
          'fecha_nacimiento': '1998-07-24T00:00:00Z',
          'telefono': '+51984000111',
          'email': 'sayri@educca.gob.pe',
          'categoria': 'PAJ',
          'consentimiento_at': '2026-11-18T10:00:00Z',
          'consentimiento_version': 'v1.0-2026',
          'anonimizado': false,
          'activo': true,
        },
        'roles': ['capacitando'],
        'permisos': ['organizaciones:leer', 'sesiones:leer', 'asistencias:checkin_qr'],
      };

      final promoter = PromoterUser.fromJson(goMeJson);
      expect(promoter.id, '10');
      expect(promoter.dni, '72345678');
      expect(promoter.fullName, 'Sayri Tupac Yupanqui');
      expect(promoter.role, 'CAPACITANDO');
      expect(promoter.promoterCategory, PromoterCategory.paj);
      expect(promoter.promoterCategory.backendCode, 'PAJ');
      expect(promoter.isAdult, isTrue);
      expect(promoter.privacyConsentAccepted, isTrue);
    });

    test('2. Parses Go Sesion into Course and CourseSession models', () {
      final goSesionJson = {
        'id': 42,
        'meta_anual_id': 2026,
        'organizacion_id': 5,
        'responsable_id': 3,
        'titulo': 'Manejo de Residuos en Mercados de Cusco',
        'modalidad': 'PRESENCIAL',
        'eje_tematico': 'RESIDUOS_SOLIDOS',
        'fecha_inicio': '2026-11-25T09:30:00Z',
        'duracion_minutos': 90,
        'cupo_maximo': 40,
        'inscritos_actuales': 12,
        'cupos_disponibles': 28,
        'estado': 'EN_CURSO',
      };

      final course = Course.fromJson(goSesionJson);
      expect(course.id, '42');
      expect(course.title, 'Manejo de Residuos en Mercados de Cusco');
      expect(course.status, 'EN_CURSO');
      expect(course.endDate.difference(course.startDate).inMinutes, 90);

      final session = CourseSession.fromJson(goSesionJson);
      expect(session.id, '42');
      expect(session.courseId, '2026');
      expect(session.attendanceStatus, SessionAttendanceStatus.open);
      expect(session.isAttendanceOpen, isTrue);
      expect(session.location, contains('PRESENCIAL'));
    });

    test('3. Parses Go MiAsistencia into AttendanceRecord', () {
      final goMiAsistenciaJson = {
        'sesion_id': 77,
        'titulo': 'Taller de Forestación Urbana',
        'eje_tematico': 'CAMBIO_CLIMATICO',
        'modalidad': 'PRESENCIAL',
        'fecha_inicio': '2026-11-20T10:00:00Z',
        'estado_sesion': 'CONCLUIDA',
        'participacion': 'ASISTENTE',
        'calificacion': 18.5,
        'metodo_registro': 'QR_GPS',
        'distancia_metros': 35.8,
        'registrado_at': '2026-11-20T10:08:15Z',
      };

      final record = AttendanceRecord.fromJson(goMiAsistenciaJson);
      expect(record.sessionId, '77');
      expect(record.sessionTitle, 'Taller de Forestación Urbana');
      expect(record.venueName, contains('35.8 m'));
      expect(record.status, 'ASISTENTE');
    });

    test('4. ApiEduccaRepository.scanAttendance maps 201, 409, 422 correctly', () async {
      final mockClient = MockClient((request) async {
        if (request.url.path.endsWith('/asistencias/check-in-qr')) {
          final body = jsonDecode(request.body) as Map<String, dynamic>;
          final token = body['qr_token'] as String;

          if (token == 'token-success') {
            return http.Response(
              jsonEncode({
                'message': 'Asistencia presencial registrada exitosamente',
                'sesion_id': 1,
                'persona_id': 2,
                'metodo_registro': 'QR_GPS',
                'distancia_metros': 15.2,
                'radio_metros': 80,
              }),
              201,
              headers: {'content-type': 'application/json'},
            );
          } else if (token == 'token-duplicate') {
            return http.Response(
              jsonEncode({
                'httpStatusCode': 409,
                'errorCode': 1005,
                'message': 'La asistencia ya fue registrada para esta sesion',
              }),
              409,
              headers: {'content-type': 'application/json'},
            );
          } else if (token == 'token-far') {
            return http.Response(
              jsonEncode({
                'httpStatusCode': 422,
                'errorCode': 1006,
                'message': 'Ubicación fuera del radio permitido de la sede: 120.50 m (máximo 80 m)',
              }),
              422,
              headers: {'content-type': 'application/json'},
            );
          } else if (token == 'token-expired') {
            return http.Response(
              jsonEncode({
                'httpStatusCode': 422,
                'errorCode': 1006,
                'message': 'El código QR de la sesión ha expirado o fue rotado/revocado',
              }),
              422,
              headers: {'content-type': 'application/json'},
            );
          }
        }
        return http.Response('Not Found', 404);
      });

      final config = AppConfig(initialBaseUrl: 'http://test:8080/api/v1');
      final storage = FakeIntegrationStorage();
      final apiClient = ApiClient(
        config: config,
        sessionStorage: storage,
        httpClient: mockClient,
      );
      final repo = ApiEduccaRepository(apiClient: apiClient);
      final loc = LocationCapture(
        latitude: -13.516,
        longitude: -71.978,
        accuracyMeters: 10.0,
        capturedAt: DateTime.now(),
      );

      // Caso 1: 201 Éxito
      final resSuccess = await repo.scanAttendance(qrToken: 'token-success', location: loc);
      expect(resSuccess.outcome, ScanOutcome.success);
      expect(resSuccess.record, isNotNull);

      // Caso 2: 409 Duplicado
      final resDup = await repo.scanAttendance(qrToken: 'token-duplicate', location: loc);
      expect(resDup.outcome, ScanOutcome.duplicate);

      // Caso 3: 422 Fuera de rango
      final resFar = await repo.scanAttendance(qrToken: 'token-far', location: loc);
      expect(resFar.outcome, ScanOutcome.outOfRange);

      // Caso 4: 422 QR expirado
      final resExp = await repo.scanAttendance(qrToken: 'token-expired', location: loc);
      expect(resExp.outcome, ScanOutcome.expired);
    });

    test('5. SessionStorage stores and clears refresh token', () async {
      final storage = FakeIntegrationStorage();
      await storage.saveRefreshToken('test_refresh_jwt');
      expect(await storage.getRefreshToken(), 'test_refresh_jwt');

      await storage.clearSession();
      expect(await storage.getRefreshToken(), isNull);
    });
  });
}
