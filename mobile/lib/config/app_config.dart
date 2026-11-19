import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Servicio de configuración de entorno y URL base del backend REST.
class AppConfig extends ChangeNotifier {
  static const String _baseUrlKey = 'app_backend_base_url';
  static const String _demoModeKey = 'app_demo_mode_active';
  
  /// Valor por defecto apuntando al subdominio de pruebas (o 10.0.2.2:8080 en emulador local).
  static const String defaultBaseUrl = 'https://educca.cocorium.online/api/v1';

  String _baseUrl = defaultBaseUrl;
  bool _isDemoMode = false;

  String get baseUrl => _baseUrl;
  bool get isDemoMode => _isDemoMode;

  AppConfig({String? initialBaseUrl, bool initialDemoMode = false}) {
    if (initialBaseUrl != null && initialBaseUrl.isNotEmpty) {
      _baseUrl = initialBaseUrl;
    }
    _isDemoMode = initialDemoMode;
  }

  /// Inicializa la configuración cargando la URL y el modo demo guardados.
  Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedUrl = prefs.getString(_baseUrlKey);
      if (savedUrl != null && savedUrl.trim().isNotEmpty) {
        _baseUrl = savedUrl.trim();
      }
      _isDemoMode = prefs.getBool(_demoModeKey) ?? false;
      notifyListeners();
    } catch (_) {
      // Si falla la lectura local, conserva la URL por defecto.
    }
  }

  /// Activa o desactiva el modo de demostración simulado (disponible en debug).
  Future<void> setDemoMode(bool active) async {
    if (_isDemoMode == active) return;
    _isDemoMode = active;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_demoModeKey, _isDemoMode);
    } catch (_) {
      // Ignora errores de almacenamiento
    }
  }

  /// Actualiza la URL base y la persiste en el almacenamiento local.
  Future<void> setBaseUrl(String newUrl) async {
    final sanitized = newUrl.trim();
    if (sanitized.isEmpty || sanitized == _baseUrl) return;

    _baseUrl = sanitized;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_baseUrlKey, _baseUrl);
    } catch (_) {
      // Ignora errores de escritura en storage
    }
  }

  /// Restablece la URL base al valor predeterminado de emulador.
  Future<void> resetToDefault() async {
    await setBaseUrl(defaultBaseUrl);
  }
}
