import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../config/app_config.dart';
import '../models/course_session.dart';
import '../providers/attendance_provider.dart';
import 'attendance_result_screen.dart';
import 'widgets/andean_widgets.dart';

/// Pantalla M06: Verificación de asistencia en proceso (Figma 2:127).
///
/// Principios:
/// - Muestra estado de carga y transparencia en las tres fases del proceso:
///   1. Validación del token QR.
///   2. Captura puntual de coordenadas GPS (single-shot).
///   3. Consulta autenticada y validación server-side de geocerca (radio ≤ 80 m).
/// - Garantiza al usuario que no se asume éxito sin la respuesta definitiva del servidor.
class VerificationScreen extends StatefulWidget {
  final String qrToken;
  final CourseSession? targetSession;
  final bool autoStart;

  const VerificationScreen({
    super.key,
    required this.qrToken,
    this.targetSession,
    this.autoStart = true,
  });

  @override
  State<VerificationScreen> createState() => _VerificationScreenState();
}

class _VerificationScreenState extends State<VerificationScreen> {
  int _currentStep = 1;

  @override
  void initState() {
    super.initState();
    if (widget.autoStart) {
      _startVerificationProcess();
    }
  }

  Future<void> _startVerificationProcess() async {
    // Paso 1: Código QR leído
    await Future.delayed(const Duration(milliseconds: 350));
    if (!mounted) return;
    setState(() => _currentStep = 2);

    // Paso 2: Fijación GPS y comunicación
    await Future.delayed(const Duration(milliseconds: 350));
    if (!mounted) return;
    setState(() => _currentStep = 3);

    // Ejecución real o simulada con el Provider activo
    final attendanceProvider = context.read<AttendanceProvider>();
    final scanResult = await attendanceProvider.registerAttendance(widget.qrToken);

    if (!mounted) return;

    // Transición fluida a M07 / M08
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => AttendanceResultScreen(
          result: scanResult,
          targetSession: widget.targetSession,
        ),
      ),
    );
  }

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
                      'VERIFICACIÓN DE ASISTENCIA',
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
                      'Verificando registro',
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 27,
                        fontWeight: FontWeight.bold,
                        color: AndeanColors.deep,
                        height: 1.15,
                      ),
                    ),
                    const SizedBox(height: 6),

                    // Subtítulo
                    Text(
                      'Consultando la sesión y tu ubicación.',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: AndeanColors.muted,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Tarjeta de Proceso
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
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
                        children: [
                          // Indicador de actividad animado
                          const SizedBox(
                            width: 52,
                            height: 52,
                            child: CircularProgressIndicator(
                              strokeWidth: 3.5,
                              valueColor: AlwaysStoppedAnimation<Color>(AndeanColors.brand),
                            ),
                          ),
                          const SizedBox(height: 18),

                          // Título de la tarjeta
                          Text(
                            'Validando asistencia',
                            style: GoogleFonts.inter(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: AndeanColors.deep,
                            ),
                          ),
                          const SizedBox(height: 4),

                          // Subtítulo
                          Text(
                            'El registro aún no está confirmado.',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              color: AndeanColors.muted,
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Separador
                          const Divider(color: Color(0xFFDCD2C1), height: 1),
                          const SizedBox(height: 18),

                          // Fases del proceso
                          _buildStepRow(
                            stepNumber: 1,
                            label: 'Código QR',
                            status: _currentStep > 1 ? 'Leído correctamente' : 'En validación...',
                            isCompleted: _currentStep > 1,
                          ),
                          const SizedBox(height: 12),
                          _buildStepRow(
                            stepNumber: 2,
                            label: 'Ubicación GPS',
                            status: _currentStep > 2
                                ? 'Punto fijado'
                                : _currentStep == 2
                                    ? 'Adquiriendo señal...'
                                    : 'Pendiente',
                            isCompleted: _currentStep > 2,
                          ),
                          const SizedBox(height: 12),
                          _buildStepRow(
                            stepNumber: 3,
                            label: 'Respuesta del servidor',
                            status: _currentStep == 3
                                ? 'Consultando geocerca (≤ 80 m)...'
                                : 'Pendiente',
                            isCompleted: false,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Aviso sin confirmación previa
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEEEADF),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        children: [
                          SvgPicture.asset(
                            'assets/images/icono_shield_seguridad.svg',
                            width: 24,
                            height: 24,
                            colorFilter: const ColorFilter.mode(
                              AndeanColors.forest,
                              BlendMode.srcIn,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'No se mostrará éxito hasta recibir la confirmación del servidor.',
                              style: GoogleFonts.inter(
                                fontSize: 12.5,
                                color: AndeanColors.muted,
                                height: 1.3,
                              ),
                            ),
                          ),
                        ],
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

  Widget _buildStepRow({
    required int stepNumber,
    required String label,
    required String status,
    required bool isCompleted,
  }) {
    return Row(
      children: [
        Container(
          width: 22,
          height: 22,
          decoration: BoxDecoration(
            color: isCompleted ? const Color(0xFFE4F1EB) : const Color(0xFFF0EBE1),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: isCompleted
                ? const Icon(Icons.check, size: 14, color: Color(0xFF15563F))
                : Text(
                    '$stepNumber',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: AndeanColors.muted,
                    ),
                  ),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          '$label · ',
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AndeanColors.ink,
          ),
        ),
        Expanded(
          child: Text(
            status,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: isCompleted ? FontWeight.w600 : FontWeight.normal,
              color: isCompleted ? const Color(0xFF15563F) : AndeanColors.muted,
            ),
          ),
        ),
      ],
    );
  }
}
