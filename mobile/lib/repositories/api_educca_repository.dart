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
    // Go espera {"identificador": "...", "password": "..."} en POST /api/v1/login
    final loginResult = await apiClient.post(
      '/login',
      body: {
        'identificador': email.trim(),
        'password': password,
      },
      requiresAuth: false,
    );

    return await loginResult.when(
      onSuccess: (data) async {
        if (data is! Map) {
          return Result.failure('Formato de respuesta de login inválido.');
        }

        final accessToken = data['access_token']?.toString() ?? data['token']?.toString() ?? '';
        final refreshToken = data['refresh_token']?.toString() ?? '';
        final expiresIn = data['expires_in'];

        if (accessToken.isEmpty) {
          return Result.failure('El servidor no retornó un token de acceso válido.');
        }

        // Persistir tokens inmediatamente
        await apiClient.sessionStorage.saveToken(accessToken);
        if (refreshToken.isNotEmpty) {
          await apiClient.sessionStorage.saveRefreshToken(refreshToken);
        }

        // Consultar el perfil real del usuario en GET /api/v1/me
        final profileResult = await getProfile();

        Map<String, dynamic> userMap = {};
        Map<String, dynamic> personaMap = {};
        List<dynamic> roles = [];

        profileResult.when(
          onSuccess: (profData) {
            if (profData is Map) {
              if (profData['persona'] is Map) {
                personaMap = Map<String, dynamic>.from(profData['persona'] as Map);
              }
              if (profData['roles'] is List) {
                roles = List<dynamic>.from(profData['roles'] as List);
              }
            }
          },
          onFailure: (error, statusCode) {
            // Si /me falla por alguna razón secundaria, conservar fallback con el identificador
          },
        );

        final nombres = personaMap['nombres']?.toString() ?? '';
        final apellidos = personaMap['apellidos']?.toString() ?? '';
        String fullName = '$nombres $apellidos'.trim();
        if (fullName.isEmpty) {
          fullName = personaMap['email']?.toString() ?? email.trim();
        }

        userMap = {
          'id': personaMap['id']?.toString() ?? '1',
          'dni': personaMap['dni']?.toString() ?? '',
          'nombres': nombres,
          'apellidos': apellidos,
          'fullName': fullName,
          'email': personaMap['email']?.toString() ?? email.trim(),
          'role': roles.isNotEmpty ? roles.first.toString().toUpperCase() : 'CAPACITANDO',
          'promoterCategory': personaMap['categoria']?.toString() ?? 'PAJ',
          'isAdult': true,
          'privacyConsentAccepted': personaMap['consentimiento_at'] != null,
          'roles': roles,
        };

        return Result.success({
          'token': accessToken,
          'access_token': accessToken,
          'refresh_token': refreshToken,
          'expires_in': expiresIn,
          'user': userMap,
          'persona': personaMap,
          'roles': roles,
        });
      },
      onFailure: (error, statusCode) {
        return Result.failure(error, statusCode: statusCode);
      },
    );
  }

  @override
  Future<Result<dynamic>> getProfile() async {
    return await apiClient.get('/me', requiresAuth: true);
  }

  @override
  Future<Result<dynamic>> refreshSession(String refreshToken) async {
    return await apiClient.post(
      '/refresh',
      body: {'refresh_token': refreshToken},
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
    String? dni,
    String? nombres,
    String? apellidos,
    String? sexo,
    String? fechaNacimiento,
    String? telefono,
  }) async {
    // Separar nombres y apellidos si no vienen explícitos
    String nom = nombres?.trim() ?? '';
    String ape = apellidos?.trim() ?? '';
    if (nom.isEmpty) {
      final parts = fullName.trim().split(RegExp(r'\s+'));
      if (parts.length == 1) {
        nom = parts[0];
        ape = parts[0];
      } else {
        nom = parts[0];
        ape = parts.sublist(1).join(' ');
      }
    }

    // Mapear categoría a los valores válidos en PostgreSQL (CHECK: 'COMERCIANTE', 'RECICLADOR', 'PAC', 'PAJ')
    String cat = promoterCategory.trim().toUpperCase();
    if (cat == 'JUVENIL') cat = 'PAJ';
    if (cat == 'COMUNITARIO') cat = 'PAC';
    if (cat == 'ESCOLAR') cat = 'PAJ';
    if (!['PAJ', 'PAC', 'COMERCIANTE', 'RECICLADOR'].contains(cat)) {
      cat = 'PAJ';
    }

    // Go espera en POST /api/v1/register
    return await apiClient.post(
      '/register',
      body: {
        'dni': (dni != null && dni.trim().isNotEmpty) ? dni.trim() : '00000000',
        'nombres': nom,
        'apellidos': ape,
        'sexo': (sexo != null && (sexo.toUpperCase() == 'M' || sexo.toUpperCase() == 'F')) ? sexo.toUpperCase() : 'M',
        'fecha_nacimiento': (fechaNacimiento != null && fechaNacimiento.trim().isNotEmpty) ? fechaNacimiento.trim() : '2000-01-01',
        if (telefono != null && telefono.trim().isNotEmpty) 'telefono': telefono.trim(),
        'email': email.trim().toLowerCase(),
        'password': password,
        'categoria': cat,
        'consentimiento_aceptado': privacyConsentAccepted,
        'consentimiento_version': 'v1.0-2026',
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
      // Go recibe en POST /api/v1/asistencias/check-in-qr:
      // {"qr_token": "...", "latitud": float, "longitud": float}
      final result = await apiClient.post(
        '/asistencias/check-in-qr',
        body: {
          'qr_token': qrToken.trim(),
          'latitud': location.latitude,
          'longitud': location.longitude,
        },
        requiresAuth: true,
      );

      final AttendanceScanResult scanResult = result.when<AttendanceScanResult>(
        onSuccess: (data) {
          AttendanceRecord? record;
          String message = 'Asistencia presencial registrada exitosamente.';

          if (data is Map) {
            if (data['message'] != null) {
              message = data['message'].toString();
            }
            final sesionId = data['sesion_id']?.toString() ?? '1';
            final distancia = data['distancia_metros'];
            final distanciaStr = distancia != null ? ' (Distancia a sede: $distancia m)' : '';

            record = AttendanceRecord(
              id: 'att-${data['persona_id'] ?? 'user'}-$sesionId',
              sessionId: sesionId,
              sessionTitle: 'Sesión Presencial #$sesionId',
              courseTitle: 'Capacitación Ambiental EDUCCA Cusco',
              venueName: 'Sede Oficial Georreferenciada$distanciaStr',
              markedAt: DateTime.now(),
              status: 'CONFIRMED',
            );
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
          } else if (lower.contains('fuera del radio') || lower.contains('distancia') || lower.contains('out_of_range')) {
            outcome = ScanOutcome.outOfRange;
          } else if (statusCode == 410 || lower.contains('expirado') || lower.contains('rotado') || lower.contains('revocado') || lower.contains('vencid')) {
            outcome = ScanOutcome.expired;
          } else if (statusCode == 403 || lower.contains('no te encuentras inscrito') || lower.contains('no autorizad') || lower.contains('not_enrolled')) {
            outcome = ScanOutcome.unauthorized;
          } else if (lower.contains('concluid') || lower.contains('cerrad') || lower.contains('validada') || lower.contains('cancelada')) {
            outcome = ScanOutcome.sessionClosed;
          } else if (lower.contains('conexión') || lower.contains('tiempo de espera')) {
            outcome = ScanOutcome.networkError;
          } else {
            // Para otros 422 de reglas de negocio
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
    // Go ofrece el catálogo en GET /api/v1/sesiones
    return await apiClient.get('/sesiones', requiresAuth: true);
  }

  @override
  Future<Result<dynamic>> getMyEnrollments() async {
    // Go ofrece las inscripciones del usuario en GET /api/v1/mi/inscripciones
    return await apiClient.get('/mi/inscripciones', requiresAuth: true);
  }

  @override
  Future<Result<dynamic>> enrollSession(int sessionId) async {
    // Go permite inscribirse en POST /api/v1/sesiones/{id}/inscripciones
    return await apiClient.post('/sesiones/$sessionId/inscripciones', requiresAuth: true);
  }

  @override
  Future<Result<dynamic>> getAttendanceHistory() async {
    // Go ofrece el historial en GET /api/v1/mi/asistencias
    return await apiClient.get('/mi/asistencias', requiresAuth: true);
  }
}
