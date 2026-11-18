import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../core/api_client.dart';
import '../core/session_storage.dart';
import '../models/promoter_user.dart';
import '../models/student_user.dart';
import '../repositories/api_educca_repository.dart';
import '../repositories/educca_repository.dart';

enum AuthStatus {
  uninitialized,
  authenticated,
  unauthenticated,
}

/// Proveedor de estado de autenticación y sesión del promotor / estudiante.
class AuthProvider extends ChangeNotifier {
  final ApiClient apiClient;
  final SessionStorage sessionStorage;
  EduccaRepository _repository;

  AuthStatus _status = AuthStatus.uninitialized;
  bool _isLoading = false;
  String? _errorMessage;
  StudentUser? _currentUser;
  PromoterUser? _currentPromoterUser;
  String? _token;

  AuthProvider({
    required this.apiClient,
    required this.sessionStorage,
    EduccaRepository? repository,
  }) : _repository = repository ?? ApiEduccaRepository(apiClient: apiClient);

  AuthStatus get status => _status;
  bool get isAuthenticated => _status == AuthStatus.authenticated;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  StudentUser? get currentUser => _currentUser;
  PromoterUser? get currentPromoterUser => _currentPromoterUser;
  String? get token => _token;
  EduccaRepository get repository => _repository;

  /// Permite alternar dinámicamente entre ApiEduccaRepository y MockEduccaRepository en debug.
  void setRepository(EduccaRepository newRepo) {
    _repository = newRepo;
    notifyListeners();
  }

  /// Verifica si existe una sesión previa guardada en el almacenamiento seguro.
  Future<void> checkAuthStatus() async {
    _isLoading = true;
    notifyListeners();

    try {
      final token = await sessionStorage.getToken();
      final userJson = await sessionStorage.getUserJson();

      if (token != null && token.isNotEmpty && userJson != null) {
        _token = token;
        final decoded = jsonDecode(userJson) as Map<String, dynamic>;
        _currentPromoterUser = PromoterUser.fromJson(decoded);
        _currentUser = StudentUser.fromJson(decoded);
        _status = AuthStatus.authenticated;
      } else {
        _status = AuthStatus.unauthenticated;
      }
    } catch (_) {
      _status = AuthStatus.unauthenticated;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Inicia sesión con correo y contraseña consumiendo el repositorio activo.
  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _repository.login(email, password);

      final loginSuccess = await result.when(
        onSuccess: (data) async {
          if (data is Map && data['token'] != null) {
            _token = data['token'].toString();

            if (data['user'] != null && data['user'] is Map) {
              final userMap = data['user'] as Map<String, dynamic>;
              _currentPromoterUser = PromoterUser.fromJson(userMap);
              _currentUser = StudentUser.fromJson(userMap);
              await sessionStorage.saveUserJson(jsonEncode(_currentPromoterUser!.toJson()));
            }

            await sessionStorage.saveToken(_token!);
            _status = AuthStatus.authenticated;
            _errorMessage = null;
            _isLoading = false;
            notifyListeners();
            return true;
          } else {
            _errorMessage = 'Formato de respuesta inválido del servidor.';
            _isLoading = false;
            notifyListeners();
            return false;
          }
        },
        onFailure: (error, statusCode) async {
          if (statusCode == 401) {
            _errorMessage = 'Credenciales inválidas. Verifica tu correo y contraseña.';
          } else if (statusCode == 403) {
            _errorMessage = 'Tu cuenta de usuario se encuentra inactiva o no autorizada.';
          } else {
            _errorMessage = error;
          }
          _status = AuthStatus.unauthenticated;
          _isLoading = false;
          notifyListeners();
          return false;
        },
      );

      return loginSuccess;
    } catch (e) {
      _errorMessage = 'Error inesperado durante el inicio de sesión: $e';
      _status = AuthStatus.unauthenticated;
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Registra un nuevo promotor ambiental en EDUCCA Cusco (HU-01 / RNF-01).
  Future<bool> registerPromoter({
    required String fullName,
    required String email,
    required String password,
    required String promoterCategory,
    required bool isAdult,
    required bool privacyConsentAccepted,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _repository.registerPromoter(
        fullName: fullName,
        email: email,
        password: password,
        promoterCategory: promoterCategory,
        isAdult: isAdult,
        privacyConsentAccepted: privacyConsentAccepted,
      );

      final success = result.when(
        onSuccess: (data) {
          _isLoading = false;
          _errorMessage = null;
          notifyListeners();
          return true;
        },
        onFailure: (error, statusCode) {
          if (statusCode == 409) {
            _errorMessage = 'El correo electrónico ya se encuentra registrado.';
          } else {
            _errorMessage = error;
          }
          _isLoading = false;
          notifyListeners();
          return false;
        },
      );

      return success;
    } catch (e) {
      _errorMessage = 'Error inesperado en el registro: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Cierra la sesión activa purgando las credenciales locales de inmediato.
  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();

    try {
      await apiClient.post('/auth/logout');
    } catch (_) {
      // Ignora error si el backend está caído durante logout
    } finally {
      await sessionStorage.clearSession();
      _token = null;
      _currentUser = null;
      _currentPromoterUser = null;
      _errorMessage = null;
      _status = AuthStatus.unauthenticated;
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Maneja respuestas 401 automáticamente expirando la sesión local.
  Future<void> handleSessionExpired() async {
    await sessionStorage.clearSession();
    _token = null;
    _currentUser = null;
    _currentPromoterUser = null;
    _errorMessage = 'Tu sesión ha expirado. Por favor, ingresa nuevamente.';
    _status = AuthStatus.unauthenticated;
    notifyListeners();
  }

  /// Limpia los mensajes de error mostrados al usuario.
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
