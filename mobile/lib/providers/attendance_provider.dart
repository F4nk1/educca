import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import '../core/api_client.dart';
import '../models/attendance_models.dart';
import '../models/location_capture.dart';
import '../repositories/api_educca_repository.dart';
import '../repositories/educca_repository.dart';

/// Proveedor de estado para el escaneo de QR y captura puntual de geolocalización (HU-04 / RNF-01).
class AttendanceProvider extends ChangeNotifier {
  final ApiClient apiClient;
  EduccaRepository _repository;

  List<AttendanceRecord> _history = [];
  bool _isLoadingHistory = false;
  String? _historyError;
  bool _isSubmittingScan = false;

  AttendanceProvider({
    required this.apiClient,
    EduccaRepository? repository,
  }) : _repository = repository ?? ApiEduccaRepository(apiClient: apiClient);

  List<AttendanceRecord> get history => _history;
  bool get isLoadingHistory => _isLoadingHistory;
  String? get historyError => _historyError;
  bool get isSubmittingScan => _isSubmittingScan;
  EduccaRepository get repository => _repository;

  /// Permite alternar dinámicamente el repositorio (ej. MockEduccaRepository en debug).
  void setRepository(EduccaRepository newRepo) {
    _repository = newRepo;
    notifyListeners();
  }

  /// Adquiere la ubicación puntual y transmite el marcado de asistencia presencial.
  ///
  /// Restricciones del proyecto:
  /// - Timeout estricto de 10 segundos.
  /// - Filtro de precisión máxima de 50 metros.
  /// - Sin tracking continuo ni almacenamiento local de coordenadas (RNF-01).
  Future<AttendanceScanResult> registerAttendance(
    String qrToken, {
    LocationCapture? locationOverride,
  }) async {
    _isSubmittingScan = true;
    notifyListeners();

    try {
      LocationCapture location;

      if (locationOverride != null) {
        location = locationOverride;
      } else {
        // 1. Verificar si los servicios de ubicación están encendidos en el teléfono
        final serviceEnabled = await Geolocator.isLocationServiceEnabled();
        if (!serviceEnabled) {
          _isSubmittingScan = false;
          notifyListeners();
          return const AttendanceScanResult(
            outcome: ScanOutcome.gpsDisabled,
            message: 'El sensor de ubicación (GPS) está desactivado en tu dispositivo. Actívalo para continuar.',
          );
        }

        // 2. Verificar y solicitar permisos de ubicación en tiempo de ejecución
        LocationPermission permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.denied) {
          permission = await Geolocator.requestPermission();
          if (permission == LocationPermission.denied) {
            _isSubmittingScan = false;
            notifyListeners();
            return const AttendanceScanResult(
              outcome: ScanOutcome.permissionDenied,
              message: 'Se denegó el permiso de ubicación. Es indispensable para constatar tu presencia en la sede.',
            );
          }
        }

        if (permission == LocationPermission.deniedForever) {
          _isSubmittingScan = false;
          notifyListeners();
          return const AttendanceScanResult(
            outcome: ScanOutcome.permissionDenied,
            message: 'El permiso de ubicación fue denegado permanentemente. Habilítalo en los ajustes del teléfono.',
          );
        }

        // 3. Captura puntual (single-shot) con timeout de 10 s
        Position position;
        try {
          position = await Geolocator.getCurrentPosition(
            locationSettings: const LocationSettings(
              accuracy: LocationAccuracy.high,
              timeLimit: Duration(seconds: 10),
            ),
          );
        } on TimeoutException {
          _isSubmittingScan = false;
          notifyListeners();
          return const AttendanceScanResult(
            outcome: ScanOutcome.gpsTimeout,
            message: 'Tiempo de espera agotado (10 s) al fijar señal satelital GPS. Reintenta en un área más abierta.',
          );
        } catch (e) {
          _isSubmittingScan = false;
          notifyListeners();
          return AttendanceScanResult(
            outcome: ScanOutcome.networkError,
            message: 'No fue posible obtener coordenadas GPS: $e',
          );
        }

        // 4. Validar filtro de precisión acordado (<= 50 m)
        if (position.accuracy > 50.0) {
          _isSubmittingScan = false;
          notifyListeners();
          return AttendanceScanResult(
            outcome: ScanOutcome.locationInaccurate,
            message: 'La precisión GPS actual es de ${position.accuracy.toStringAsFixed(1)} m (tolerancia máxima: 50 m). Acércate a un espacio despejado.',
          );
        }

        location = LocationCapture(
          latitude: position.latitude,
          longitude: position.longitude,
          accuracyMeters: position.accuracy,
          capturedAt: position.timestamp,
        );
      }

      // 5. Enviar al repositorio activo (el backend valida la geocerca de 80 m)
      final scanResult = await _repository.scanAttendance(
        qrToken: qrToken,
        location: location,
      );

      if (scanResult.isSuccess && scanResult.record != null) {
        _history.insert(0, scanResult.record!);
      }

      _isSubmittingScan = false;
      notifyListeners();
      return scanResult;
    } catch (e) {
      _isSubmittingScan = false;
      notifyListeners();
      return AttendanceScanResult(
        outcome: ScanOutcome.networkError,
        message: 'Error inesperado durante el marcado: $e',
      );
    }
  }

  /// Consulta el historial de asistencias confirmadas.
  Future<void> fetchHistory() async {
    _isLoadingHistory = true;
    _historyError = null;
    notifyListeners();

    final result = await _repository.getAttendanceHistory();

    result.when(
      onSuccess: (data) {
        if (data is List) {
          _history = data
              .map((item) => AttendanceRecord.fromJson(item as Map<String, dynamic>))
              .toList();
        } else {
          _history = [];
        }
        _historyError = null;
        _isLoadingHistory = false;
        notifyListeners();
      },
      onFailure: (error, _) {
        _historyError = error;
        _isLoadingHistory = false;
        notifyListeners();
      },
    );
  }
}
