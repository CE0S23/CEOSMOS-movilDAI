/// Modelo inmutable de datos recibidos del wearable vía BLE.
///
/// Solo vive en memoria (última muestra recibida); no se persiste directo en
/// Firestore, de ahí que no tenga factory `fromFirestore`.
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