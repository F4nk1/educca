import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../config/app_config.dart';
import '../models/attendance_models.dart';
import '../models/course_session.dart';
import 'home_screen.dart';
import 'qr_scanner_screen.dart';
import 'widgets/andean_widgets.dart';

/// Pantalla M07 / M08: Resultado definitivo de asistencia con tema andino (Figma 2:141 y 2:221–2:311).
///
/// Principios:
/// - Si el resultado es exitoso (`isSuccess`), renderiza M07 con la constancia y comprobante de sesión.
/// - Si el resultado es de rechazo o error, renderiza la variante correspondiente de M08 (E01 a E07).
/// - En modo demostración, etiqueta claramente que los datos son simulados.
/// - Provee navegación directa para volver al inicio o saltar al historial de asistencias.
class AttendanceResultScreen extends StatelessWidget {
  final AttendanceScanResult result;
  final CourseSession? targetSession;

  const AttendanceResultScreen({
    super.key,
    required this.result,
    this.targetSession,
  });

  String _formatDateTime(DateTime dt) {
    const months = [
      'ene', 'feb', 'mar', 'abr', 'may', 'jun',
      'jul', 'ago', 'set', 'oct', 'nov', 'dic'
    ];
    final hour = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
    final period = dt.hour >= 12 ? 'p. m.' : 'a. m.';
    final min = dt.minute.toString().padLeft(2, '0');
    return '${dt.day} ${months[dt.month - 1]} · $hour:$min $period';
  }

  void _navigateToTab(BuildContext context, int tabIndex) {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => HomeScreen(initialTab: tabIndex),
      ),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final config = context.watch<AppConfig>();
    final isDemoMode = config.isDemoMode;

