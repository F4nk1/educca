import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import 'result.dart';
import 'session_storage.dart';

/// Cliente HTTP centralizado para consumir la API REST del backend.
class ApiClient {
  final http.Client _httpClient;
  final AppConfig config;
  final SessionStorage sessionStorage;
  final void Function()? onUnauthorized;

  ApiClient({
    required this.config,
    required this.sessionStorage,
    http.Client? httpClient,
    this.onUnauthorized,
  }) : _httpClient = httpClient ?? http.Client();

  /// Construye la URL completa a partir de la URL base y el endpoint relativo.
  Uri _buildUri(String endpoint) {
    var base = config.baseUrl;
    if (base.endsWith('/')) {
      base = base.substring(0, base.length - 1);
    }
    final path = endpoint.startsWith('/') ? endpoint : '/$endpoint';
    return Uri.parse('$base$path');
  }

  /// Construye los encabezados HTTP comunes e inyecta el token Bearer si existe.
  Future<Map<String, String>> _buildHeaders({bool requiresAuth = true}) async {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    if (requiresAuth) {
      final token = await sessionStorage.getToken();
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }
    }

    return headers;
  }

  /// Realiza una petición GET.
  Future<Result<dynamic>> get(
    String endpoint, {
    bool requiresAuth = true,
  }) async {
    try {
      final uri = _buildUri(endpoint);
      final headers = await _buildHeaders(requiresAuth: requiresAuth);

      final response = await _httpClient
          .get(uri, headers: headers)
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 401 && requiresAuth) {
        final refreshed = await _tryRefreshToken();
        if (refreshed) {
          final retryHeaders = await _buildHeaders(requiresAuth: true);
          final retryResponse = await _httpClient
              .get(uri, headers: retryHeaders)
              .timeout(const Duration(seconds: 10));
          return _handleResponse(retryResponse);
        }
      }

      return _handleResponse(response);
    } on SocketException {
      return Result.failure(
        'No se pudo conectar con el servidor. Verifica tu conexión de red o la IP configurada.',
      );
    } on TimeoutException {
      return Result.failure(
        'Tiempo de espera agotado. El servidor tardó demasiado en responder.',
      );
    } catch (e) {
      return Result.failure('Error inesperado de comunicación: $e');
    }
  }

  /// Realiza una petición POST enviando un cuerpo JSON.
  Future<Result<dynamic>> post(
    String endpoint, {
    Map<String, dynamic>? body,
    bool requiresAuth = true,
  }) async {
    try {
      final uri = _buildUri(endpoint);
      final headers = await _buildHeaders(requiresAuth: requiresAuth);

      final response = await _httpClient
          .post(
            uri,
            headers: headers,
            body: body != null ? jsonEncode(body) : null,
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 401 && requiresAuth && endpoint != '/refresh') {
        final refreshed = await _tryRefreshToken();
        if (refreshed) {
          final retryHeaders = await _buildHeaders(requiresAuth: true);
          final retryResponse = await _httpClient
              .post(
                uri,
                headers: retryHeaders,
                body: body != null ? jsonEncode(body) : null,
              )
              .timeout(const Duration(seconds: 10));
          return _handleResponse(retryResponse);
        }
      }

      return _handleResponse(response);
    } on SocketException {
      return Result.failure(
        'No se pudo conectar con el servidor. Verifica tu conexión de red o la IP configurada.',
      );
    } on TimeoutException {
      return Result.failure(
        'Tiempo de espera agotado. El servidor tardó demasiado en responder.',
      );
    } catch (e) {
      return Result.failure('Error inesperado de comunicación: $e');
    }
  }

  /// Realiza una petición DELETE.
  Future<Result<dynamic>> delete(
    String endpoint, {
    bool requiresAuth = true,
  }) async {
    try {
      final uri = _buildUri(endpoint);
      final headers = await _buildHeaders(requiresAuth: requiresAuth);

      final response = await _httpClient
          .delete(uri, headers: headers)
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 401 && requiresAuth) {
        final refreshed = await _tryRefreshToken();
        if (refreshed) {
          final retryHeaders = await _buildHeaders(requiresAuth: true);
          final retryResponse = await _httpClient
              .delete(uri, headers: retryHeaders)
              .timeout(const Duration(seconds: 10));
          return _handleResponse(retryResponse);
        }
      }

      return _handleResponse(response);
    } on SocketException {
      return Result.failure(
        'No se pudo conectar con el servidor. Verifica tu conexión de red o la IP configurada.',
      );
    } on TimeoutException {
      return Result.failure(
        'Tiempo de espera agotado. El servidor tardó demasiado en responder.',
      );
    } catch (e) {
      return Result.failure('Error inesperado de comunicación: $e');
    }
  }

  /// Intenta renovar el token de acceso utilizando el refresh_token almacenado.
  Future<bool> _tryRefreshToken() async {
    try {
      final refreshToken = await sessionStorage.getRefreshToken();
      if (refreshToken == null || refreshToken.isEmpty) return false;

      final uri = _buildUri('/refresh');
      final response = await _httpClient.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({'refresh_token': refreshToken}),
      ).timeout(const Duration(seconds: 8));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final decoded = jsonDecode(utf8.decode(response.bodyBytes));
        if (decoded is Map && decoded['access_token'] != null) {
          await sessionStorage.saveToken(decoded['access_token'].toString());
          if (decoded['refresh_token'] != null) {
            await sessionStorage.saveRefreshToken(decoded['refresh_token'].toString());
          }
          return true;
        }
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  /// Procesa la respuesta HTTP y mapea los códigos de estado.
  Result<dynamic> _handleResponse(http.Response response) {
    final statusCode = response.statusCode;
    dynamic decodedBody;

    try {
      if (response.body.isNotEmpty) {
        decodedBody = jsonDecode(utf8.decode(response.bodyBytes));
      }
    } catch (_) {
      decodedBody = response.body;
    }

    if (statusCode >= 200 && statusCode < 300) {
      return Result.success(decodedBody);
    }

    // Manejo de sesión no autorizada o expirada
    if (statusCode == 401) {
      onUnauthorized?.call();
      final msg = (decodedBody is Map && decodedBody['message'] != null)
          ? decodedBody['message'].toString()
          : 'Sesión no autorizada o expirada';
      return Result.failure(msg, statusCode: statusCode);
    }

    // Extracción de mensaje de error enviado por el backend
    String errorMessage = 'Error del servidor ($statusCode)';
    if (decodedBody is Map && decodedBody['message'] != null) {
      errorMessage = decodedBody['message'].toString();
    }

    return Result.failure(errorMessage, statusCode: statusCode);
  }

  /// Cierra el cliente HTTP cuando ya no se utilice.
  void dispose() {
    _httpClient.close();
  }
}
