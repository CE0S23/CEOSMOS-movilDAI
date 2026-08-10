import 'dart:async';

import 'package:flutter/foundation.dart';

import '../ble/gatt_server_service.dart';
import '../models/wearable_data_model.dart';
import '../services/simulador_datos_service.dart';

class WearableGattProvider extends ChangeNotifier {
  final GattServerService _gattServerService = GattServerService();
  final SimuladorDatosService _simuladorDatosService = SimuladorDatosService();

  WearableDataModel? _ultimoDato;
  bool _advertisingActivo = false;
  bool _centralConectado = false;
  int _tcpClientes = 0;

  StreamSubscription<bool>? _conexionSub;
  StreamSubscription<WearableDataModel>? _datosSub;
  StreamSubscription<int>? _tcpClientesSub;

  WearableDataModel? get ultimoDato => _ultimoDato;
  bool get advertisingActivo => _advertisingActivo;
  bool get centralConectado => _centralConectado;

  /// Canal activo por el que el central (móvil) recibe datos:
  /// 'ble' (GATT), 'tcp' (respaldo loopback) o 'ninguno'.
  String get canalActivo {
    if (_centralConectado) {
      return 'ble';
    }
    if (_tcpClientes > 0) {
      return 'tcp';
    }
    return 'ninguno';
  }

  Future<void> iniciar() async {
    await _gattServerService.inicializar();
    await _gattServerService.configurarServicioYCaracteristicas();
    await _gattServerService.iniciarAdvertising();
    _advertisingActivo = true;

    _conexionSub?.cancel();
    _conexionSub =
        _gattServerService.streamCentralConectado.listen((conectado) {
      _centralConectado = conectado;
      notifyListeners();
    });

    _tcpClientesSub?.cancel();
    _tcpClientesSub = _gattServerService.tcpServerService.streamTotalClientes
        .listen((clientes) {
      _tcpClientes = clientes;
      notifyListeners();
    });

    _simuladorDatosService.iniciar();

    _datosSub?.cancel();
    _datosSub = _simuladorDatosService.streamDatos.listen((dato) {
      _ultimoDato = dato;
      _gattServerService.notificarDato(dato);
      notifyListeners();
    });

    notifyListeners();
  }

  void pausarSesion() {
    _simuladorDatosService.pausar();
  }

  void reanudarSesion() {
    _simuladorDatosService.reanudar();
  }

  Future<void> detener() async {
    await _conexionSub?.cancel();
    await _datosSub?.cancel();
    await _tcpClientesSub?.cancel();
    _simuladorDatosService.detener();
    await _gattServerService.detenerAdvertising();
    _advertisingActivo = false;
    _centralConectado = false;
    _tcpClientes = 0;
    notifyListeners();
  }

  @override
  void dispose() {
    _conexionSub?.cancel();
    _datosSub?.cancel();
    _tcpClientesSub?.cancel();
    _gattServerService.dispose();
    _simuladorDatosService.dispose();
    super.dispose();
  }
}