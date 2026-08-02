/// Constantes compartidas del protocolo BLE entre el móvil (central) y el
/// wearable (periférico).
///
/// NOTA: Estas constantes se reutilizan tal cual en el proyecto `wearable/`
/// que se implementará después. NO deben cambiarse, ya que el periférico y el
/// central deben usar exactamente los mismos UUIDs para comunicarse.
///
/// UUIDs base usados: Nordic UART Service (NUS). Válidos como placeholders de
/// desarrollo.
class BleConstants {
  /// UUID del servicio principal que expone el wearable.
  static const String serviceUuid = "6e400001-b5a3-f393-e0a9-e50e24dcca9e";

  /// Característica de frecuencia cardíaca (por minuto).
  static const String frecuenciaCardiacaCharUuid =
      "6e400002-b5a3-f393-e0a9-e50e24dcca9e";

  /// Característica de contador de pasos.
  static const String pasosCharUuid = "6e400003-b5a3-f393-e0a9-e50e24dcca9e";

  /// Característica de estado del usuario ("flow"/"estres"/"pausa"/"normal").
  static const String estadoCharUuid = "6e400004-b5a3-f393-e0a9-e50e24dcca9e";

  /// Umbral a partir del cual se considera la frecuencia crítica.
  static const int umbralFrecuenciaCritica = 120;
}