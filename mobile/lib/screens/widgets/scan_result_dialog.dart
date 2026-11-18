import 'package:flutter/material.dart';
import '../../models/attendance_models.dart';

/// Diálogo modal con retroalimentación visual diferenciada según el resultado del escaneo.
class ScanResultDialog extends StatelessWidget {
  final AttendanceScanResult result;
  final VoidCallback? onDismiss;

  const ScanResultDialog({
    super.key,
    required this.result,
    this.onDismiss,
  });

  static Future<void> show(BuildContext context, AttendanceScanResult result) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => ScanResultDialog(result: result),
    );
  }

  String _formatDateTime(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} a las '
        '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}:${date.second.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    IconData icon;
    Color iconColor;
    String title;

    switch (result.outcome) {
      case ScanOutcome.success:
        icon = Icons.check_circle_outline;
        iconColor = const Color(0xFF00897B); // Verde azulado
        title = '¡Asistencia Registrada!';
        break;
      case ScanOutcome.duplicate:
        icon = Icons.info_outline;
        iconColor = const Color(0xFFF57C00); // Ámbar / naranja
        title = 'Asistencia Previa';
        break;
      case ScanOutcome.outOfRange:
        icon = Icons.wrong_location_outlined;
        iconColor = const Color(0xFFD32F2F); // Rojo
        title = 'Fuera del Área de Sede';
        break;
      case ScanOutcome.expired:
        icon = Icons.timer_off_outlined;
        iconColor = const Color(0xFFD32F2F); // Rojo
        title = 'Código QR Expirado';
        break;
      case ScanOutcome.sessionClosed:
        icon = Icons.event_busy;
        iconColor = Colors.grey.shade700;
        title = 'Sesión Concluida';
        break;
      case ScanOutcome.unauthorized:
        icon = Icons.person_off_outlined;
        iconColor = const Color(0xFFD32F2F);
        title = 'No Inscrito';
        break;
      case ScanOutcome.permissionDenied:
        icon = Icons.location_disabled_outlined;
        iconColor = const Color(0xFFD32F2F);
        title = 'Permiso de GPS Denegado';
        break;
      case ScanOutcome.gpsDisabled:
        icon = Icons.gps_off_outlined;
        iconColor = const Color(0xFFF57C00);
        title = 'GPS Desactivado';
        break;
      case ScanOutcome.locationInaccurate:
        icon = Icons.gps_not_fixed_outlined;
        iconColor = const Color(0xFFF57C00);
        title = 'Precisión Insuficiente';
        break;
      case ScanOutcome.gpsTimeout:
        icon = Icons.timer_off_outlined;
        iconColor = const Color(0xFFF57C00);
        title = 'Tiempo Agotado en GPS';
        break;
      case ScanOutcome.networkError:
        icon = Icons.wifi_off;
        iconColor = const Color(0xFFF57C00);
        title = 'Fallo de Conexión';
        break;
      case ScanOutcome.invalid:
        icon = Icons.error_outline;
        iconColor = const Color(0xFFD32F2F);
        title = 'Código No Válido';
        break;
    }

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      contentPadding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 64, color: iconColor),
          const SizedBox(height: 16),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: iconColor,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            result.message,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: Colors.grey.shade800),
          ),
          if (result.record != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    result.record!.courseTitle,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    result.record!.sessionTitle,
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.access_time, size: 12, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(
                        _formatDateTime(result.record!.markedAt),
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
      actions: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: iconColor,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.of(context).pop();
              onDismiss?.call();
            },
            child: const Text('Entendido'),
          ),
        ),
      ],
    );
  }
}
