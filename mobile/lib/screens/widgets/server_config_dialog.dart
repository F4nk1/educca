import 'package:flutter/material.dart';
import '../../config/app_config.dart';
import 'demo_tour_sheet.dart';

/// Diálogo interactivo para configurar la URL base de conexión con el backend en caliente.
class ServerConfigDialog extends StatefulWidget {
  final AppConfig config;

  const ServerConfigDialog({super.key, required this.config});

  static Future<void> show(BuildContext context, AppConfig config) {
    return showDialog(
      context: context,
      builder: (ctx) => ServerConfigDialog(config: config),
    );
  }

  @override
  State<ServerConfigDialog> createState() => _ServerConfigDialogState();
}

class _ServerConfigDialogState extends State<ServerConfigDialog> {
  late final TextEditingController _controller;
  late bool _demoMode;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.config.baseUrl);
    _demoMode = widget.config.isDemoMode;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _save() {
    final text = _controller.text.trim();
    if (text.isNotEmpty) {
      widget.config.setBaseUrl(text);
    }
    widget.config.setDemoMode(_demoMode);
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_demoMode
            ? 'Modo Demostración activado (Datos simulados)'
            : 'URL del servidor actualizada: $text'),
        backgroundColor: _demoMode ? Colors.orange.shade800 : Colors.teal,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.settings_ethernet, color: Color(0xFF1565C0)),
          SizedBox(width: 8),
          Text('Ajustes de Conexión', style: TextStyle(fontSize: 18)),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Configura la dirección IP o URL base del servicio backend externo:',
              style: TextStyle(fontSize: 13, color: Colors.black87),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _controller,
              decoration: const InputDecoration(
                labelText: 'URL Base de la API',
                hintText: 'http://10.0.2.2:3000/api/v1',
                prefixIcon: Icon(Icons.link),
              ),
              keyboardType: TextInputType.url,
            ),
            const SizedBox(height: 16),
            Container(
              decoration: BoxDecoration(
                color: _demoMode ? Colors.orange.shade50 : Colors.grey.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: _demoMode ? Colors.orange.shade300 : Colors.grey.shade300,
                ),
              ),
              child: SwitchListTile(
                value: _demoMode,
                activeColor: Colors.orange.shade800,
                title: const Text(
                  'Modo Demostración (Simulado)',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                ),
                subtitle: const Text(
                  'Permite probar flujos completos de registro, login y escaneo sin necesidad del backend Go en ejecución.',
                  style: TextStyle(fontSize: 11),
                ),
                onChanged: (val) {
                  setState(() {
                    _demoMode = val;
                  });
                },
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Accesos rápidos para pruebas:',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                ActionChip(
                  label: const Text('Emulador (10.0.2.2)', style: TextStyle(fontSize: 11)),
                  onPressed: () {
                    _controller.text = 'http://10.0.2.2:3000/api/v1';
                  },
                ),
                ActionChip(
                  label: const Text('Localhost (5000)', style: TextStyle(fontSize: 11)),
                  onPressed: () {
                    _controller.text = 'http://10.0.2.2:5000/api/v1';
                  },
                ),
                ActionChip(
                  label: const Text('Restablecer', style: TextStyle(fontSize: 11)),
                  onPressed: () {
                    _controller.text = AppConfig.defaultBaseUrl;
                  },
                ),
                if (_demoMode)
                  ActionChip(
                    avatar: const Icon(Icons.slideshow, size: 14, color: Colors.deepOrange),
                    label: const Text('Recorrido Demo', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                    onPressed: () {
                      Navigator.of(context).pop();
                      DemoTourSheet.show(context);
                    },
                  ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: _save,
          child: const Text('Guardar'),
        ),
      ],
    );
  }
}