    if (result.isSuccess) {
      return _buildSuccessM07(context, isDemoMode);
    } else {
      return _buildErrorM08(context, isDemoMode);
    }
  }

  // =========================================================================
  // M07: Confirmación exitosa
  // =========================================================================
  Widget _buildSuccessM07(BuildContext context, bool isDemoMode) {
    final record = result.record;
    final courseTitle = record?.courseTitle ??
        targetSession?.title ??
        'Segregación en la fuente y reciclaje';
    final venueName = record?.venueName ??
        targetSession?.location ??
        'Centro Cultural Cusco (Radio ≤ 80 m)';
    final markedAt = record?.markedAt ?? DateTime.now();

    return Scaffold(
      backgroundColor: AndeanColors.cream,
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            const AndeanHeader(compact: true),
            if (isDemoMode) const AndeanDemoBanner(),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Tag superior
                    Text(
                      'RESULTADO DE ASISTENCIA',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AndeanColors.terracotta,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 6),

                    // Título principal en Playfair Display
                    Text(
                      'Asistencia registrada',
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: AndeanColors.deep,
                        height: 1.15,
                      ),
                    ),
                    const SizedBox(height: 18),

                    // Tarjeta de confirmación verde suave (Figma #ded)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
                      decoration: BoxDecoration(
                        color: const Color(0xFFDED0B3).withAlpha(120), // Tono orgánico suave
                        borderRadius: BorderRadius.circular(19),
                        border: Border.all(color: const Color(0xFFC8DEC9)),
                      ),
                      child: Column(
                        children: [
                          SvgPicture.asset(
                            'assets/images/icono_check_confirmado.svg',
                            width: 48,
                            height: 48,
                            colorFilter: const ColorFilter.mode(
                              AndeanColors.forest,
                              BlendMode.srcIn,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Registro confirmado',
                            style: GoogleFonts.inter(
                              fontSize: 19,
                              fontWeight: FontWeight.w700,
                              color: AndeanColors.deep,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            isDemoMode
                                ? 'Asistencia simulada registrada con datos de demostración.'
                                : 'El servidor confirmó tu asistencia y presencia en sede.',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              color: AndeanColors.forest,
                              height: 1.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Tarjeta de comprobante del taller
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: const Color(0xFFDCD2C1)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'TALLER AMBIENTAL',
                            style: GoogleFonts.inter(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                              color: AndeanColors.terracotta,
                              letterSpacing: 0.8,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            courseTitle,
                            style: GoogleFonts.playfairDisplay(
                              fontSize: 19,
                              fontWeight: FontWeight.bold,
                              color: AndeanColors.deep,
                            ),
                          ),
                          const SizedBox(height: 12),
                          const Divider(color: Color(0xFFDCD2C1), height: 1),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              const Icon(Icons.event_outlined, size: 16, color: AndeanColors.muted),
                              const SizedBox(width: 8),
                              Text(
                                _formatDateTime(markedAt),
                                style: GoogleFonts.inter(fontSize: 12.5, color: AndeanColors.muted),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(Icons.place_outlined, size: 16, color: AndeanColors.muted),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  venueName,
                                  style: GoogleFonts.inter(fontSize: 12.5, color: AndeanColors.muted),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Botones de acción
                    AndeanButton(
                      text: 'Volver al inicio',
                      key: const Key('backToHomeButton'),
                      onPressed: () => _navigateToTab(context, 0),
                    ),
                    const SizedBox(height: 10),
                    AndeanButton(
                      text: 'Ver mis asistencias',
                      isSecondary: true,
                      key: const Key('viewAttendancesButton'),
                      onPressed: () => _navigateToTab(context, 2),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // =========================================================================
  // M08: Estados de error y rechazo (E01 a E07)
  // =========================================================================
  Widget _buildErrorM08(BuildContext context, bool isDemoMode) {
    late final String tagText;
    late final String headlineText;
    late final String cardTitle;
    late final String cardDescription;
    late final String primaryButtonText;
    late final VoidCallback onPrimaryAction;

    switch (result.outcome) {
      case ScanOutcome.outOfRange:
        tagText = 'VALIDACIÓN DE ASISTENCIA · E01';
        headlineText = 'Estás fuera del área de asistencia';
        cardTitle = 'Distancia no permitida';
        cardDescription =
            'Tu ubicación se encuentra a más de 80 metros de la sede programada. Acércate a la sede para registrar tu asistencia.';
        primaryButtonText = 'Volver a comprobar';
        onPrimaryAction = () => Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => const QrScannerScreen()),
            );
        break;

      case ScanOutcome.expired:
        tagText = 'VALIDACIÓN DE ASISTENCIA · E02';
        headlineText = 'El código QR venció';
        cardTitle = 'Código QR expirado';
        cardDescription =
            'El código QR proyectado ha caducado por motivos de seguridad. Solicita a tu capacitador que actualice el código en pantalla.';
        primaryButtonText = 'Escanear nuevo QR';
        onPrimaryAction = () => Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => const QrScannerScreen()),
            );
        break;

      case ScanOutcome.duplicate:
        tagText = 'VALIDACIÓN DE ASISTENCIA · E03';
        headlineText = 'Asistencia ya registrada';
        cardTitle = 'Registro duplicado';
        cardDescription =
            'Tu asistencia a esta sesión ambiental ya fue constatada previamente. Puedes consultar tu constancia en el historial.';
        primaryButtonText = 'Ver mis asistencias';
        onPrimaryAction = () => _navigateToTab(context, 2);
        break;

      case ScanOutcome.sessionClosed:
      case ScanOutcome.unauthorized:
        tagText = 'VALIDACIÓN DE ASISTENCIA · E04';
        headlineText = 'Sesión no disponible';
        cardTitle = 'No habilitado para la sesión';
        cardDescription = result.message.isNotEmpty
            ? result.message
            : 'El periodo de asistencia ha concluido o no te encuentras inscrito en este taller.';
        primaryButtonText = 'Consultar mis talleres';
        onPrimaryAction = () => _navigateToTab(context, 1);
        break;

      case ScanOutcome.permissionDenied:
      case ScanOutcome.gpsDisabled:
      case ScanOutcome.gpsTimeout:
        tagText = 'VALIDACIÓN DE ASISTENCIA · E05';
        headlineText = 'Ubicación no disponible';
        cardTitle = 'Sensor o permiso GPS';
        cardDescription =
            'No fue posible obtener coordenadas válidas. Asegúrate de encender el GPS y conceder el permiso de ubicación puntual a la aplicación.';
        primaryButtonText = 'Reintentar escaneo';
        onPrimaryAction = () => Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => const QrScannerScreen()),
            );
        break;

      case ScanOutcome.networkError:
        tagText = 'VALIDACIÓN DE ASISTENCIA · E06';
        headlineText = 'No hay conexión';
        cardTitle = 'Fallo de conectividad';
        cardDescription =
            'No se pudo comunicar con el servidor de EDUCCA Cusco. Verifica tu conexión de red móvil, Wi-Fi o la IP configurada.';
        primaryButtonText = 'Reintentar conexión';
        onPrimaryAction = () => Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => const QrScannerScreen()),
            );
        break;

      case ScanOutcome.locationInaccurate:
      default:
        tagText = 'VALIDACIÓN DE ASISTENCIA · E07';
        headlineText = 'Precisión GPS insuficiente';
        cardTitle = 'Señal satelital débil';
        cardDescription =
            'La precisión obtenida fue superior a 50 metros. Acércate a un espacio abierto para fijar una señal satelital óptima.';
        primaryButtonText = 'Volver a comprobar';
        onPrimaryAction = () => Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => const QrScannerScreen()),
            );
        break;
    }

    return Scaffold(
      backgroundColor: AndeanColors.cream,
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            const AndeanHeader(compact: true),
            if (isDemoMode) const AndeanDemoBanner(),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Tag E0X
                    Text(
                      tagText,
                      style: GoogleFonts.inter(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        color: AndeanColors.terracotta,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 6),

                    // Título de error en Playfair Display
                    Text(
                      headlineText,
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AndeanColors.deep,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Tarjeta de resultado de error
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: const Color(0xFFDCD2C1)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SvgPicture.asset(
                            'assets/images/icono_resultado_alerta.svg',
                            width: 36,
                            height: 36,
                            colorFilter: const ColorFilter.mode(
                              AndeanColors.terracotta,
                              BlendMode.srcIn,
                            ),
                          ),
                          const SizedBox(height: 14),
                          Text(
                            cardTitle,
                            style: GoogleFonts.inter(
                              fontSize: 17,
                              fontWeight: FontWeight.w600,
                              color: AndeanColors.ink,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            cardDescription,
                            style: GoogleFonts.inter(
                              fontSize: 13.5,
                              color: AndeanColors.muted,
                              height: 1.35,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Botón primario de acción
                    AndeanButton(
                      text: primaryButtonText,
                      key: const Key('retryActionButton'),
                      onPressed: onPrimaryAction,
                    ),
                    const SizedBox(height: 10),

                    // Botón secundario para volver al inicio
                    AndeanButton(
                      text: 'Volver al inicio',
                      isSecondary: true,
                      key: const Key('backToHomeSecondaryButton'),
                      onPressed: () => _navigateToTab(context, 0),
                    ),
                    const SizedBox(height: 20),

                    Center(
                      child: Text(
                        'La asistencia depende de la validación del servidor.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: AndeanColors.muted,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
