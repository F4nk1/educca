import 'package:flutter/material.dart';

/// Diálogo modal con el texto oficial del aviso de privacidad y consentimiento informado (RNF-01 / LPDP N.° 29733).
class PrivacyConsentDialog extends StatelessWidget {
  const PrivacyConsentDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      builder: (ctx) => const PrivacyConsentDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.privacy_tip_outlined, color: Color(0xFF00897B)),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'Aviso de Privacidad y Consentimiento',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Programa Municipal EDUCCA — Cusco',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
            const SizedBox(height: 8),
            Text(
              'En cumplimiento de la Ley de Protección de Datos Personales N.° 29733 y su reglamento (D.S. N.° 016-2024-JUS), la Gerencia de Medio Ambiente y Servicios Públicos de la Municipalidad Provincial del Cusco le informa:\n\n'
              '1. Finalidad: Sus datos personales (nombre, correo y categoría) se utilizarán exclusivamente para gestionar su participación, constatar asistencias y emitir reconocimientos en las actividades de educación ambiental.\n\n'
              '2. Geolocalización puntual: Para registrar su presencia en talleres y sedes, la aplicación capturará su ubicación GPS ÚNICAMENTE en el instante exacto en que confirme el escaneo del código QR. La aplicación NO realiza seguimiento continuo ni rastreo en segundo plano, ni almacena su historial de coordenadas en el teléfono.\n\n'
              '3. Confidencialidad y derechos ARCO: Sus datos no serán transferidos a terceros con fines comerciales. Puede ejercer sus derechos de acceso, rectificación, cancelación y oposición ante la gerencia municipal correspondiente.',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade800, height: 1.4),
            ),
          ],
        ),
      ),
      actions: [
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF00897B),
            foregroundColor: Colors.white,
          ),
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Entendido'),
        ),
      ],
    );
  }
}
