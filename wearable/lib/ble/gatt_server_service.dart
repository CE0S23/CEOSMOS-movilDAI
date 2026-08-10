import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:ble_peripheral/ble_peripheral.dart' as ble_peripheral;

import '../models/wearable_data_model.dart';
import '../services/tcp_server_service.dart';
import 'ble_constants.dart';

/// Servidor GATT (peripheral) basado en `ble_peripheral`.
///
/// NOTA SOBRE LA API REAL (ble_peripheral 2.4.0):
///  - La clase real es `BleCharacteristic` (no `BleCharacteristic` como modelo),
///    y las propiedades van como `List<int>` con `.index` del enum
///    `CharacteristicProperties` (NOTIFY = `CharacteristicProperties.notify.index`).
///  - No existe un método con nombre exacto "configurarServicioYCaracteristicas";
///    el servicio se define con el modelo `BleService` y se registra con
///    `BlePeripheral.addService(...)`.
///  - La notificación de valores se hace con `BlePeripheral.updateCharacteristic(...)`.
///  - Para "streamCentralConectado" el paquete ofrece dos callbacks distintos por
///    plataforma: `setConnectionStateChangeCallback` (SÓLO Android) y
///    `setCharacteristicSubscriptionChangeCallback` (SÓLO iOS/Mac/Windows). Como
///    nuestro objetivo es Android, usamos el de conexión; la suscripción queda
///    documentada como alternativa iOS.
class GattServerService {
  final StreamController<bool> _conectadoController =
      StreamController<bool>.broadcast();
  final Map<String, bool> _deviceConectados = {};

  final TcpServerService tcpServerService = TcpServerService();

  /// broadcast: true si hay al menos un dispositivo central (móvil) conectado.
  Stream<bool> get streamCentralConectado => _conectadoController.stream;
  bool get _hayConectado => _deviceConectados.values.contains(true);

  /// Inicializa el plugin (debe llamarse antes que cualquier otro método).
  Future<void> inicializar() async {
    await ble_peripheral.BlePeripheral.initialize();
    await tcpServerService.iniciar();
  }

  /// Define el servicio CEOSMOS con sus 3 características (propiedad NOTIFY)
  /// y lo registra en el peripheral.
  Future<void> configurarServicioYCaracteristicas() async {
    await registrarCallbacks();

    final service = ble_peripheral.BleService(
      uuid: BleConstants.serviceUuid,
      primary: true,
      characteristics: [
        ble_peripheral.BleCharacteristic(
          uuid: BleConstants.frecuenciaCardiacaCharUuid,
          properties: [ble_peripheral.CharacteristicProperties.notify.index],
          permissions: [
            ble_peripheral.AttributePermissions.readable.index,
          ],
        ),
        ble_peripheral.BleCharacteristic(
          uuid: BleConstants.pasosCharUuid,
          properties: [ble_peripheral.CharacteristicProperties.notify.index],
          permissions: [
            ble_peripheral.AttributePermissions.readable.index,
          ],
        ),
        ble_peripheral.BleCharacteristic(
          uuid: BleConstants.estadoCharUuid,
          properties: [ble_peripheral.CharacteristicProperties.notify.index],
          permissions: [
            ble_peripheral.AttributePermissions.readable.index,
          ],
        ),
      ],
    );

    await ble_peripheral.BlePeripheral.addService(service);
  }

  Future<void> registrarCallbacks() async {
    // Sólo Android: notifica cambios de conexión del dispositivo central.
    ble_peripheral.BlePeripheral.setConnectionStateChangeCallback(
      (String deviceId, bool connected) {
        _deviceConectados[deviceId] = connected;
        _conectadoController.add(_hayConectado);
      },
    );

    // iOS/Mac/Windows: suscripción a NOTIFY del central.
    // Nota: no usamos este callback porque el objetivo es Android; queda
    // documentado como la alternativa para esas plataformas.
    ble_peripheral.BlePeripheral.setCharacteristicSubscriptionChangeCallback(
      (String deviceId, String characteristicId, bool isSubscribed,
          String? name) {
        // Activamente no usado en Android.
      },
    );
  }

  /// Comienza a anunciar el servicio con nombre "CEOSMOS-Wearable".
  Future<void> iniciarAdvertising() async {
    await ble_peripheral.BlePeripheral.startAdvertising(
      services: [BleConstants.serviceUuid],
      localName: 'CEOSMOS-Wearable',
    );
  }

  /// Detiene la publicidad (advertising) del peripheral.
  Future<void> detenerAdvertising() async {
    await ble_peripheral.BlePeripheral.stopAdvertising();
  }

  /// Notifica una muestra a los devices suscritos, codificando cada
  /// característica según el formato esperado por el móvil:
  ///  - frecuenciaCardiaca: 1 byte (value[0]).
  ///  - pasos: 4 bytes little-endian.
  ///  - estado: UTF-8.
  void notificarDato(WearableDataModel dato) {
    final frecuenciaBytes = Uint8List.fromList([dato.frecuenciaCardiaca]);
    final pasosBytes = ByteData(4)..setUint32(0, dato.pasos, Endian.little);
    final estadoBytes = Uint8List.fromList(utf8.encode(dato.estado));

    // Actualizar característica 1: frecuencia cardíaca
    ble_peripheral.BlePeripheral.updateCharacteristic(
      characteristicId: BleConstants.frecuenciaCardiacaCharUuid,
      value: frecuenciaBytes,
    );
    // Característica 2: pasos
    ble_peripheral.BlePeripheral.updateCharacteristic(
      characteristicId: BleConstants.pasosCharUuid,
      value: pasosBytes.buffer.asUint8List(),
    );
    // Característica 3: estado
    ble_peripheral.BlePeripheral.updateCharacteristic(
      characteristicId: BleConstants.estadoCharUuid,
      value: estadoBytes,
    );

    // Respaldo TCP loopback: se publica la misma muestra por el socket local.
    tcpServerService.enviarDato(dato);
  }

  void dispose() {
    tcpServerService.detener();
    _conectadoController.close();
  }
}