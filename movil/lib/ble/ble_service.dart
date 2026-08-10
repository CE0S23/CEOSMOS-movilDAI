import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_blue_plus/flutter_blue_plus.dart';

import '../models/wearable_data_model.dart';
import 'ble_constants.dart';

/// Cliente BLE central: escanea, conecta y consume notificaciones del wearable.
///
/// Formato asumido de los bytes en cada NOTIFY:
///  - frecuenciaCardiaca: 1 byte unsigned (valor = value[0]).
///  - pasos: 4 bytes little-endian (valor = value[0..3] como int32 unsigned).
///  - estado: texto UTF-8.
class BleService {
  /// Escanea durante 10s buscando el servicio BLE del wearable y emite el
  /// primer dispositivo que lo anuncie (o `null` si no encuentra nada).
  Stream<BluetoothDevice?> escanearWearable() async* {
    try {
      await FlutterBluePlus.startScan(
        withServices: [Guid(BleConstants.serviceUuid)],
        timeout: const Duration(seconds: 5),
      );

      await for (final results in FlutterBluePlus.scanResults) {
        if (results.isNotEmpty) {
          final dispositivo = results.first.device;
          yield dispositivo;
          await FlutterBluePlus.stopScan();
          return;
        }
      }

      await FlutterBluePlus.stopScan();
      yield null;
    } catch (e) {
      // ignore: avoid_print
      print('Error escaneando wearable: $e');
      yield null;
    }
  }

  /// Conecta al dispositivo y descubre sus servicios.
  Future<void> conectar(BluetoothDevice device) async {
    try {
      await device.connect(license: License.nonprofit);
      await device.discoverServices();
    } catch (e) {
      // ignore: avoid_print
      print('Error al conectar: $e');
    }
  }

  /// Stream continuo de [WearableDataModel] combinando las 3 características.
  ///
  /// Se suscribe a NOTIFY de frecuenciaCardiaca, pasos y estado. Cada vez que
  /// llega un NOTIFY y ya se tiene la primera muestra de las 3, combina los
  /// valores en un nuevo [WearableDataModel]. Si el dispositivo se desconecta,
  /// los errores solo se loguean y el stream no se cierra de forma brusca.
  Stream<WearableDataModel> streamDatosWearable(BluetoothDevice device) {
    late final StreamController<WearableDataModel> controller;
    final Map<String, List<int>> ultimosValores = {};
    final List<StreamSubscription<List<int>>> subs = [];

    controller = StreamController<WearableDataModel>(
      onListen: () async {
        try {
          final services = await device.discoverServices();
          final service = _findService(services);
          if (service == null) {
            // ignore: avoid_print
            print('No se encontró el servicio BLE del wearable');
            return;
          }

          for (final uuid in [
            BleConstants.frecuenciaCardiacaCharUuid,
            BleConstants.pasosCharUuid,
            BleConstants.estadoCharUuid,
          ]) {
            final characteristic = _findCharacteristic(service, uuid);
            if (characteristic == null) {
              // ignore: avoid_print
              print('No se encontró la característica $uuid');
              continue;
            }

            await characteristic.setNotifyValue(true);
            final sub = characteristic.onValueReceived.listen(
              (value) {
                ultimosValores[uuid] = value;
                if (ultimosValores.length == 3) {
                  if (!controller.isClosed) {
                    controller.add(_parsearDatos(ultimosValores));
                  }
                }
              },
              onError: (Object e) {
                // ignore: avoid_print
                print('Error en notificación $uuid: $e');
              },
            );
            subs.add(sub);
          }
        } catch (e) {
          // ignore: avoid_print
          print('Error suscribiéndose a datos del wearable: $e');
        }
      },
      onCancel: () async {
        for (final sub in subs) {
          await sub.cancel();
        }
        await controller.close();
      },
    );

    return controller.stream;
  }

  Stream<BluetoothConnectionState> streamEstadoConexion(
    BluetoothDevice device,
  ) {
    return device.connectionState;
  }

  Future<void> desconectar(BluetoothDevice device) async {
    try {
      await device.disconnect();
    } catch (e) {
      // ignore: avoid_print
      print('Error al desconectar: $e');
    }
  }

  BluetoothService? _findService(List<BluetoothService> services) {
    for (final service in services) {
      if (service.uuid.str.toLowerCase() == BleConstants.serviceUuid) {
        return service;
      }
    }
    return null;
  }

  BluetoothCharacteristic? _findCharacteristic(
    BluetoothService service,
    String uuid,
  ) {
    for (final characteristic in service.characteristics) {
      if (characteristic.uuid.str.toLowerCase() == uuid) {
        return characteristic;
      }
    }
    return null;
  }

  WearableDataModel _parsearDatos(Map<String, List<int>> valores) {
    final fcBytes = valores[BleConstants.frecuenciaCardiacaCharUuid] ?? const [];
    final pasosBytes = valores[BleConstants.pasosCharUuid] ?? const [];
    final estadoBytes = valores[BleConstants.estadoCharUuid] ?? const [];

    int frecuenciaCardiaca = 0;
    if (fcBytes.isNotEmpty) {
      frecuenciaCardiaca = fcBytes[0];
    }

    int pasos = 0;
    if (pasosBytes.isNotEmpty) {
      if (pasosBytes.length >= 4) {
        pasos = ByteData.sublistView(Uint8List.fromList(pasosBytes))
            .getUint32(0, Endian.little);
      } else {
        pasos = pasosBytes[0];
      }
    }

    final estado = utf8.decode(estadoBytes, allowMalformed: true);

    return WearableDataModel(
      frecuenciaCardiaca: frecuenciaCardiaca,
      pasos: pasos,
      estado: estado,
      timestamp: DateTime.now(),
    );
  }
}