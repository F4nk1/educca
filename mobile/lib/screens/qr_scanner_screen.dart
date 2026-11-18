import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import '../config/app_config.dart';
import '../models/course_session.dart';
import 'location_consent_screen.dart';
import 'widgets/andean_widgets.dart';

/// Pantalla M04: Escáner QR con tema andino EDUCCA Cusco (Figma 2:94).
///
/// Principios:
/// - Solicita cámara exclusivamente al ingresar a esta vista.
/// - Detiene la captura ante la primera lectura para evitar lecturas duplicadas (RNF-01).
/// - En modo demostración (debug), ofrece botón para «Simular lectura QR».
/// - Transfiere el token escaneado a M05 (Permiso y Explicación de Ubicación GPS).
class QrScannerScreen extends StatefulWidget {
  final CourseSession? targetSession;

  const QrScannerScreen({super.key, this.targetSession});

  @override
  State<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends State<QrScannerScreen> {
  final MobileScannerController _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    facing: CameraFacing.back,
  );

  bool _isProcessing = false;
  bool _torchActive = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_isProcessing) return;

    final barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;

    final rawValue = barcodes.first.rawValue;
    if (rawValue == null || rawValue.trim().isEmpty) return;

    _handleTokenAcquired(rawValue.trim());
  }

  void _handleTokenAcquired(String qrToken) {
    if (_isProcessing) return;

    setState(() {
      _isProcessing = true;
    });

    _controller.stop();

    Navigator.of(context)
        .push(
      MaterialPageRoute(
        builder: (_) => LocationConsentScreen(
          qrToken: qrToken,
          targetSession: widget.targetSession,
        ),
      ),
    )
        .then((_) {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
        _controller.start();
      }
    });
  }

  void _showManualInputDialog() {
    final textController = TextEditingController(text: 'EDUCCA-SES-301-DEMO');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AndeanColors.cream,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Ingreso manual de token',
          style: GoogleFonts.playfairDisplay(
            fontWeight: FontWeight.bold,
            color: AndeanColors.deep,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Herramienta de prueba para entornos sin cámara física.',
              style: GoogleFonts.inter(fontSize: 12, color: AndeanColors.muted),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: textController,
              decoration: andeanInputDecoration(
                hintText: 'Ej. EDUCCA-SES-301-DEMO',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              'Cancelar',
              style: GoogleFonts.inter(color: AndeanColors.muted),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AndeanColors.brand,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              final text = textController.text.trim();
              if (text.isNotEmpty) {
                Navigator.of(ctx).pop();
                _handleTokenAcquired(text);
              }
            },
            child: Text('Continuar', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final config = context.watch<AppConfig>();
    final isDemoMode = kDebugMode && config.isDemoMode;

    return Scaffold(
      backgroundColor: AndeanColors.cream,
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            // Encabezado compacto
            AndeanHeader(
              compact: true,
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: Icon(
                      _torchActive ? Icons.flash_on : Icons.flash_off,
                      color: Colors.white,
                      size: 22,
                    ),
                    tooltip: 'Linterna',
                    onPressed: () {
                      _controller.toggleTorch();
                      setState(() {
                        _torchActive = !_torchActive;
                      });
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.keyboard_outlined, color: Colors.white, size: 22),
                    tooltip: 'Ingresar token manualmente',
                    onPressed: _showManualInputDialog,
                  ),
                ],
              ),
            ),

            if (isDemoMode) const AndeanDemoBanner(),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Tag superior terracota
                    Text(
                      'REGISTRO DE ASISTENCIA',
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
                      'Escanear código QR',
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
                      widget.targetSession != null
                          ? 'Enfoca el QR de la sesión: ${widget.targetSession!.title}'
                          : 'Enfoca el QR mostrado por tu capacitador ambiental.',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: AndeanColors.muted,
                      ),
                    ),
                    const SizedBox(height: 18),

                    // Contenedor Visor de Cámara Andino
                    Container(
                      height: 275,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: AndeanColors.deep,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withAlpha(35),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          MobileScanner(
                            controller: _controller,
                            onDetect: _onDetect,
                            errorBuilder: (context, error) {
                              return Center(
                                child: Padding(
                                  padding: const EdgeInsets.all(20),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.camera_alt_outlined,
                                        size: 48,
                                        color: Colors.white70,
                                      ),
                                      const SizedBox(height: 12),
                                      Text(
                                        'Visor no disponible',
                                        style: GoogleFonts.inter(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Utiliza la simulación o el ingreso manual de token.',
                                        textAlign: TextAlign.center,
                                        style: GoogleFonts.inter(
                                          color: Colors.white70,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),

                          // Marco gráfico de enfoque
                          Positioned(
                            top: 20,
                            child: SvgPicture.asset(
                              'assets/images/icono_scan_qr.svg',
                              width: 28,
                              height: 28,
                              colorFilter: const ColorFilter.mode(
                                Colors.white70,
                                BlendMode.srcIn,
                              ),
                            ),
                          ),

                          Container(
                            width: 200,
                            height: 170,
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: AndeanColors.brand.withAlpha(200),
                                width: 2.5,
                              ),
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),

                          Positioned(
                            bottom: 12,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.black.withAlpha(140),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                'Cámara activa · Enfoque puntual',
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Nota de validación servidor
                    Text(
                      'El código QR y tu ubicación puntual se verificarán en el servidor.',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AndeanColors.muted,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Botón de simulación (siempre disponible en modo demo)
                    if (isDemoMode) ...[
                      AndeanButton(
                        text: 'Simular lectura QR',
                        key: const Key('simulateScanButton'),
                        onPressed: () => _handleTokenAcquired('EDUCCA-SES-301-DEMO'),
                      ),
                      const SizedBox(height: 10),
                    ],

                    // Botón secundario para volver
                    AndeanButton(
                      text: 'Volver',
                      isSecondary: true,
                      onPressed: () => Navigator.of(context).pop(),
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
