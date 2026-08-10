import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../models/wearable_data_model.dart';

/// Servidor TCP de respaldo (loopback 127.0.0.1:8765).
///
/// Se usa SOLO como mecanismo de backup cuando la conexión BLE falla.
/// No reemplaza al GATT server (BLE sigue siendo el canal primario evaluado);
/// convive con [GattServerService] y publica las mismas muestras por un socket
/// local adicional.
class TcpServerService {
  static const String _host = '127.0.0.1';
  static const int _puerto = 8765;

  ServerSocket? _servidor;
  final List<Socket> _clientes = [];
  bool _escuchando = false;
  final StreamController<int> _clientesController =
      StreamController<int>.broadcast();

  bool get escuchando => _escuchando;

  /// Número actual de clientes TCP conectados.
  int get totalClientes => _clientes.length;

  /// Emite el número de clientes conectados cada vez que cambia.
  Stream<int> get streamTotalClientes => _clientesController.stream;

  /// Abre el socket en 127.0.0.1:8765 y acepta conexiones entrantes,
  /// guardando los sockets de los clientes conectados en [_clientes].
  Future<void> iniciar() async {
    if (_escuchando) {
      return;
    }

    _servidor = await ServerSocket.bind(_host, _puerto);
    _escuchando = true;

    _clientesController.add(0);
    _servidor!.listen(
      (Socket cliente) {
        _clientes.add(cliente);
        _clientesController.add(_clientes.length);
        cliente.done.whenComplete(() {
          _clientes.remove(cliente);
          _clientesController.add(_clientes.length);
        });
      },
      onError: (Object e) {
        // ignore: avoid_print
        print('Error en servidor TCP: $e');
      },
    );
  }

  /// Serializa [dato] a JSON con el formato esperado por el móvil y lo envía
  /// a todos los clientes conectados, terminando cada mensaje con '\n' como
  /// delimitador.
  void enviarDato(WearableDataModel dato) {
    if (_clientes.isEmpty) {
      return;
    }

    final payload = jsonEncode({
      'frecuenciaCardiaca': dato.frecuenciaCardiaca,
      'pasos': dato.pasos,
      'estado': dato.estado,
      'timestamp': dato.timestamp.toIso8601String(),
    });

    final mensaje = '$payload\n';
    for (final cliente in List<Socket>.from(_clientes)) {
      try {
        cliente.write(mensaje);
        cliente.flush();
      } catch (e) {
        // ignore: avoid_print
        print('Error enviando dato TCP: $e');
      }
    }
  }

  /// Cierra todos los sockets de clientes y el servidor.
  Future<void> detener() async {
    for (final cliente in List<Socket>.from(_clientes)) {
      try {
        await cliente.close();
      } catch (_) {}
    }
    _clientes.clear();

    final servidor = _servidor;
    _servidor = null;
    _escuchando = false;
    if (servidor != null) {
      try {
        await servidor.close();
      } catch (_) {}
    }
  }
}