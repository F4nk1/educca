import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:sistema_capacitaciones/config/app_config.dart';
import 'package:sistema_capacitaciones/core/api_client.dart';
import 'package:sistema_capacitaciones/core/result.dart';
import 'package:sistema_capacitaciones/core/session_storage.dart';

// Fake SessionStorage en memoria para tests unitarios
class FakeSessionStorage extends SessionStorage {
  String? _token;
  String? _userJson;

  @override
  Future<void> saveToken(String token) async {
    _token = token;
  }

  @override
  Future<String?> getToken() async => _token;

  @override
  Future<void> saveUserJson(String userJson) async {
    _userJson = userJson;
  }

  @override
  Future<String?> getUserJson() async => _userJson;

  @override
  Future<void> clearSession() async {
    _token = null;
    _userJson = null;
  }

  @override
  Future<bool> hasToken() async => _token != null && _token!.isNotEmpty;
}

void main() {
  group('Result<T> Unit Tests', () {
    test('Result.success returns data and isSuccess=true', () {
      final result = Result.success('ok');
      expect(result.isSuccess, isTrue);
      expect(result.data, 'ok');
      expect(result.error, isNull);
    });

    test('Result.failure returns error and isSuccess=false', () {
      final result = Result<String>.failure('fail', statusCode: 400);
      expect(result.isSuccess, isFalse);
      expect(result.data, isNull);
      expect(result.error, 'fail');
      expect(result.statusCode, 400);
    });
  });

  group('ApiClient Unit Tests', () {
    late AppConfig config;
    late FakeSessionStorage storage;

    setUp(() {
      config = AppConfig(initialBaseUrl: 'http://example.com/api/v1');
      storage = FakeSessionStorage();
    });

    test('GET request injects Authorization header when token exists', () async {
      await storage.saveToken('test_jwt_123');

      final mockHttp = MockClient((request) async {
        expect(request.url.toString(), 'http://example.com/api/v1/test');
        expect(request.headers['Authorization'], 'Bearer test_jwt_123');
        return http.Response(jsonEncode({'success': true}), 200);
      });

      final client = ApiClient(
        config: config,
        sessionStorage: storage,
        httpClient: mockHttp,
      );

      final result = await client.get('/test');
      expect(result.isSuccess, isTrue);
      expect(result.data['success'], isTrue);
    });

    test('POST request sends JSON body and parses 200 response', () async {
      final mockHttp = MockClient((request) async {
        final body = jsonDecode(request.body);
        expect(body['email'], 'student@example.com');
        return http.Response(jsonEncode({'token': 'jwt_abc'}), 200);
      });

      final client = ApiClient(
        config: config,
        sessionStorage: storage,
        httpClient: mockHttp,
      );

      final result = await client.post('/auth/login', body: {'email': 'student@example.com'});
      expect(result.isSuccess, isTrue);
      expect(result.data['token'], 'jwt_abc');
    });

    test('401 response invokes onUnauthorized callback', () async {
      bool unauthorizedCalled = false;

      final mockHttp = MockClient((request) async {
        return http.Response(jsonEncode({'message': 'Token expirado'}), 401);
      });

      final client = ApiClient(
        config: config,
        sessionStorage: storage,
        httpClient: mockHttp,
        onUnauthorized: () {
          unauthorizedCalled = true;
        },
      );

      final result = await client.get('/protected');
      expect(result.isSuccess, isFalse);
      expect(result.statusCode, 401);
      expect(result.error, 'Token expirado');
      expect(unauthorizedCalled, isTrue);
    });
  });
}
