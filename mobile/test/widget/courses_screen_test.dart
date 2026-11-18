import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:provider/provider.dart';
import 'package:sistema_capacitaciones/config/app_config.dart';
import 'package:sistema_capacitaciones/core/api_client.dart';
import 'package:sistema_capacitaciones/core/session_storage.dart';
import 'package:sistema_capacitaciones/providers/courses_provider.dart';
import 'package:sistema_capacitaciones/screens/courses_screen.dart';

class MockSessionStorage extends SessionStorage {
  @override
  Future<String?> getToken() async => 'mock_token';
  @override
  Future<String?> getUserJson() async => null;
  @override
  Future<void> saveToken(String token) async {}
  @override
  Future<void> saveUserJson(String userJson) async {}
  @override
  Future<void> clearSession() async {}
}

void main() {
  testWidgets('CoursesScreen renders empty state when courses list is empty', (tester) async {
    final mockHttp = MockClient((request) async {
      return http.Response(jsonEncode([]), 200);
    });

    final storage = MockSessionStorage();
    final client = ApiClient(
      config: AppConfig(),
      sessionStorage: storage,
      httpClient: mockHttp,
    );
    final provider = CoursesProvider(apiClient: client);

    await tester.pumpWidget(
      ChangeNotifierProvider<CoursesProvider>.value(
        value: provider,
        child: const MaterialApp(
          home: Scaffold(body: CoursesScreen()),
        ),
      ),
    );

    // Espera a que termine la carga asíncrona
    await tester.pumpAndSettle();

    expect(find.text('Sin capacitaciones activas'), findsOneWidget);
  });

  testWidgets('CoursesScreen renders error state and retry button on network failure', (tester) async {
    final mockHttp = MockClient((request) async {
      return http.Response('Internal Server Error', 500);
    });

    final storage = MockSessionStorage();
    final client = ApiClient(
      config: AppConfig(),
      sessionStorage: storage,
      httpClient: mockHttp,
    );
    final provider = CoursesProvider(apiClient: client);

    await tester.pumpWidget(
      ChangeNotifierProvider<CoursesProvider>.value(
        value: provider,
        child: const MaterialApp(
          home: Scaffold(body: CoursesScreen()),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Ocurrió un problema de conexión'), findsOneWidget);
    expect(find.text('Reintentar'), findsOneWidget);
  });
}
