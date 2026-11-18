import 'package:flutter/foundation.dart';
import '../core/api_client.dart';
import '../models/course.dart';
import '../models/course_session.dart';
import '../repositories/educca_repository.dart';
import '../repositories/mock_educca_repository.dart';

/// Proveedor de estado para consultar capacitaciones inscritas y sus sesiones.
class CoursesProvider extends ChangeNotifier {
  final ApiClient apiClient;
  EduccaRepository? _repository;

  List<Course> _courses = [];
  bool _isLoading = false;
  String? _errorMessage;

  // Sesiones por curso
  final Map<String, List<CourseSession>> _sessions = {};
  final Map<String, bool> _loadingSessions = {};
  final Map<String, String?> _sessionErrors = {};

  CoursesProvider({
    required this.apiClient,
    EduccaRepository? repository,
  }) : _repository = repository ?? (apiClient.config.isDemoMode ? MockEduccaRepository() : null);

  List<Course> get courses => _courses;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  void setRepository(EduccaRepository newRepo) {
    _repository = newRepo;
    notifyListeners();
  }

  List<CourseSession> getSessions(String courseId) => _sessions[courseId] ?? [];
  bool isLoadingSessions(String courseId) => _loadingSessions[courseId] ?? false;
  String? getSessionError(String courseId) => _sessionErrors[courseId];

  /// Consulta la lista de capacitaciones del promotor.
  /// En modo demo consume el mock determinista; en modo producción consulta el API real.
  Future<void> fetchCourses() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    if (_repository != null) {
      final result = await _repository!.getPromoterSessions();
      result.when(
        onSuccess: (data) {
          if (data is List) {
            _courses = data
                .map((item) => Course.fromJson(item as Map<String, dynamic>))
                .toList();
          } else {
            _courses = [];
          }
          _errorMessage = null;
          _isLoading = false;
          notifyListeners();
        },
        onFailure: (error, _) {
          _errorMessage = error;
          _isLoading = false;
          notifyListeners();
        },
      );
      return;
    }

    final result = await apiClient.get('/sesiones');

    result.when(
      onSuccess: (data) {
        if (data is List) {
          _courses = data
              .map((item) => Course.fromJson(item as Map<String, dynamic>))
              .toList();
        } else {
          _courses = [];
        }
        _errorMessage = null;
        _isLoading = false;
        notifyListeners();
      },
      onFailure: (error, _) {
        _errorMessage = error;
        _isLoading = false;
        notifyListeners();
      },
    );
  }

  /// Consulta las inscripciones activas del promotor (GET /api/v1/mi/inscripciones).
  Future<void> fetchMyEnrollments() async {
    if (_repository != null) {
      final result = await _repository!.getMyEnrollments();
      result.when(
        onSuccess: (data) {
          if (data is List) {
            _courses = data
                .map((item) => Course.fromJson(item as Map<String, dynamic>))
                .toList();
          }
          notifyListeners();
        },
        onFailure: (error, _) {
          // Si falla, conserva las sesiones ya cargadas
        },
      );
    }
  }

  /// Inscribe al usuario autenticado a una sesión específica (POST /api/v1/sesiones/{id}/inscripciones).
  Future<bool> enrollSession(int sessionId) async {
    if (_repository != null) {
      final result = await _repository!.enrollSession(sessionId);
      return result.when(
        onSuccess: (_) {
          fetchCourses();
          return true;
        },
        onFailure: (error, _) {
          _errorMessage = error;
          notifyListeners();
          return false;
        },
      );
    }
    return false;
  }

  /// Consulta las sesiones de un curso o el detalle de una sesión específica (/api/v1/sesiones/:id).
  Future<void> fetchSessions(String courseId) async {
    _loadingSessions[courseId] = true;
    _sessionErrors[courseId] = null;
    notifyListeners();

    if (_repository is MockEduccaRepository || apiClient.config.isDemoMode) {
      await Future.delayed(const Duration(milliseconds: 250));
      _sessions[courseId] = [
        CourseSession(
          id: 'ses-educca-301',
          courseId: courseId,
          title: 'Sesión Presencial: Práctica en Sede',
          scheduledDate: DateTime.now().add(const Duration(days: 2)),
          startTime: '09:00',
          endTime: '11:00',
          location: 'Centro Cultural Cusco (Radio ≤ 80 m)',
          attendanceStatus: SessionAttendanceStatus.open,
        ),
      ];
      _sessionErrors[courseId] = null;
      _loadingSessions[courseId] = false;
      notifyListeners();
      return;
    }

    final result = await apiClient.get('/sesiones/$courseId');

    result.when(
      onSuccess: (data) {
        if (data is List) {
          _sessions[courseId] = data
              .map((item) => CourseSession.fromJson(item as Map<String, dynamic>))
              .toList();
        } else if (data is Map) {
          _sessions[courseId] = [CourseSession.fromJson(data as Map<String, dynamic>)];
        } else {
          _sessions[courseId] = [];
        }
        _sessionErrors[courseId] = null;
        _loadingSessions[courseId] = false;
        notifyListeners();
      },
      onFailure: (error, _) {
        _sessionErrors[courseId] = error;
        _loadingSessions[courseId] = false;
        notifyListeners();
      },
    );
  }
}
