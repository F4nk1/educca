import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../config/app_config.dart';
import '../models/course_session.dart';
import 'verification_screen.dart';
import 'widgets/andean_widgets.dart';

/// Pantalla M05: Consentimiento y explicación de ubicación GPS puntual (Figma 2:110).
///
/// Principios (RNF-01 / HU-04):
/// - Explica de forma transparente la captura puntual de coordenadas para verificar la presencia en sede (radio ≤ 80 m).
/// - Asegura explícitamente al promotor que NO hay rastreo continuo ni en segundo plano.
/// - Permite avanzar hacia la verificación (M06) o rechazar/volver a la pantalla anterior.
class LocationConsentScreen extends StatelessWidget {
  final String qrToken;
  final CourseSession? targetSession;

  const LocationConsentScreen({
    super.key,
    required this.qrToken,
    this.targetSession,
  });

  @override
  Widget build(BuildContext context) {
    final config = context.watch<AppConfig>();
    final isDemoMode = config.isDemoMode;

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
                      'PRIVACIDAD Y UBICACIÓN',
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
                      'Permitir ubicación',
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: AndeanColors.deep,
                        height: 1.15,
                      ),
                    ),
                    const SizedBox(height: 6),

                    // Subtítulo
                    Text(
                      'Usaremos tu ubicación únicamente cuando registres asistencia.',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: AndeanColors.muted,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Tarjeta explicativa de GPS
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(19),
                        border: Border.all(color: const Color(0xFFDCD2C1)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withAlpha(10),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Icono de Pin
                          SvgPicture.asset(
                            'assets/images/icono_gps_pin.svg',
                            width: 32,
                            height: 32,
                            colorFilter: const ColorFilter.mode(
                              AndeanColors.forest,
                              BlendMode.srcIn,
                            ),
                          ),
                          const SizedBox(height: 14),

                          // Título de la tarjeta
                          Text(
                            'Verificaremos que estés cerca de la sede.',
                            style: GoogleFonts.inter(
                              fontSize: 17,
                              fontWeight: FontWeight.w600,
                              color: AndeanColors.ink,
                              height: 1.25,
                            ),
                          ),
                          const SizedBox(height: 8),

                          // Descripción técnica transparente
                          Text(
                            'El servidor comprobará que tu ubicación se encuentre a 80 metros o menos de la sede oficial de la actividad ambiental.',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              color: AndeanColors.muted,
                              height: 1.35,
                            ),
                          ),
                          const SizedBox(height: 14),

                          // Etiqueta de permiso puntual
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE4F1EB),
                              borderRadius: BorderRadius.circular(15),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.check_circle_outline,
                                  size: 14,
                                  color: Color(0xFF15563F),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'GPS solo durante el registro puntual',
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF15563F),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Garantía de no rastreo
                    Row(
                      children: [
                        const Icon(
                          Icons.shield_outlined,
                          size: 16,
                          color: AndeanColors.muted,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'No realizamos seguimiento continuo ni en segundo plano.',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: AndeanColors.muted,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Botón principal: Continuar y permitir ubicación
                    AndeanButton(
                      text: 'Continuar y permitir ubicación',
                      key: const Key('allowLocationButton'),
                      onPressed: () {
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute(
                            builder: (_) => VerificationScreen(
                              qrToken: qrToken,
                              targetSession: targetSession,
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 10),

                    // Botón secundario: No permitir / Volver
                    AndeanButton(
                      text: 'No permitir / Volver',
                      isSecondary: true,
                      key: const Key('denyLocationButton'),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    const SizedBox(height: 16),

                    // Pie informativo
                    Center(
                      child: Text(
                        'Puedes revocar o cambiar este permiso en cualquier momento desde los ajustes de Android.',
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
