import '../core/result.dart';
import '../models/attendance_models.dart';
import '../models/location_capture.dart';

/// Contrato abstracto para las operaciones de backend de EDUCCA Cusco.
///
/// Permite desacoplar los Providers y la interfaz visual de las rutas
/// HTTP definitivas del backend Go + PostgreSQL, y habilita la alternancia
/// con un repositorio simulado ([MockEduccaRepository]) bajo debug.
abstract class EduccaRepository {
  /// Inicia sesión con credenciales de usuario.
  Future<Result<dynamic>> login(String email, String password);

  /// Obtiene los datos del perfil del usuario autenticado (GET /api/v1/me).
  Future<Result<dynamic>> getProfile();

  /// Renueva el token de acceso utilizando un refresh token (POST /api/v1/refresh).
  Future<Result<dynamic>> refreshSession(String refreshToken);

  /// Registra un nuevo promotor ambiental en EDUCCA Cusco.
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
  });

  /// Transmite el token QR y la lectura puntual de ubicación GPS para
  /// que el backend valide sesión, inscripción y radio de 80 m de la sede.
  Future<AttendanceScanResult> scanAttendance({
    required String qrToken,
    required LocationCapture location,
  });

  /// Consulta las sesiones y talleres disponibles para el promotor.
  Future<Result<dynamic>> getPromoterSessions();

  /// Inscribe al usuario autenticado en una sesión específica (POST /api/v1/sesiones/{id}/inscripciones).
  Future<Result<dynamic>> enrollSession(int sessionId);

  /// Consulta las inscripciones activas del usuario autenticado (GET /api/v1/mi/inscripciones).
  Future<Result<dynamic>> getMyEnrollments();

  /// Consulta el historial de asistencias confirmadas.
  Future<Result<dynamic>> getAttendanceHistory();
}
