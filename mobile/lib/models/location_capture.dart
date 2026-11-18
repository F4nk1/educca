/// Captura efímera de coordenadas para el marcado puntual de asistencia (HU-04 / RNF-01).
///
/// Principio RNF-01: No cuenta con serialización a almacenamiento persistente local
/// (SharedPreferences, SQLite). Los valores son volátiles en memoria y se descartan
/// tras la transmisión al backend en Go.
class LocationCapture {
  final double latitude;
  final double longitude;
  final double accuracyMeters;
  final DateTime capturedAt;

  const LocationCapture({
    required this.latitude,
    required this.longitude,
    required this.accuracyMeters,
    required this.capturedAt,
  });

  Map<String, dynamic> toJson() => {
    'latitude': latitude,
    'longitude': longitude,
    'accuracyMeters': accuracyMeters,
    'capturedAt': capturedAt.toIso8601String(),
  };
}
