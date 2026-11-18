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

  /// Registra un nuevo promotor ambiental en EDUCCA Cusco.
  Future<Result<dynamic>> registerPromoter({
    required String fullName,
    required String email,
    required String password,
    required String promoterCategory,
    required bool isAdult,
    required bool privacyConsentAccepted,
  });

  /// Transmite el token QR y la lectura puntual de ubicación GPS para
  /// que el backend valide sesión, inscripción y radio de 80 m de la sede.
  Future<AttendanceScanResult> scanAttendance({
    required String qrToken,
    required LocationCapture location,
  });

  /// Consulta las sesiones y talleres disponibles para el promotor.
  Future<Result<dynamic>> getPromoterSessions();

  /// Consulta el historial de asistencias confirmadas.
  Future<Result<dynamic>> getAttendanceHistory();
}
