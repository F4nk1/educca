import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:sistema_capacitaciones/config/app_config.dart';
import 'package:sistema_capacitaciones/core/api_client.dart';
import 'package:sistema_capacitaciones/core/session_storage.dart';
import 'package:sistema_capacitaciones/providers/auth_provider.dart';
import 'package:sistema_capacitaciones/screens/login_screen.dart';

class MockSessionStorage extends SessionStorage {
  @override
  Future<String?> getToken() async => null;
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
  testWidgets('LoginScreen renders fields and validates empty inputs', (tester) async {
    final config = AppConfig();
    final storage = MockSessionStorage();
    final apiClient = ApiClient(config: config, sessionStorage: storage);
    final authProvider = AuthProvider(apiClient: apiClient, sessionStorage: storage);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<AppConfig>.value(value: config),
          ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
        ],
        child: const MaterialApp(
          home: LoginScreen(),
        ),
      ),
    );

    expect(find.text('Portal del Promotor Ambiental'), findsOneWidget);
    expect(find.byKey(const Key('emailField')), findsOneWidget);
    expect(find.byKey(const Key('passwordField')), findsOneWidget);
    expect(find.byKey(const Key('loginButton')), findsOneWidget);

    // Pulsa iniciar sesión sin llenar campos
    await tester.tap(find.byKey(const Key('loginButton')));
    await tester.pumpAndSettle();

    expect(find.text('Por favor ingresa tu correo'), findsOneWidget);
    expect(find.text('Por favor ingresa tu contraseña'), findsOneWidget);
  });
}
