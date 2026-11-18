import 'package:flutter_test/flutter_test.dart';
import 'package:sistema_capacitaciones/models/attendance_models.dart';

void main() {
  group('AttendanceModels Unit Tests (HU-04 / RNF-01)', () {
    test('AttendanceRecord parses nested session JSON from backend Go', () {
      final json = {
        'status': 'RECORDED',
        'attendanceId': 'att-go-901',
        'session': {
          'id': 'ses-go-101',
          'title': 'Taller de Prevención de Incendios Forestales',
          'venueName': 'Comunidad Campesina de Huilloc',
        },
        'recordedAt': '2026-11-17T14:30:00.000Z',
      };

      final record = AttendanceRecord.fromJson(json);
      expect(record.id, 'att-go-901');
      expect(record.sessionId, 'ses-go-101');
      expect(record.sessionTitle, 'Taller de Prevención de Incendios Forestales');
      expect(record.venueName, 'Comunidad Campesina de Huilloc');
      expect(record.status, 'RECORDED');
    });

    test('AttendanceScanResult getters evaluate correctly', () {
      const successResult = AttendanceScanResult(
        outcome: ScanOutcome.success,
        message: 'Asistencia registrada',
      );
      expect(successResult.isSuccess, isTrue);
      expect(successResult.isDuplicate, isFalse);
      expect(successResult.isOutOfRange, isFalse);

      const outOfRangeResult = AttendanceScanResult(
        outcome: ScanOutcome.outOfRange,
        message: 'Fuera de radio de 80 m',
      );
      expect(outOfRangeResult.isSuccess, isFalse);
      expect(outOfRangeResult.isOutOfRange, isTrue);

      const duplicateResult = AttendanceScanResult(
        outcome: ScanOutcome.duplicate,
        message: 'Asistencia duplicada',
      );
      expect(duplicateResult.isDuplicate, isTrue);

      const expiredResult = AttendanceScanResult(
        outcome: ScanOutcome.expired,
        message: 'QR caducado',
      );
      expect(expiredResult.isExpired, isTrue);
    });
  });
}
