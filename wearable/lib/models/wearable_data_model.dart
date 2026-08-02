/// Modelo inmutable de datos del wearable. Idéntico a `movil/lib/models/`.
///
/// Vive solo en memoria (última muestra enviada por el periférico).
class WearableDataModel {
  final int frecuenciaCardiaca;
  final int pasos;
  final String estado;
  final DateTime timestamp;

  WearableDataModel({
    required this.frecuenciaCardiaca,
    required this.pasos,
    required this.estado,
    required this.timestamp,
  });
}