import '../core/api_client.dart';
import '../core/result.dart';
import '../models/attendance_models.dart';
import '../models/location_capture.dart';
import 'educca_repository.dart';

/// Implementación real de [EduccaRepository] que consume el backend Go + PostgreSQL
/// mediante [ApiClient].
class ApiEduccaRepository implements EduccaRepository {
  final ApiClient apiClient;

  ApiEduccaRepository({required this.apiClient});

  @override
  Future<Result<dynamic>> login(String email, String password) async {
    return await apiClient.post(
      '/auth/login',
      body: {
        'email': email.trim().toLowerCase(),
        'password': password,
      },
      requiresAuth: false,
    );
  }

  @override
  Future<Result<dynamic>> registerPromoter({
    required String fullName,
    required String email,
    required String password,
    required String promoterCategory,
    required bool isAdult,
    required bool privacyConsentAccepted,
  }) async {
    return await apiClient.post(
      '/auth/register',
      body: {
        'fullName': fullName.trim(),
        'email': email.trim().toLowerCase(),
        'password': password,
        'promoterCategory': promoterCategory.toUpperCase(),
        'isAdult': isAdult,
        'privacyConsentAccepted': privacyConsentAccepted,
      },
      requiresAuth: false,
    );
  }

  @override
  Future<AttendanceScanResult> scanAttendance({
    required String qrToken,
    required LocationCapture location,
  }) async {
    try {
      final result = await apiClient.post(
        '/attendance/scan',
        body: {
          'qrToken': qrToken.trim(),
          'location': location.toJson(),
        },
      );

      final AttendanceScanResult scanResult = result.when<AttendanceScanResult>(
        onSuccess: (data) {
          AttendanceRecord? record;
          String message = 'Asistencia registrada correctamente.';

          if (data is Map) {
            if (data['message'] != null) {
              message = data['message'].toString();
            }
            if (data['attendance'] != null && data['attendance'] is Map) {
              record = AttendanceRecord.fromJson(data['attendance'] as Map<String, dynamic>);
            }
          }

          return AttendanceScanResult(
            outcome: ScanOutcome.success,
            message: message,
            record: record,
          );
        },
        onFailure: (error, statusCode) {
          final lower = error.toLowerCase();
          ScanOutcome outcome;

          if (statusCode == 409 || lower.contains('ya fue registrada') || lower.contains('duplicad')) {
            outcome = ScanOutcome.duplicate;
          } else if (lower.contains('fuera del área') || lower.contains('out_of_range') || lower.contains('distancia')) {
            outcome = ScanOutcome.outOfRange;
          } else if (statusCode == 410 || lower.contains('expirado') || lower.contains('vencid') || lower.contains('caducad')) {
            outcome = ScanOutcome.expired;
          } else if (statusCode == 403 || lower.contains('no te encuentras inscrito') || lower.contains('no autorizad') || lower.contains('not_enrolled')) {
            outcome = ScanOutcome.unauthorized;
          } else if (lower.contains('concluid') || lower.contains('cerrad') || lower.contains('session_closed')) {
            outcome = ScanOutcome.sessionClosed;
          } else if (lower.contains('conexión') || lower.contains('tiempo de espera')) {
            outcome = ScanOutcome.networkError;
          } else {
            outcome = ScanOutcome.invalid;
          }

          return AttendanceScanResult(
            outcome: outcome,
            message: error,
          );
        },
      );
      return scanResult;
    } catch (e) {
      return AttendanceScanResult(
        outcome: ScanOutcome.networkError,
        message: 'Error inesperado de red al transmitir asistencia: $e',
      );
    }
  }

  @override
  Future<Result<dynamic>> getPromoterSessions() async {
    return await apiClient.get('/student/courses');
  }

  @override
  Future<Result<dynamic>> getAttendanceHistory() async {
    return await apiClient.get('/student/attendance/history');
  }
}
