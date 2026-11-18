import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../config/app_config.dart';
import '../models/promoter_user.dart';
import '../providers/auth_provider.dart';
import '../providers/courses_provider.dart';
import 'attendance_history_screen.dart';
import 'courses_screen.dart';
import 'qr_scanner_screen.dart';
import 'widgets/andean_widgets.dart';
import 'widgets/demo_tour_sheet.dart';
import 'widgets/privacy_consent_dialog.dart';
import 'widgets/server_config_dialog.dart';

/// Pantalla principal M03 (Inicio del Promotor · Tema Andino EDUCCA Cusco)
class HomeScreen extends StatefulWidget {
  final int initialTab;

  const HomeScreen({super.key, this.initialTab = 0});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialTab;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final courses = context.read<CoursesProvider>();
      if (courses.courses.isEmpty && !courses.isLoading) {
        courses.fetchCourses();
      }
    });
  }

  Future<void> _confirmLogout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Cerrar Sesión',
          style: GoogleFonts.playfairDisplay(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AndeanColors.deep,
          ),
        ),
        content: Text(
          '¿Estás seguro de que deseas salir de tu cuenta de promotor?',
          style: GoogleFonts.inter(fontSize: 13, color: AndeanColors.ink),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(
              'Cancelar',
              style: GoogleFonts.inter(color: AndeanColors.muted),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFD32F2F),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(
              'Cerrar Sesión',
              style: GoogleFonts.inter(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      await context.read<AuthProvider>().logout();
    }
  }

  void _openQrScanner() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (ctx) => const QrScannerScreen(),
      ),
    );
  }

  String _formatDate(DateTime date) {
    const months = [
      'ene', 'feb', 'mar', 'abr', 'may', 'jun',
      'jul', 'ago', 'set', 'oct', 'nov', 'dic'
    ];
    final monthName = months[date.month - 1];
    final hour = date.hour > 12 ? date.hour - 12 : (date.hour == 0 ? 12 : date.hour);
    final period = date.hour >= 12 ? 'p. m.' : 'a. m.';
    final minuteStr = date.minute.toString().padLeft(2, '0');
    return '${date.day} $monthName · $hour:$minuteStr $period';
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final config = context.watch<AppConfig>();
    final promoter = auth.currentPromoterUser;
    final fullName = promoter?.fullName ?? auth.currentUser?.fullName ?? 'Promotor Ambiental';
    final firstName = fullName.trim().split(' ').first;
    final categoryText = promoter != null ? promoter.promoterCategory.displayName : 'Promotor EDUCCA';
    final isCompact = MediaQuery.of(context).size.height < 740;

    return Scaffold(
      backgroundColor: AndeanColors.cream,
      body: Column(
        children: [
          // 1. Encabezado paisajístico andino institucional
          AndeanHeader(
            title: 'EDUCCA Cusco',
            isCompact: isCompact,
            trailing: IconButton(
              icon: const Icon(Icons.logout, color: Colors.white, size: 20),
              tooltip: 'Cerrar sesión',
              onPressed: () => _confirmLogout(context),
            ),
          ),

          // 2. Banner de Modo Demostración si está activo
          if (config.isDemoMode)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
              color: Colors.amber.shade800,
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.science_outlined, color: Colors.white, size: 14),
                  SizedBox(width: 6),
                  Text(
                    'MODO DEMOSTRACIÓN — DATOS SIMULADOS',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 10,
                      letterSpacing: 0.6,
                    ),
                  ),
                ],
              ),
            ),

          // 3. Contenido según la pestaña seleccionada
          Expanded(
            child: _buildCurrentTab(
              auth: auth,
              config: config,
              firstName: firstName,
              fullName: fullName,
              categoryText: categoryText,
              isCompact: isCompact,
            ),
          ),
        ],
      ),
      bottomNavigationBar: AndeanBottomNavigation(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
      ),
    );
  }

  Widget _buildCurrentTab({
    required AuthProvider auth,
    required AppConfig config,
    required String firstName,
    required String fullName,
    required String categoryText,
    required bool isCompact,
  }) {
    switch (_currentIndex) {
      case 1:
        return const CoursesScreen();
      case 2:
        return const AttendanceHistoryScreen();
      case 3:
        return _buildProfileTab(auth, config, fullName, categoryText, isCompact);
      case 0:
      default:
        return _buildDashboardTab(
          auth: auth,
          firstName: firstName,
          categoryText: categoryText,
          isCompact: isCompact,
        );
    }
  }

  /// Pestaña Inicio (Dashboard M03 de Figma)
  Widget _buildDashboardTab({
    required AuthProvider auth,
    required String firstName,
    required String categoryText,
    required bool isCompact,
  }) {
    final coursesProvider = context.watch<CoursesProvider>();
    final nextCourse = coursesProvider.courses.isNotEmpty ? coursesProvider.courses.first : null;

    final nextActivityTitle = nextCourse?.title ?? 'Segregación en la fuente';
    final nextActivityDate = nextCourse != null
        ? _formatDate(nextCourse.startDate)
        : 'Sáb 21 nov · 9:00 a. m.';
    final nextActivityVenue = nextCourse?.instructorName != null
        ? 'Docente: ${nextCourse!.instructorName}'
        : 'Centro Cultural Cusco';

    return SafeArea(
      top: false,
      child: SingleChildScrollView(
        padding: EdgeInsets.symmetric(
          horizontal: 24,
          vertical: isCompact ? 10 : 16,
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 360),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Saludo y nombre del promotor en Playfair Display
                Text(
                  'Allin hamuy,',
                  style: GoogleFonts.playfairDisplay(
                    fontSize: isCompact ? 22 : 24,
                    fontWeight: FontWeight.bold,
                    color: AndeanColors.deep,
                    height: 1.15,
                  ),
                ),
                Text(
                  firstName,
                  style: GoogleFonts.playfairDisplay(
                    fontSize: isCompact ? 26 : 30,
                    fontStyle: FontStyle.italic,
                    color: AndeanColors.forest,
                    height: 1.15,
                  ),
                ),
                SizedBox(height: isCompact ? 8 : 10),

                // Insignia de categoría promotora
                Align(
                  alignment: Alignment.centerLeft,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                    decoration: BoxDecoration(
                      color: AndeanColors.chipSelectedBg,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text(
                      'PROMOTOR ${categoryText.toUpperCase()}',
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: AndeanColors.forest,
                        letterSpacing: 0.6,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: isCompact ? 10 : 14),

                // Subtítulo de actividad
                Text(
                  'Tu próxima actividad ambiental',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AndeanColors.muted,
                  ),
                ),
                SizedBox(height: isCompact ? 8 : 10),

                // Tarjeta: Próxima actividad
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AndeanColors.surface,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: AndeanColors.line, width: 1),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 18,
                            height: 2,
                            color: AndeanColors.terracotta,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'PRÓXIMA ACTIVIDAD',
                            style: GoogleFonts.inter(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w600,
                              color: AndeanColors.terracotta,
                              letterSpacing: 0.8,
                            ),
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                            decoration: BoxDecoration(
                              color: AndeanColors.chipSelectedBg,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              'Inscrita',
                              style: GoogleFonts.inter(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: AndeanColors.forest,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        nextActivityTitle,
                        style: GoogleFonts.playfairDisplay(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: AndeanColors.deep,
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Divider(color: AndeanColors.line, thickness: 1, height: 1),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          const Icon(Icons.calendar_today_outlined, size: 14, color: AndeanColors.muted),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              nextActivityDate,
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: AndeanColors.muted,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 5),
                      Row(
                        children: [
                          const Icon(Icons.place_outlined, size: 14, color: AndeanColors.muted),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              nextActivityVenue,
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: AndeanColors.muted,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                SizedBox(height: isCompact ? 14 : 18),

                // Botón principal: Escanear QR de asistencia
                SizedBox(
                  width: double.infinity,
                  height: isCompact ? 48 : 52,
                  child: ElevatedButton(
                    key: const Key('quickScanButton'),
                    onPressed: _openQrScanner,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AndeanColors.brand,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.qr_code_scanner, color: Colors.white, size: 18),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            'Escanear QR de asistencia',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: isCompact ? 16 : 22),

                // Sección: Accesos Rápidos
                Text(
                  'ACCESOS RÁPIDOS',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AndeanColors.terracotta,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 10),

                // Fila de dos accesos rápidos
                Row(
                  children: [
                    Expanded(
                      child: _buildQuickAccessCard(
                        iconPath: 'assets/images/icono_card_talleres.svg',
                        title: 'Mis talleres',
                        subtitle: 'Ver capacitaciones',
                        onTap: () => setState(() => _currentIndex = 1),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildQuickAccessCard(
                        iconPath: 'assets/images/icono_card_asistencias.svg',
                        title: 'Mis asistencias',
                        subtitle: 'Ver historial en sede',
                        onTap: () => setState(() => _currentIndex = 2),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Tarjeta de acceso rápido (EduccaAccesoRapidoDestino de Figma)
  Widget _buildQuickAccessCard({
    required String iconPath,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        height: 104,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AndeanColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFDCE5DF), width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SvgPicture.asset(
              iconPath,
              width: 22,
              height: 22,
            ),
            const SizedBox(height: 10),
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF202B26),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(
                fontSize: 11,
                color: AndeanColors.muted,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Pestaña Perfil (Datos del promotor, configuración de servidor y logout)
  Widget _buildProfileTab(
    AuthProvider auth,
    AppConfig config,
    String fullName,
    String categoryText,
    bool isCompact,
  ) {
    return SafeArea(
      top: false,
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 360),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: CircleAvatar(
                    radius: 36,
                    backgroundColor: AndeanColors.brand,
                    child: Text(
                      fullName.isNotEmpty ? fullName[0].toUpperCase() : 'P',
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  fullName,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AndeanColors.deep,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  auth.currentUser?.email ?? '',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(fontSize: 13, color: AndeanColors.muted),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AndeanColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AndeanColors.line, width: 1),
                  ),
                  child: Column(
                    children: [
                      _buildProfileRow('Rol', 'Promotor Ambiental'),
                      const Divider(color: AndeanColors.line, height: 20),
                      _buildProfileRow('Categoría', categoryText),
                      const Divider(color: AndeanColors.line, height: 20),
                      _buildProfileRow('Servidor', config.baseUrl),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                if (kDebugMode && config.isDemoMode) ...[
                  ElevatedButton.icon(
                    key: const Key('demoTourButton'),
                    onPressed: () => DemoTourSheet.show(context),
                    icon: const Icon(Icons.slideshow_outlined, size: 18),
                    label: const Text('Recorrido de Demostración (Sprint 1)'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF176B53),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
                OutlinedButton.icon(
                  onPressed: () => ServerConfigDialog.show(context, config),
                  icon: const Icon(Icons.settings_ethernet, size: 18),
                  label: const Text('Configurar Servidor / Modo Demo'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AndeanColors.forest,
                    side: const BorderSide(color: AndeanColors.forest),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: () => PrivacyConsentDialog.show(context),
                  icon: const Icon(Icons.privacy_tip_outlined, size: 18),
                  label: const Text('Aviso de Privacidad (LPDP N.° 29733)'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AndeanColors.forest,
                    side: const BorderSide(color: AndeanColors.line),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: () => _confirmLogout(context),
                  icon: const Icon(Icons.logout, size: 18),
                  label: const Text('Cerrar Sesión'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFD32F2F),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AndeanColors.ink,
          ),
        ),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(
              fontSize: 12.5,
              color: AndeanColors.muted,
            ),
          ),
        ),
      ],
    );
  }
}
