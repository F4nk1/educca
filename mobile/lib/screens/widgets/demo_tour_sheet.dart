import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../config/app_config.dart';
import '../../models/attendance_models.dart';
import '../../providers/attendance_provider.dart';
import '../../repositories/mock_educca_repository.dart';
import '../attendance_result_screen.dart';
import '../location_consent_screen.dart';
import '../qr_scanner_screen.dart';
import 'andean_widgets.dart';

/// Hoja modal de control para el «Recorrido de Demostración» (Sprint 1).
///
/// REQUISITO CRÍTICO:
/// - Disponible EXCLUSIVAMENTE en [kDebugMode] cuando [AppConfig.isDemoMode] esté activo.
/// - Nunca expuesto en compilaciones de producción.
/// - Utiliza las pantallas REALES de la aplicación (M04, M05, M06, M07, M08).
class DemoTourSheet extends StatelessWidget {
  const DemoTourSheet({super.key});

  static Future<void> show(BuildContext context) {
    if (!kDebugMode) return Future.value();

    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const DemoTourSheet(),
    );
  }

  void _launchDirectOutcome(BuildContext context, ScanOutcome outcome) {
    final provider = context.read<AttendanceProvider>();
    final repo = provider.repository;

    if (repo is MockEduccaRepository) {
      repo.forceOutcome(outcome);
    }

    final dummyRecord = outcome == ScanOutcome.success || outcome == ScanOutcome.duplicate
        ? AttendanceRecord(
            id: 'demo-tour-001',
            sessionId: 'ses-educca-301',
            sessionTitle: 'Taller: Segregación en la fuente',
            courseTitle: 'Educación Ambiental EDUCCA Cusco (Datos de demostración)',
            venueName: 'Centro Cultural Cusco (Simulación ≤ 80 m)',
            markedAt: DateTime.now(),
            status: 'CONFIRMED',
          )
        : null;

    final result = AttendanceScanResult(
      outcome: outcome,
      message: 'Escenario simulado activado para evaluación.',
      record: dummyRecord,
    );

    Navigator.of(context).pop(); // Cierra el modal
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AttendanceResultScreen(result: result),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final config = context.watch<AppConfig>();
    if (!kDebugMode || !config.isDemoMode) {
      return const SizedBox.shrink();
    }

    final provider = context.watch<AttendanceProvider>();

    return Container(
      decoration: const BoxDecoration(
        color: AndeanColors.cream,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Barra de arrastre
          Center(
            child: Container(
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFDCD2C1),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Título del recorrido
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5A623).withAlpha(40),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: const Color(0xFFF5A623)),
                ),
                child: Text(
                  'EXPOSICIÓN SPRINT 1',
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFFB37400),
                  ),
                ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.close, size: 20),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          const SizedBox(height: 8),

          Text(
            'Recorrido de demostración',
            style: GoogleFonts.playfairDisplay(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AndeanColors.deep,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Selecciona el escenario que deseas exhibir utilizando las pantallas reales de la aplicación.',
            style: GoogleFonts.inter(fontSize: 12.5, color: AndeanColors.muted),
          ),
          const SizedBox(height: 16),
          const Divider(color: Color(0xFFDCD2C1), height: 1),
          const SizedBox(height: 12),

          Expanded(
            child: ListView(
              children: [
                // 1. Flujo completo interactivo
                _buildTourItem(
                  icon: Icons.play_circle_fill_outlined,
                  iconColor: AndeanColors.brand,
                  title: '1. Flujo completo guiado (M04 → M07)',
                  subtitle: 'Escanear QR simulado, autorizar GPS y validar en servidor',
                  onTap: () {
                    Navigator.of(context).pop();
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const QrScannerScreen(),
                      ),
                    );
                  },
                ),

                // 2. M05: Explicación de ubicación
                _buildTourItem(
                  icon: Icons.place_outlined,
                  iconColor: AndeanColors.forest,
                  title: '2. Pantalla M05 · Ubicación y Privacidad',
                  subtitle: 'Transparencia de geocerca (≤ 80 m) sin rastreo de fondo',
                  onTap: () {
                    Navigator.of(context).pop();
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const LocationConsentScreen(
                          qrToken: 'EDUCCA-SES-301-DEMO',
                        ),
                      ),
                    );
                  },
                ),

                // 3. M07: Confirmación
                _buildTourItem(
                  icon: Icons.check_circle_outline,
                  iconColor: const Color(0xFF15563F),
                  title: '3. Pantalla M07 · Asistencia registrada',
                  subtitle: 'Confirmación exitosa con comprobante del taller',
                  onTap: () => _launchDirectOutcome(context, ScanOutcome.success),
                ),

                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    'VARIANTES DE RECHAZO (M08):',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: AndeanColors.terracotta,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),

                // M08-E01
                _buildTourItem(
                  icon: Icons.wrong_location_outlined,
                  iconColor: AndeanColors.terracotta,
                  title: 'E01 · Fuera del área de asistencia',
                  subtitle: 'Distancia a la sede superior a 80 metros',
                  onTap: () => _launchDirectOutcome(context, ScanOutcome.outOfRange),
                ),

                // M08-E02
                _buildTourItem(
                  icon: Icons.timer_off_outlined,
                  iconColor: AndeanColors.terracotta,
                  title: 'E02 · Código QR vencido',
                  subtitle: 'El token dinámico caducó en la proyección web',
                  onTap: () => _launchDirectOutcome(context, ScanOutcome.expired),
                ),

                // M08-E03
                _buildTourItem(
                  icon: Icons.history,
                  iconColor: const Color(0xFFB37400),
                  title: 'E03 · Asistencia ya registrada',
                  subtitle: 'Constancia de duplicado determinista',
                  onTap: () => _launchDirectOutcome(context, ScanOutcome.duplicate),
                ),

                // M08-E04
                _buildTourItem(
                  icon: Icons.event_busy_outlined,
                  iconColor: AndeanColors.terracotta,
                  title: 'E04 · Sesión no disponible / No inscrito',
                  subtitle: 'Período cerrado o usuario no matriculado',
                  onTap: () => _launchDirectOutcome(context, ScanOutcome.unauthorized),
                ),

                // M08-E05
                _buildTourItem(
                  icon: Icons.location_disabled_outlined,
                  iconColor: AndeanColors.terracotta,
                  title: 'E05 · Ubicación no disponible',
                  subtitle: 'Permiso denegado o sensor GPS apagado',
                  onTap: () => _launchDirectOutcome(context, ScanOutcome.permissionDenied),
                ),

                // M08-E06
                _buildTourItem(
                  icon: Icons.wifi_off_outlined,
                  iconColor: AndeanColors.terracotta,
                  title: 'E06 · No hay conexión con el servidor',
                  subtitle: 'Fallo de conectividad de red',
                  onTap: () => _launchDirectOutcome(context, ScanOutcome.networkError),
                ),

                // M08-E07
                _buildTourItem(
                  icon: Icons.gps_not_fixed_outlined,
                  iconColor: AndeanColors.terracotta,
                  title: 'E07 · Precisión GPS insuficiente',
                  subtitle: 'Imprecisión satelital mayor a 50 metros',
                  onTap: () => _launchDirectOutcome(context, ScanOutcome.locationInaccurate),
                ),

                const SizedBox(height: 16),
                const Divider(color: Color(0xFFDCD2C1)),
                const SizedBox(height: 8),

                // Botón de restablecer historial
                TextButton.icon(
                  onPressed: () {
                    final repo = provider.repository;
                    if (repo is MockEduccaRepository) {
                      repo.resetMockHistory();
                      provider.fetchHistory();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Historial simulado restablecido a su estado inicial.'),
                        ),
                      );
                    }
                  },
                  icon: const Icon(Icons.refresh, color: AndeanColors.forest),
                  label: Text(
                    'Restablecer datos de demostración',
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w600,
                      color: AndeanColors.forest,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTourItem({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFDCD2C1)),
      ),
      child: ListTile(
        leading: Icon(icon, color: iconColor),
        title: Text(
          title,
          style: GoogleFonts.inter(fontSize: 13.5, fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          subtitle,
          style: GoogleFonts.inter(fontSize: 11.5, color: AndeanColors.muted),
        ),
        trailing: const Icon(Icons.chevron_right, size: 20, color: AndeanColors.muted),
        onTap: onTap,
      ),
    );
  }
}
