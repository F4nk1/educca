import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:sistema_capacitaciones/config/app_config.dart';
import 'package:sistema_capacitaciones/core/api_client.dart';
import 'package:sistema_capacitaciones/core/session_storage.dart';
import 'package:sistema_capacitaciones/models/promoter_user.dart';
import 'package:sistema_capacitaciones/providers/auth_provider.dart';
import 'package:sistema_capacitaciones/repositories/mock_educca_repository.dart';
import 'package:sistema_capacitaciones/screens/register_screen.dart';

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
  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  Widget createWidgetUnderTest(AuthProvider authProvider) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
      ],
      child: const MaterialApp(
        home: RegisterScreen(),
      ),
    );
  }

  testWidgets('RegisterScreen renders fields and requires consent and valid inputs', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());
    final storage = MockSessionStorage();
    final apiClient = ApiClient(config: AppConfig(), sessionStorage: storage);
    final mockRepo = MockEduccaRepository();
    final authProvider = AuthProvider(
      apiClient: apiClient,
      sessionStorage: storage,
      repository: mockRepo,
    );

    await tester.pumpWidget(createWidgetUnderTest(authProvider));

    expect(find.text('Registro de Promotor EDUCCA'), findsOneWidget);
    expect(find.byKey(const Key('nameField')), findsOneWidget);
    expect(find.byKey(const Key('emailField')), findsOneWidget);
    expect(find.byKey(const Key('passwordField')), findsOneWidget);
    expect(find.byKey(const Key('confirmPasswordField')), findsOneWidget);
    expect(find.byKey(const Key('categoryDropdown')), findsOneWidget);
    expect(find.byKey(const Key('consentCheckbox')), findsOneWidget);
    expect(find.byKey(const Key('registerButton')), findsOneWidget);

    // Initial button should be disabled because consentCheckbox is false
    final buttonFinder = find.byKey(const Key('registerButton'));
    final button = tester.widget<ElevatedButton>(buttonFinder);
    expect(button.onPressed, isNull);
  });

  testWidgets('RegisterScreen blocks submission for minor escolar promotor', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());
    final storage = MockSessionStorage();
    final apiClient = ApiClient(config: AppConfig(), sessionStorage: storage);
    final mockRepo = MockEduccaRepository();
    final authProvider = AuthProvider(
      apiClient: apiClient,
      sessionStorage: storage,
      repository: mockRepo,
    );

    await tester.pumpWidget(createWidgetUnderTest(authProvider));

    // Fill form
    await tester.enterText(find.byKey(const Key('nameField')), 'Carlos Escolar');
    await tester.enterText(find.byKey(const Key('emailField')), 'carlos@colegio.edu.pe');
    await tester.enterText(find.byKey(const Key('passwordField')), 'password123');
    await tester.enterText(find.byKey(const Key('confirmPasswordField')), 'password123');

    // Accept consent
    await tester.tap(find.byKey(const Key('consentCheckbox')));
    await tester.pumpAndSettle();

    // Select Escolar category
    await tester.tap(find.byKey(const Key('categoryDropdown')));
    await tester.pumpAndSettle();
    await tester.tap(find.text(PromoterCategory.escolar.displayName).last);
    await tester.pumpAndSettle();

    // Adult checkbox should appear
    final adultCheckbox = find.byKey(const Key('isAdultCheckbox'));
    expect(adultCheckbox, findsOneWidget);
    await tester.ensureVisible(adultCheckbox);
    await tester.pumpAndSettle();

    // Uncheck adult checkbox (declaring to be minor)
    await tester.tap(adultCheckbox);
    await tester.pumpAndSettle();

    // Warning message must appear
    expect(
      find.textContaining('menores de edad es gestionado directamente por su institución educativa'),
      findsOneWidget,
    );

    // Button must be disabled
    final button = tester.widget<ElevatedButton>(find.byKey(const Key('registerButton')));
    expect(button.onPressed, isNull);
  });

  testWidgets('RegisterScreen renders all Go contract fields and allows successful registration', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());
    final storage = MockSessionStorage();
    final apiClient = ApiClient(config: AppConfig(), sessionStorage: storage);
    final mockRepo = MockEduccaRepository();
    final authProvider = AuthProvider(
      apiClient: apiClient,
      sessionStorage: storage,
      repository: mockRepo,
    );

    await tester.pumpWidget(createWidgetUnderTest(authProvider));

    // Verify all contract fields exist
    expect(find.byKey(const Key('dniField')), findsOneWidget);
    expect(find.byKey(const Key('nameField')), findsOneWidget);
    expect(find.byKey(const Key('lastNameField')), findsOneWidget);
    expect(find.byKey(const Key('sexoM')), findsOneWidget);
    expect(find.byKey(const Key('sexoF')), findsOneWidget);
    expect(find.byKey(const Key('birthDateField')), findsOneWidget);
    expect(find.byKey(const Key('phoneField')), findsOneWidget);
    expect(find.byKey(const Key('emailField')), findsOneWidget);
    expect(find.byKey(const Key('passwordField')), findsOneWidget);
    expect(find.byKey(const Key('confirmPasswordField')), findsOneWidget);

    // Fill the complete registration form
    await tester.enterText(find.byKey(const Key('dniField')), '74561238');
    await tester.enterText(find.byKey(const Key('nameField')), 'Sayri');
    await tester.enterText(find.byKey(const Key('lastNameField')), 'Huaman');
    await tester.tap(find.byKey(const Key('sexoM')));
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('phoneField')), '984123456');
    await tester.enterText(find.byKey(const Key('emailField')), 'sayri.huaman@educca.gob.pe');
    await tester.enterText(find.byKey(const Key('passwordField')), 'seguridad2026');
    await tester.enterText(find.byKey(const Key('confirmPasswordField')), 'seguridad2026');

    // Accept consent
    final consentFinder = find.byKey(const Key('consentCheckbox'));
    await tester.ensureVisible(consentFinder);
    await tester.pumpAndSettle();
    await tester.tap(consentFinder);
    await tester.pumpAndSettle();

    // Register button should now be enabled
    final registerBtnFinder = find.byKey(const Key('registerButton'));
    await tester.ensureVisible(registerBtnFinder);
    await tester.pumpAndSettle();
    final registerBtn = tester.widget<ElevatedButton>(registerBtnFinder);
    expect(registerBtn.onPressed, isNotNull);

    // Tap register button
    await tester.tap(registerBtnFinder);
    await tester.pump(); // Start async call
    await tester.pump(const Duration(milliseconds: 1000)); // Complete mock delay
    await tester.pumpAndSettle();

    // Verify success snackbar
    expect(find.text('¡Cuenta de promotor creada con éxito! Ahora puedes iniciar sesión.'), findsOneWidget);
  });
}
