import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

import '../ble/ble_constants.dart';
import '../ble/ble_service.dart';
import '../models/wearable_data_model.dart';

class WearableProvider extends ChangeNotifier {
  final BleService _bleService = BleService();

  BluetoothDevice? _dispositivo;
  WearableDataModel? _ultimoDato;
  String _estadoConexion = 'inactivo';

  StreamSubscription<BluetoothDevice?>? _scanSub;
  StreamSubscription<WearableDataModel>? _dataSub;
  StreamSubscription<BluetoothConnectionState>? _connectionSub;

  BluetoothDevice? get dispositivo => _dispositivo;
  WearableDataModel? get ultimoDato => _ultimoDato;
  String get estadoConexion => _estadoConexion;

  bool get alertaCritica =>
      _ultimoDato != null &&
      _ultimoDato!.frecuenciaCardiaca > BleConstants.umbralFrecuenciaCritica;

  Future<void> iniciarEscaneo() async {
    _estadoConexion = 'buscando';
    notifyListeners();

    try {
      _scanSub?.cancel();
      _scanSub = _bleService.escanearWearable().listen(
        (dispositivo) async {
          if (dispositivo != null) {
            _dispositivo = dispositivo;
            _estadoConexion = 'conectado';
            notifyListeners();
            await _conectarYEscuchar(dispositivo);
          } else {
            _estadoConexion = 'error';
            notifyListeners();
          }
        },
        onError: (Object e) {
          // ignore: avoid_print
          print('Error en escaneo: $e');
          _estadoConexion = 'error';
          notifyListeners();
        },
      );
    } catch (e) {
      // ignore: avoid_print
      print('Error al iniciar escaneo: $e');
      _estadoConexion = 'error';
      notifyListeners();
    }
  }

  Future<void> _conectarYEscuchar(BluetoothDevice device) async {
    await _bleService.conectar(device);

    _dataSub?.cancel();
    _dataSub = _bleService.streamDatosWearable(device).listen(
      (dato) {
        _ultimoDato = dato;
        notifyListeners();
      },
      onError: (Object e) {
        // ignore: avoid_print
        print('Error en datos del wearable: $e');
      },
    );

    _connectionSub?.cancel();
    _connectionSub =
        _bleService.streamEstadoConexion(device).listen((state) {
      switch (state) {
        case BluetoothConnectionState.connected:
          _estadoConexion = 'conectado';
          break;
        case BluetoothConnectionState.disconnected:
          _estadoConexion = 'desconectado';
          break;
      }
      notifyListeners();
    });
  }

  Future<void> desconectar() async {
    await _scanSub?.cancel();
    await _dataSub?.cancel();
    await _connectionSub?.cancel();

    final dispositivo = _dispositivo;
    if (dispositivo != null) {
      await _bleService.desconectar(dispositivo);
    }

    _dispositivo = null;
    _ultimoDato = null;
    _estadoConexion = 'inactivo';
    notifyListeners();
  }

  @override
  void dispose() {
    _scanSub?.cancel();
    _dataSub?.cancel();
    _connectionSub?.cancel();
    super.dispose();
  }
}