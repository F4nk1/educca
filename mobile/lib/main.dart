import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'config/app_config.dart';
import 'config/app_theme.dart';
import 'core/api_client.dart';
import 'core/session_storage.dart';
import 'providers/attendance_provider.dart';
import 'providers/auth_provider.dart';
import 'providers/courses_provider.dart';
import 'repositories/api_educca_repository.dart';
import 'repositories/mock_educca_repository.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final appConfig = AppConfig();
  await appConfig.init();

  final sessionStorage = SessionStorage();

  late final ApiClient apiClient;
  late final AuthProvider authProvider;

  apiClient = ApiClient(
    config: appConfig,
    sessionStorage: sessionStorage,
    onUnauthorized: () {
      authProvider.handleSessionExpired();
    },
  );

  final apiRepo = ApiEduccaRepository(apiClient: apiClient);
  final mockRepo = MockEduccaRepository();

  final initialRepo = appConfig.isDemoMode ? mockRepo : apiRepo;

  authProvider = AuthProvider(
    apiClient: apiClient,
    sessionStorage: sessionStorage,
    repository: initialRepo,
  );

  final coursesProvider = CoursesProvider(
    apiClient: apiClient,
    repository: initialRepo,
  );
  final attendanceProvider = AttendanceProvider(
    apiClient: apiClient,
    repository: initialRepo,
  );

  // Escucha cambios en AppConfig para alternar en caliente entre API real y Mock Demo
  appConfig.addListener(() {
    final activeRepo = appConfig.isDemoMode ? mockRepo : apiRepo;
    authProvider.setRepository(activeRepo);
    coursesProvider.setRepository(activeRepo);
    attendanceProvider.setRepository(activeRepo);
  });

  // Verifica sesión previa antes de renderizar
  await authProvider.checkAuthStatus();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<AppConfig>.value(value: appConfig),
        ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
        ChangeNotifierProvider<CoursesProvider>.value(value: coursesProvider),
        ChangeNotifierProvider<AttendanceProvider>.value(value: attendanceProvider),
      ],
      child: const SistemaCapacitacionesApp(),
    ),
  );
}

class SistemaCapacitacionesApp extends StatelessWidget {
  const SistemaCapacitacionesApp({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return MaterialApp(
      title: 'EDUCCA Cusco — Promotores Ambientales',
      theme: AppTheme.lightTheme,
      debugShowCheckedModeBanner: false,
      home: Builder(
        builder: (context) {
          if (auth.status == AuthStatus.uninitialized) {
            return const Scaffold(
              body: Center(
                child: CircularProgressIndicator(),
              ),
            );
          }

          if (auth.isAuthenticated) {
            return const HomeScreen();
          }

          return const LoginScreen();
        },
      ),
    );
  }
}
