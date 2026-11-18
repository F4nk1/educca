import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sistema_capacitaciones/models/attendance_models.dart';
import 'package:sistema_capacitaciones/screens/widgets/scan_result_dialog.dart';

void main() {
  testWidgets('ScanResultDialog renders outOfRange state with alert title and color', (tester) async {
    const result = AttendanceScanResult(
      outcome: ScanOutcome.outOfRange,
      message: 'Te encuentras a 125 metros de la sede. El radio máximo permitido es de 80 m.',
    );

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: ScanResultDialog(result: result),
        ),
      ),
    );

    expect(find.text('Fuera del Área de Sede'), findsOneWidget);
    expect(find.textContaining('radio máximo permitido es de 80 m'), findsOneWidget);
    expect(find.byIcon(Icons.wrong_location_outlined), findsOneWidget);
    expect(find.text('Entendido'), findsOneWidget);
  });

  testWidgets('ScanResultDialog renders locationInaccurate state with warning message', (tester) async {
    const result = AttendanceScanResult(
      outcome: ScanOutcome.locationInaccurate,
      message: 'La precisión GPS actual es de 65 metros. Acércate a un área despejada y vuelve a intentar.',
    );

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: ScanResultDialog(result: result),
        ),
      ),
    );

    expect(find.text('Precisión Insuficiente'), findsOneWidget);
    expect(find.textContaining('La precisión GPS actual es de 65 metros'), findsOneWidget);
    expect(find.byIcon(Icons.gps_not_fixed_outlined), findsOneWidget);
  });

  testWidgets('ScanResultDialog renders permissionDenied state with guidance', (tester) async {
    const result = AttendanceScanResult(
      outcome: ScanOutcome.permissionDenied,
      message: 'Se requiere permiso de ubicación para comprobar que estás en la sede.',
    );

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: ScanResultDialog(result: result),
        ),
      ),
    );

    expect(find.text('Permiso de GPS Denegado'), findsOneWidget);
    expect(find.textContaining('Se requiere permiso de ubicación'), findsOneWidget);
    expect(find.byIcon(Icons.location_disabled_outlined), findsOneWidget);
  });
}
