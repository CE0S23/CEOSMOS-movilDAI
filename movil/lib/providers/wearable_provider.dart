import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';

import '../ble/ble_constants.dart';
import '../ble/ble_service.dart';
import '../ble/tcp_fallback_client.dart';
import '../models/wearable_data_model.dart';

class WearableProvider extends ChangeNotifier {
  final BleService _bleService = BleService();
  final TcpFallbackClient _tcpFallbackClient = TcpFallbackClient();

  BluetoothDevice? _dispositivo;
  WearableDataModel? _ultimoDato;
  String _estadoConexion = 'inactivo';
  bool _reconectando = false;
  bool _cierreManual = false;

  StreamSubscription<BluetoothDevice?>? _scanSub;
  StreamSubscription<WearableDataModel>? _dataSub;
  StreamSubscription<BluetoothConnectionState>? _connectionSub;
  StreamSubscription<WearableDataModel>? _tcpDataSub;
  Socket? _tcpSocket;

  BluetoothDevice? get dispositivo => _dispositivo;
  WearableDataModel? get ultimoDato => _ultimoDato;
  String get estadoConexion => _estadoConexion;
  bool get reconectando => _reconectando;
  bool get conectado =>
      _estadoConexion == 'conectado' ||
      _estadoConexion == 'conectado_respaldo';

  bool get alertaCritica =>
      _ultimoDato != null &&
      _ultimoDato!.frecuenciaCardiaca > BleConstants.umbralFrecuenciaCritica;

  Future<bool> _solicitarPermisosBle() async {
    final statuses = await [
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
    ].request();
    return statuses.values.every((status) => status.isGranted);
  }

  Future<void> iniciarEscaneo() async {
    final permisosOk = await _solicitarPermisosBle();
    if (!permisosOk) {
      _cambiarEstado('error');
      return;
    }

    _reconectando = false;
    _reintentarEscaneo();
  }

  Future<void> _reintentarEscaneo() async {
    _cambiarEstado('buscando');

    try {
      _scanSub?.cancel();
      _scanSub = _bleService.escanearWearable().listen(
        (dispositivo) async {
          if (dispositivo != null) {
            _dispositivo = dispositivo;
            await _conectarYEscuchar(dispositivo);
          } else {
            await _manejarFalloEscaneo();
          }
        },
        onError: (Object e) {
          // ignore: avoid_print
          print('Error en escaneo: $e');
          _manejarFalloEscaneo();
        },
      );
    } catch (e) {
      // ignore: avoid_print
      print('Error al iniciar escaneo: $e');
      _manejarFalloEscaneo();
    }
  }

/// Intento de respaldo vía TCP loopback cuando el escaneo BLE no encuentra
  /// el wearable. Si el fallback también falla, ahí sí se marca 'error'.
  Future<void> _manejarFalloEscaneo() async {
    try {
      final socket = await _tcpFallbackClient.conectar();
      if (socket == null) {
        _cambiarEstado('error');
        return;
      }

      _tcpSocket = socket;
      await _tcpDataSub?.cancel();
      _tcpDataSub = _tcpFallbackClient.escucharDatos(socket).listen(
        (dato) {
          _ultimoDato = dato;
          notifyListeners();
        },
        onError: (Object e) {
          // ignore: avoid_print
          print('Error en datos del respaldo TCP: $e');
          _cambiarEstado('error');
        },
        onDone: () {
          if (_estadoConexion == 'conectado_respaldo') {
            _ultimoDato = null;
            _cambiarEstado('desconectado');
          }
        },
      );

      _cambiarEstado('conectado_respaldo');
    } catch (e) {
      // ignore: avoid_print
      print('Error en el respaldo TCP: $e');
      _cambiarEstado('error');
    }
  }

  Future<void> _conectarYEscuchar(BluetoothDevice device) async {
    try {
      await _bleService.conectar(device);
    } catch (e) {
      // ignore: avoid_print
      print('Error al conectar: $e');
      _cambiarEstado('error');
      return;
    }

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
        _bleService.streamEstadoConexion(device).listen(
      (state) {
        if (state == BluetoothConnectionState.connected) {
          _cambiarEstado('conectado');
          _reconectando = false;
        } else if (state == BluetoothConnectionState.disconnected) {
          if (_cierreManual) {
            _reiniciar();
          } else {
            _manejarDesconexion();
          }
        }
      },
      onError: (Object e) {
        // ignore: avoid_print
        print('Error en estado de conexión: $e');
        _manejarDesconexion();
      },
    );
  }

  /// Desconexión no deseada: limpia datos, marca estado y reintenta una vez
  /// con espera para no crashear la UI.
  Future<void> _manejarDesconexion() async {
    _ultimoDato = null;
    _cambiarEstado('desconectado');

    if (_reconectando || _dispositivo == null) {
      return;
    }

    _reconectando = true;
    notifyListeners();

    await Future.delayed(const Duration(seconds: 3));
    _reconectando = false;

    final device = _dispositivo;
    if (device == null || _cierreManual) {
      return;
    }

    _cambiarEstado('buscando');
    await _conectarYEscuchar(device);
  }

  Future<void> desconectar() async {
    _cierreManual = true;
    await _scanSub?.cancel();
    await _dataSub?.cancel();
    await _connectionSub?.cancel();
    await _tcpDataSub?.cancel();

    final tcpSocket = _tcpSocket;
    if (tcpSocket != null) {
      await _tcpFallbackClient.cerrar(tcpSocket);
      _tcpSocket = null;
    }

    final dispositivo = _dispositivo;
    if (dispositivo != null) {
      try {
        await _bleService.desconectar(dispositivo);
      } catch (e) {
        // ignore: avoid_print
        print('Error al desconectar: $e');
      }
    }
    _reiniciar();
    _cierreManual = false;
  }

  void _cambiarEstado(String nuevo) {
    _estadoConexion = nuevo;
    notifyListeners();
  }

  void _reiniciar() {
    _dispositivo = null;
    _ultimoDato = null;
    _reconectando = false;
    _cambiarEstado('inactivo');
  }

  @override
  void dispose() {
    _scanSub?.cancel();
    _dataSub?.cancel();
    _connectionSub?.cancel();
    _tcpDataSub?.cancel();
    final tcpSocket = _tcpSocket;
    if (tcpSocket != null) {
      tcpSocket.close();
      _tcpSocket = null;
    }
    super.dispose();
  }
}
