import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Servicio de almacenamiento seguro para credenciales y tokens JWT de sesión.
class SessionStorage {
  static const String _tokenKey = 'jwt_auth_token';
  static const String _refreshTokenKey = 'jwt_refresh_token';
  static const String _userKey = 'cached_student_user';

  final FlutterSecureStorage _storage;

  SessionStorage({FlutterSecureStorage? storage})
      : _storage = storage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(
                encryptedSharedPreferences: true,
              ),
            );

  /// Guarda el token JWT de acceso de forma segura en Android Keystore.
  Future<void> saveToken(String token) async {
    await _storage.write(key: _tokenKey, value: token);
  }

  /// Recupera el token JWT de acceso almacenado, o null si no existe.
  Future<String?> getToken() async {
    return await _storage.read(key: _tokenKey);
  }

  /// Guarda el token JWT de renovación (refresh token) de forma segura.
  Future<void> saveRefreshToken(String refreshToken) async {
    await _storage.write(key: _refreshTokenKey, value: refreshToken);
  }

  /// Recupera el refresh token almacenado, o null si no existe.
  Future<String?> getRefreshToken() async {
    return await _storage.read(key: _refreshTokenKey);
  }

  /// Guarda los datos del usuario autenticado en formato JSON.
  Future<void> saveUserJson(String userJson) async {
    await _storage.write(key: _userKey, value: userJson);
  }

  /// Recupera los datos del usuario en formato JSON.
  Future<String?> getUserJson() async {
    return await _storage.read(key: _userKey);
  }

  /// Elimina los tokens y los datos de usuario al cerrar sesión.
  Future<void> clearSession() async {
    await _storage.delete(key: _tokenKey);
    await _storage.delete(key: _refreshTokenKey);
    await _storage.delete(key: _userKey);
  }

  /// Verifica si existe un token de sesión guardado.
  Future<bool> hasToken() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }
}
